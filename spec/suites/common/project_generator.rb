require File.expand_path('../generator', __FILE__)
require File.expand_path('../test_file_generator', __FILE__)
require File.expand_path('../test_helper_generator', __FILE__)

require 'session'

class ProjectGenerator
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

  class TestsRunner
    def self.call(project)
      runner = new(project)
      yield runner if block_given?
      runner.call
    end

    attr_reader :project
    attr_accessor :command

    def initialize(project)
      @project = project
      self.command = project.test_runner_command
    end

    def call
      match = command.match(/^((?:\w+=[^ ]+ )*)(.+)$/)
      project.run_command_within("bundle exec #{match[2]}", :env => match[1])
    end
  end

  include Generator

  attr_accessor \
    :autorequire_gems,
    :include_rr_before_test_framework

  attr_reader \
    :gem_dependencies,
    :test_requires,
    :prelude

  def setup
    super
    self.autorequire_gems = false
    self.include_rr_before_test_framework = false
    @gem_dependencies = []
    @test_requires = []
    @number_of_test_files = 0
    @prelude = ""
    @files_to_add = []
  end

  def root_dir
    File.expand_path('../../../..', __FILE__)
  end

  def lib_dir
    File.join(root_dir, 'lib')
  end

  def directory
    File.join(root_dir, 'tmp', 'rr-integration-tests', 'test_project')
  end

  def bundle_dir
    File.join(directory, '.bundle')
  end

  def test_filename
    raise NotImplementedError
  end

  def test_runner_command
    raise NotImplementedError
  end

  def call
    FileUtils.rm_rf directory
    FileUtils.mkdir_p File.dirname(directory)
    generate_skeleton
    test_helper_generator.call(self)
  end

  def add_to_prelude(string)
    test_helper_generator.configure do |file|
      file.add_to_prelude(string)
    end
  end

  def add_to_test_requires(path)
    test_helper_generator.configure do |file|
      file.add_to_requires(path)
    end
  end

  def add_test_file(&block)
    test_file_generator.call(self, @number_of_test_files, &block)
    @number_of_test_files += 1
  end

  def run_tests
    TestsRunner.call(self)
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
    #success = !!(exit_status == 0 || stdout =~ /Finished/)
    success = (exit_status == 0)
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
    if opts[:env]
      opts[:env].split(' ').each do |pair|
        contents << "export #{pair}\n"
      end
    end
    contents << "exec #{command}\n"
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
    @files_to_add << [file_name, content]
  end

  def build_partial_gemfile
    gem_dependencies_with_rr.
      map { |dep| gem_dependency_line(dep) }.
      join("\n")
  end

  def test_file_generator
    @test_file_generator ||= TestFileGenerator.factory
  end

  def requires_with_rr(requires)
    requires = requires.dup
    unless autorequire_gems
      if include_rr_before_test_framework
        requires.unshift 'rr'
      else
        requires.push 'rr'
      end
    end
    requires
  end

  def require_lines(requires)
    requires.map { |path| "require '#{path}'" }
  end

  def test_helper_generator
    @test_helper_generator ||= TestHelperGenerator.factory
  end

  private

  def generate_skeleton
  end

  def create_files
    @files_to_add.each do |file_name, content|
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
  end

  def create_link(filename, dest_filename = filename)
    FileUtils.ln_sf(File.join(root_dir, filename), File.join(directory, dest_filename))
  end

  def copy_file(filename, dest_filename = filename)
    FileUtils.cp(File.join(root_dir, filename), File.join(directory, dest_filename))
  end

  def ruby_18?
    RUBY_VERSION =~ /^1\.8/
  end

  def under_jruby?
    RUBY_PLATFORM =~ /java/
  end

  def gem_dependency(dep)
    dep
  end

  def gem_dependency_line(dep)
    dep = dep.dup
    name = dep.delete(:name)
    version = dep.delete(:version) || '>= 0'
    "gem #{name.to_s.inspect}, #{version.inspect}, #{dep.inspect}"
  end

  def gem_dependencies_with_rr
    if RR.debug?
      puts "Include RR before test framework? #{include_rr_before_test_framework.inspect}"
      puts "Autorequiring gems? #{autorequire_gems.inspect}"
    end

    dependencies = gem_dependencies.dup

    rr_dep = {:name => 'rr', :path => root_dir}
    rr_dep[:require] = false unless autorequire_gems
    rr_dep = gem_dependency(rr_dep)

    if include_rr_before_test_framework
      dependencies.unshift(rr_dep)
    else
      dependencies.push(rr_dep)
    end

    dependencies
  end
end
