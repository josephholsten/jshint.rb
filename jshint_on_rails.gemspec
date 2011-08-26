lib_dir = File.expand_path(File.dirname(__FILE__) + '/lib')
$LOAD_PATH << lib_dir unless $LOAD_PATH.include?(lib_dir)

require 'jshint/utils'

Gem::Specification.new do |s|
  s.name = "jshint_on_rails"
  s.version = JSHint::VERSION
  s.description = "JSHint wrapped in a Ruby gem for easier use"
  s.summary = "JSHint is a little more flexible JavaScript checker, wrapped in a Ruby gem for easier use"
  s.homepage = "http://github.com/bgouveia/jshint_on_rails"

  s.author = "Bruno Gouveia"
  s.email = "brunogouveia@buzungo.com.br"

  s.requirements = ['JS engine compatible with execjs', 'JSON engine compatible with multi_json']

  s.add_dependency 'execjs', '>= 1.3.2'
  s.add_dependency 'multi_json', '>= 1.3.5'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'fakefs', '0.3.2'

  s.files = %w(MIT-LICENSE README.markdown Changelog.markdown Gemfile Gemfile.lock Rakefile)
  s.files += Dir['lib/**/*'] + Dir['spec/**/*']
end
