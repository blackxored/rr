require File.expand_path('../rails_integration_tests', __FILE__)
require File.expand_path('../rails_minitest_project', __FILE__)

module RailsMinitestIntegrationTests
  include RailsIntegrationTests

  def configure_project_generator(generator)
    super
    generator.mixin RailsMinitestProject
  end
end
