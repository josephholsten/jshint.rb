require 'jshint/errors'
require 'jshint/utils'
require 'execjs'
require 'multi_json'

module JSHint

  PATH = File.dirname(__FILE__)

  JSLINT_FILE = File.expand_path("#{PATH}/vendor/jshint.js")

  class Lint

    # available options:
    # :paths => [list of paths...]
    # :exclude_paths => [list of exluded paths...]
    # :config_path => path to custom config file (can be set via JSHint.config_path too)
    def initialize(options = {})
      default_config = Utils.load_config_file(DEFAULT_CONFIG_FILE)
      custom_config = Utils.load_config_file(options[:config_path] || JSHint.config_path)
      @config = default_config.merge(custom_config)
      if @config['predef']
        @config['predef'] = @config['predef'].split(",") unless @config['predef'].is_a?(Array)
      end

      included_files = files_matching_paths(options, :paths)
      excluded_files = files_matching_paths(options, :exclude_paths)
      @file_list = Utils.exclude_files(included_files, excluded_files)
      @file_list.delete_if { |f| File.size(f) == 0 }

      ['paths', 'exclude_paths'].each { |field| @config.delete(field) }
    end

    def run
      raise NoEngineException, "No JS engine available" unless js_engine
      Utils.log "Running JSHint via #{js_engine.name}:\n\n"

      errors = @file_list.map { |file| process_file(file) }.flatten

      if errors.length == 0
        Utils.log "\nNo JS errors found."
      else
        Utils.log "\nFound #{Utils.pluralize(errors.length, 'error')}."
        raise LintCheckFailure, "JSHint test failed."
      end
    end


    private

    def js_engine
      ExecJS.runtime
    end

    def process_file(filename)
      Utils.display "checking #{filename}... "
      errors = []

      if File.exist?(filename)
        source = File.read(filename)
        errors = run_lint(source)

        if errors.length == 0
          Utils.log "OK"
        else
          Utils.log print(Utils.pluralize(errors.length, "error") + ":\n");

          errors.each do |error|
            Utils.log "Lint at line #{error['line']} character #{error['character']}: #{error['reason']}"

            if error['evidence']
              evidence = error['evidence'].gsub(/^\s*(\S*(\s+\S+)*)\s*$/) { $1 }
              Utils.log(evidence)
            end

            Utils.log ''
          end
        end
      else
        Utils.log "Error: couldn't open file."
      end

      errors
    end

    def run_lint(source)
      code = %(
        JSHINT(#{source.inspect}, #{MultiJson.dump(@config)});
        return JSHINT.errors;
      )

      context.exec(code)
    end

    def context
      @context ||= ExecJS.compile(File.read(JSLINT_FILE))
    end

    def files_matching_paths(options, field)
      path_list = options[field] || @config[field.to_s] || []
      path_list = [path_list] unless path_list.is_a?(Array)
      file_list = path_list.map { |p| Dir[p] }.flatten
      Utils.unique_files(file_list)
    end
  end
end
