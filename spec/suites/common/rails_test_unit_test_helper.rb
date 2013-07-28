#require File.expand_path('../test_unit_test_helper', __FILE__)
require File.expand_path('../rails_test_helper', __FILE__)

module RailsTestUnitTestHelper
  #include TestUnitTestHelper
  include RailsTestHelper

  def path
    File.join(project.directory, 'test/test_helper.rb')
  end
end
