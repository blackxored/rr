require File.expand_path('../test_unit_project', __FILE__)
require File.expand_path('../rails_project', __FILE__)
require File.expand_path('../rails_test_unit_file', __FILE__)
require File.expand_path('../rails_test_unit_test_helper', __FILE__)
require File.expand_path('../test_helper_generator', __FILE__)

module RailsTestUnitProject
  include TestUnitProject
  include RailsProject

  def setup
    super
    test_file_generator.mixin RailsTestUnitFile
    test_helper_generator.mixin RailsTestUnitTestHelper
  end
end
