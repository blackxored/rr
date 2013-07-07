require File.expand_path('../rails_project', __FILE__)

module AdapterIntegrationTests
  class RailsTestUnitProject < RailsProject
    def test_runner_program
      "ruby -I #{test_dir}"
    end

    def test_dir
      File.join(directory, 'test')
    end
  end
end
