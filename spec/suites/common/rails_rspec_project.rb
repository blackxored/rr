module AdapterIntegrationTests
  class RailsRSpecProject < RailsProject
    def setup
      super
      within do
        run_command('rails generate rspec:install')
      end
    end

    def setup_test_runner(runner)
      super
      runner.directory = File.join(directory, 'spec')
    end

    def setup_test_file(file)
      super
      file.lines_to_require_helpers = [
        "require 'spec_helper'"
      ]
    end
  end
end
