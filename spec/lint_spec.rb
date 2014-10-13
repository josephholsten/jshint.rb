require 'spec_helper'

describe JSHint::Lint do

  JSHint::Lint.class_eval do
    attr_reader :config, :file_list
  end

  before :all do
    create_config 'color' => 'red', 'size' => 5, 'shape' => 'circle'
    create_file 'custom_config.yml', 'color' => 'blue', 'size' => 7, 'border' => 2
    create_file 'other_config.yml', 'color' => 'green', 'border' => 0, 'shape' => 'square'
    JSHint.config_path = "custom_config.yml"
  end

  it "should merge default config with custom config from JSHint.config_path" do
    lint = JSHint::Lint.new
    lint.config.should == { 'color' => 'blue', 'size' => 7, 'border' => 2, 'shape' => 'circle' }
  end

  it "should merge default config with custom config given in argument, if available" do
    lint = JSHint::Lint.new :config_path => 'other_config.yml'
    lint.config.should == { 'color' => 'green', 'border' => 0, 'shape' => 'square', 'size' => 5 }
  end

  it "should convert predef to string if it's an array" do
    create_file 'predef.yml', 'predef' => ['a', 'b', 'c']

    lint = JSHint::Lint.new :config_path => 'predef.yml'
    lint.config['predef'].should == ['a', 'b', 'c']
  end

  it "should accept predef as string" do
    create_file 'predef.yml', 'predef' => 'd,e,f'

    lint = JSHint::Lint.new :config_path => 'predef.yml'
    lint.config['predef'].should == ['d', 'e', 'f']
  end

  it "should not pass paths and exclude_paths options to real JSHint" do
    create_file 'test.yml', 'paths' => ['a', 'b'], 'exclude_paths' => ['c'], 'debug' => 'true'

    lint = JSHint::Lint.new :config_path => 'test.yml'
    lint.config['debug'].should == 'true'
    lint.config['paths'].should be_nil
    lint.config['exclude_paths'].should be_nil
  end

  it "should fail if JSHint check fails" do
    lint = JSHint::Lint.new
    lint.instance_variable_set("@file_list", ['app.js'])
    lint.should_receive(:process_file).and_return([{'line'=>0,'character'=>0,'reason'=>'failure'}])
    lambda { lint.run }.should raise_error(JSHint::LintCheckFailure)
  end

  it "should not fail if JSHint check passes" do
    lint = JSHint::Lint.new
    lint.instance_variable_set("@file_list", ['app.js'])
    lint.should_receive(:process_file).and_return([])
    lambda { lint.run }.should_not raise_error
  end

  it "should run JSHint once for each file" do
    lint = JSHint::Lint.new
    lint.instance_variable_set("@file_list", ['app.js', 'jquery.js'])
    lint.should_receive(:process_file).twice.and_return([])
    lint.run
  end

  describe "file lists" do
    before :each do
      JSHint::Utils.stub!(:exclude_files).and_return { |inc, exc| inc - exc }
      JSHint::Utils.stub!(:unique_files).and_return { |files| files.uniq }
    end

    before :all do
      @files = ['test/app.js', 'test/lib.js', 'test/utils.js', 'test/vendor/jquery.js', 'test/vendor/proto.js']
      @files.each { |fn| create_file(fn, "alert()") }
      @files = @files.map { |fn| File.expand_path(fn) }
    end

    it "should calculate a list of files to test" do
      lint = JSHint::Lint.new :paths => ['test/**/*.js']
      lint.file_list.should == @files

      lint = JSHint::Lint.new :paths => ['test/a*.js', 'test/**/*r*.js']
      lint.file_list.should == [@files[0], @files[3], @files[4]]

      lint = JSHint::Lint.new :paths => ['test/a*.js', 'test/**/*r*.js'], :exclude_paths => ['**/*q*.js']
      lint.file_list.should == [@files[0], @files[4]]

      lint = JSHint::Lint.new :paths => ['test/**/*.js'], :exclude_paths => ['**/*.js']
      lint.file_list.should == []

      lint = JSHint::Lint.new :paths => ['test/**/*.js', 'test/**/a*.js', 'test/**/p*.js']
      lint.file_list.should == @files

      create_file 'new.yml', 'paths' => ['test/vendor/*.js']

      lint = JSHint::Lint.new :config_path => 'new.yml', :exclude_paths => ['**/proto.js']
      lint.file_list.should == [@files[3]]

      lint = JSHint::Lint.new :config_path => 'new.yml', :paths => ['test/l*.js']
      lint.file_list.should == [@files[1]]
    end

    it "should accept :paths and :exclude_paths as string instead of one-element array" do
      lambda do
        lint = JSHint::Lint.new :paths => 'test/*.js', :exclude_paths => 'test/lib.js'
        lint.file_list.should == [@files[0], @files[2]]
      end.should_not raise_error
    end

    it "should ignore empty files" do
      create_file 'test/empty.js', ''
      create_file 'test/full.js', 'qqq'

      lint = JSHint::Lint.new :paths => ['test/*.js']
      lint.file_list.should_not include(File.expand_path("test/empty.js"))
      lint.file_list.should include(File.expand_path("test/full.js"))
    end
  end

  describe '#run_lint' do
    context 'when the array returned by ExecJS contains a nil' do
      it 'returns array in same order, but without the nil' do
        err1 = double
        err2 = double
        execjs_context = double("ExecJS::ExternalRuntime::Context")
        expect(execjs_context).to \
          receive(:exec).and_return([err1, err2, nil])
        lint = described_class.new
        expect(lint).to receive(:context).and_return(execjs_context)
        result = lint.send(:run_lint, double("JS Source"))
        expect(result).to eq([err1, err2])
      end
    end
  end

end
