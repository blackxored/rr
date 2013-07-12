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

  class Runner
    def self.call(project)
      runner = new(project)
      yield runner
      runner.call
    end

    attr_reader :project
    attr_accessor :directory, :program

    def initialize(project)
      @project = project
      self.directory = project.test_dir
      self.program = project.test_runner_program
    end

    def call(content)
      test_file_path = File.join(directory, 'the_test.rb')
      File.open(test_file_path, 'w') do |f|
        puts content if RR.debug?
        f.write(content)
      end
      command = "bundle exec #{program} #{test_file_path}"
      project.run_command_within(command)
    ensure
      FileUtils.rm_f(test_file_path) if test_file_path
    end
  end

  def self.create
    new.tap { |project| project.create }
  end

  attr_accessor \
    :autorequire_gems,
    :adapter_name,
    :include_rr_before_test_framework,
    :test_file_prelude

  attr_reader \
    :test_framework_paths,
    :test_framework_dependencies

  def initialize
    @test_framework_paths = []
    @test_framework_dependencies = []
    @autorequire_gems = true
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

  def test_runner_program
    raise NotImplementedError
  end

  def create
    FileUtils.rm_rf directory
    FileUtils.mkdir_p File.dirname(directory)
  end

  def build_test_file(body)
    TestFile.new(body).tap do |file|
      file.prelude = test_file_prelude
      file.test_framework_paths = test_framework_paths
      file.include_rr_before_test_framework = include_rr_before_test_framework
      file.autorequire_gems = autorequire_gems
    end
  end

  def run_test_file(file)
    build_runner.call(file.to_s)
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
    puts command if RR.debug?
    stdout, _ = bash.execute(command)
    exit_status = bash.exit_status
    success = !!(exit_status == 0 || stdout =~ /Finished/)
    if RR.debug?
      puts stdout
    end
    if not success
      msg = "Command failed: #{command}"
      msg << "\n#{stdout}" unless RR.debug?
      abort msg
    end
    CommandResult.new(success, stdout)
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
      #{command}
      exit $?
    EOT
    if RR.debug?
      puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
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
    File.open(File.join(directory, file_name), 'w') { |f| f.write(content) }
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

  def build_runner
    Runner.new(self).tap do |runner|
      runner.directory = test_dir
    end
  end

  def ruby_18?
    RUBY_VERSION =~ /^1\.8/
  end

  def under_jruby?
    RUBY_PLATFORM =~ /java/
  end

  def appraisal_name
    parts = []
    parts << (ruby_18? ? 'ruby_18' : 'ruby_19')
    parts << adapter_name
    parts.join('_')
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
