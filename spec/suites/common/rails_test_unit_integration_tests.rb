require File.expand_path('../rails_integration_tests', __FILE__)
require File.expand_path('../../../adapter_integration_tests/rails_test_unit_project', __FILE__)

module RailsTestUnitIntegrationTests
  include RailsIntegrationTests

  #def build_project
  #  AdapterIntegrationTests::RailsTestUnitProject.new
  #end

  def build_test_file(*args)
    super.tap do |file|
      file.lines_to_require_helpers = [
        "require 'test_helper'"
      ]
    end
  end
end
