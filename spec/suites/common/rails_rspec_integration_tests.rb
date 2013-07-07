require File.expand_path('../rails_integration_tests', __FILE__)

module RailsRSpecIntegrationTests
  include RailsIntegrationTests

  def build_project
    RailsRSpecProject.new
  end
end
