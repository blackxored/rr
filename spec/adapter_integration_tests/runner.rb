require 'session'

module AdapterIntegrationTests
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
      f = File.open(test_file_path, 'w') do |f|
        puts content if RR.debug?
        f.write(content)
      end
      command = "#{program} #{f.path}"
      project.run_within(command)
    ensure
      FileUtils.rm_f(test_file_path) if test_file_path
    end
  end
end
