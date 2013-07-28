require File.expand_path('../rails_integration_tests', __FILE__)
require File.expand_path('../rails_test_unit_like_project', __FILE__)

module RailsTestUnitLikeIntegrationTests
  include RailsIntegrationTests

  def configure_project_generator(generator)
    super
    generator.mixin RailsTestUnitLikeProject
  end
end
