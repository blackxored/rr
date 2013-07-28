#require File.expand_path('../test_unit_test_helper', __FILE__)
require File.expand_path('../rails_test_helper', __FILE__)

module RailsTestUnitTestHelper
  #include TestUnitTestHelper
  include RailsTestHelper

  def path
    File.join(project.directory, 'test/test_helper.rb')
  end

  def start_of_requires
    Regexp.new(
      Regexp.escape('require File.expand_path(') +
      %q/(?:"|')/ +
      Regexp.escape('../../config/environment') +
      %q/(?:"|')/ +
      Regexp.escape(', __FILE__)')
    )
  end
end
