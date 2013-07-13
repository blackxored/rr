require File.expand_path('../test_file', __FILE__)

require 'session'

class GenericProject
  class CommandResult
    attr_reader :output

    def initialize(success, output)
      @success = success
      @output = output
    end

    def success?
      @success
    end
  end

  class TestFileRunner
    def self.call(project)
      runner = new(project)
      yield runner
      runner.call
    end

    attr_reader :project
    attr_accessor :directory, :filename, :command

    def initialize(project)
      @project = project
      self.directory = project.test_dir
      self.filename = project.test_filename
      self.command = project.test_runner_command
    end

    def call(content)
      test_file_path = File.join(directory, filename)
      if RR.debug?
        puts "Test file path: #{test_file_path}"
      end
      File.open(test_file_path, 'w') do |f|
        if RR.debug?
          puts "~ Test file contents ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
          puts content
          puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        end
        f.write(content)
      end
      full_command = "bundle exec #{command}"
      project.run_command_within(full_command)
    end
  end

  def self.create(&block)
    new(&block).tap do |project|
      project.create
    end
  end

  attr_accessor \
    :autorequire_gems,
    :include_rr_before_test_framework,
    :test_file_prelude

  attr_reader \
    :test_framework_paths,
    :test_framework_dependencies

  def initialize
    @test_framework_paths = []
    @test_framework_dependencies = []
    @autorequire_gems = true
    yield self if block_given?
  end

  def root_dir
    File.expand_path('../../../..', __FILE__)
  end

  def lib_dir
    File.join(root_dir, 'lib')
  end

  def directory
    File.join(root_dir, 'tmp', 'rr-integration-tests')
  end

  def bundle_dir
    File.join(directory, '.bundle')
  end

  def test_dir
    raise NotImplementedError
  end

  def test_filename
    raise NotImplementedError
  end

  def test_runner_command
    raise NotImplementedError
  end

  def create
    FileUtils.rm_rf directory
    FileUtils.mkdir_p File.dirname(directory)
  end

  def build_test_file(body)
    TestFile.new(self, body)
  end

  def run_test_file(file)
    build_test_file_runner.call(file.to_s)
  end

  def within(&block)
    ret = nil
    Dir.chdir(directory) { ret = block.call }
    ret
  end

  def exec(command)
    command = command.dup
    command << ' 2>&1'
    bash = Session::Bash.new
    if RR.debug?
      puts "Running: #{command}"
    end
    stdout, _ = bash.execute(command)
    exit_status = bash.exit_status
    success = !!(exit_status == 0 || stdout =~ /Finished/)
    if RR.debug?
      puts "~ Output from `#{command}` ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
      puts stdout
      puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    end
    CommandResult.new(success, stdout)
  end

  def exec!(command)
    result = exec(command)
    if not result.success?
      raise "Command failed: #{command}"
    end
    result
  end

  def run_command(command, opts={})
    f = Tempfile.new('rr-integration-test-file')
    contents = ""
    unless opts[:without_bundler_sandbox]
      # Bundler will set RUBYOPT to "-I <path to bundler> -r bundler/setup".
      # This is unfortunate as it causes Bundler to be loaded before we
      # load Bundler in RR::Test.setup_test_suite, thereby rendering our
      # second Bundler.setup a no-op.
      contents << <<-EOT
        export BUNDLE_BIN_PATH=""
        export BUNDLE_GEMFILE=""
        export RUBYOPT=""
      EOT
    end
    contents << <<-EOT
      exec #{command}
    EOT
    if RR.debug?
      puts "~ File to run ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
      puts contents
      puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    end
    f.write(contents)
    f.close
    exec "bash #{f.path}"
  ensure
    f.unlink if f
  end

  def run_command_within(command, opts={})
    within { run_command(command, opts) }
  end

  def add_file(file_name, content)
    full_file_name = File.join(directory, file_name)
    FileUtils.mkdir_p File.dirname(full_file_name)
    File.open(full_file_name, 'w') do |f|
      if RR.debug?
        puts "~ Adding file #{full_file_name} ~~~~~~~~~~~~~~~~~~~~~~~~"
        puts content
        puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
      end
      f.write(content)
    end
  end

  def build_partial_gemfile
    gem_dependencies.
      map { |dependency| gem_dependency(*dependency) }.
      join("\n")
  end

  private

  def create_link(filename, dest_filename = filename)
    FileUtils.ln_sf(File.join(root_dir, filename), File.join(directory, dest_filename))
  end

  def copy_file(filename, dest_filename = filename)
    FileUtils.cp(File.join(root_dir, filename), File.join(directory, dest_filename))
  end

  def build_test_file_runner
    TestFileRunner.new(self).tap do |runner|
      runner.directory = test_dir
    end
  end

  def ruby_18?
    RUBY_VERSION =~ /^1\.8/
  end

  def under_jruby?
    RUBY_PLATFORM =~ /java/
  end

  def gem_dependency(name, *args)
    opts = args.last.is_a?(Hash) ? args.pop : {}
    version = args.first
    str = "gem '#{name}'"
    str << ", '#{version}'" if version
    str << ", #{opts.inspect}"
    str
  end

  def gem_dependencies
    if RR.debug?
      puts "Include RR before test framework? #{include_rr_before_test_framework.inspect}"
      puts "Autorequiring gems? #{autorequire_gems.inspect}"
    end

    deps = test_framework_dependencies.dup

    rr_dependency_options = {:path => root_dir}
    rr_dependency_options[:require] = false unless autorequire_gems
    rr_dependency = ['rr', rr_dependency_options]

    if include_rr_before_test_framework
      deps.unshift(rr_dependency)
    else
      deps.push(rr_dependency)
    end

    deps
  end
end
