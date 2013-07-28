require File.expand_path('../rails_integration_tests', __FILE__)
require File.expand_path('../rails_test_unit_project', __FILE__)

module RailsTestUnitIntegrationTests
  include RailsIntegrationTests

  def configure_project_generator(generator)
    super
    generator.mixin RailsTestUnitProject
  end
end
