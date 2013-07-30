require File.expand_path('../ruby_integration_tests', __FILE__)
require File.expand_path('../ruby_test_unit_project', __FILE__)

module RubyTestUnitIntegrationTests
  include RubyIntegrationTests

  def configure_project_generator(generator)
    super
    generator.mixin RubyTestUnitProject
  end
end
