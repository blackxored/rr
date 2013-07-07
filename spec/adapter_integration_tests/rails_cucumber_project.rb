require File.expand_path('../rails_project', __FILE__)

module AdapterIntegrationTests
  class RailsCucumberProject < RailsProject
    def test_runner_program
      "cucumber"
    end

    def setup
      super
      within do
        run_command('rails generate cucumber:install')
      end
    end

    def test_dir
      File.join(directory, 'features')
    end
  end
end
