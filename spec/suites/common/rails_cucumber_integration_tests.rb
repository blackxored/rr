require File.expand_path('../rails_integration_tests', __FILE__)
require File.expand_path('../../../adapter_integration_tests/rails_cucumber_project', __FILE__)

module RailsCucumberIntegrationTests
  include RailsIntegrationTests

  def build_project
    AdapterIntegrationTests::RailsCucumberProject.new
  end
end
