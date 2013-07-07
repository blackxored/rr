require File.expand_path('../runner', __FILE__)
require File.expand_path('../test_file', __FILE__)

module AdapterIntegrationTests
  class GenericProject
    class CommandResult
      attr_reader :output

      def initialize(success, stdout)
        @success = success
        @output = output
      end

      def success?
        @success
      end
    end

    attr_accessor \
      :auto_require_test_framework,
      :adapter_name,
      :include_rr_before_test_framework,
      :test_file_contents

    attr_reader \
      :test_framework_paths,
      :test_framework_dependencies

    def initialize
      @test_framework_paths = []
      @test_framework_dependencies = []
      @auto_require_test_framework = true
    end

    def root_dir
      File.expand_path('../../..', __FILE__)
    end

    def lib_dir
      File.join(root_dir, 'lib')
    end

    def directory
      File.join(root_dir, 'tmp', 'rr-integration-tests')
    end

    def test_dir
      raise NotImplementedError
    end

    def test_runner_program
      raise NotImplementedError
    end

    def create
      FileUtils.rm_rf directory
      FileUtils.mkdir_p File.dirname(directory)
      setup
    end

    def run_test_file(file)
      build_runner.call(file.to_s)
    end

    def within(&block)
      ret = nil
      Dir.chdir(directory) { ret = block.call }
      ret
    end

    def run_command(command)
      # Bundler will set RUBYOPT to "-I <path to bundler> -r bundler/setup".
      # This is unfortunate as it causes Bundler to be loaded before we
      # load Bundler in RR::Test.setup_test_suite, thereby rendering our
      # second Bundler.setup a no-op.
      command = "env RUBYOPT='' #{command} 2>&1"
      bash = Session::Bash.new
      puts command if RR.debug?
      stdout, _ = bash.execute(command)
      exit_status = bash.exit_status
      success = !!(exit_status == 0 || stdout =~ /Finished/)
      if RR.debug?
        puts stdout
      end
      if not success
        msg = "Command failed!"
        msg << "\n#{stdout}" unless RR.debug?
        abort msg
      end
      CommandResult.new(success, stdout)
    end

    def run_command_within(command)
      within { run_command(command) }
    end

    private

    def setup
    end

    def create_link(filename, dest_filename = filename)
      FileUtils.ln_sf(File.join(root_dir, filename), File.join(directory, dest_filename))
    end

    def copy_file(filename, dest_filename = filename)
      FileUtils.cp(File.join(root_dir, filename), File.join(directory, dest_filename))
    end

    def build_runner
      Runner.new(self).tap do |runner|
        runner.directory = test_dir
      end
    end

    #def build_test_file(body)
    #  TestFile.new(body).tap do |file|
    #    file.test_framework_paths = test_framework_paths
    #    file.include_rr_before_test_framework = include_rr_before_test_framework
    #  end
    #end

    #def successfully_run_command(command)
    #  command = "#{command} 2>&1"
    #  command << " >/dev/null" unless RR.debug?
    #  system(command) or abort "Command failed"
    #end

    def ruby_18?
      RUBY_VERSION =~ /^1\.8/
    end

    def appraisal_name
      parts = []
      parts << (ruby_18? ? 'ruby_18' : 'ruby_19')
      parts << adapter_name
      parts.join('_')
    end

    def build_partial_gemfile
      partial_gemfile = test_framework_dependencies.map do |(name, version)|
        "gem '#{name}', '#{version}'"
      end.join("\n")
      if require_rr_before_test_framework
        partial_gemfile = "require 'rr', path: '#{root_dir}'"
    end
  end
end
