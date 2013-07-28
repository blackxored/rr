#require File.expand_path('../rspec_test_helper', __FILE__)
require File.expand_path('../rails_test_helper', __FILE__)

module RailsRSpecTestHelper
  #include RSpecTestHelper
  include RailsTestHelper

  def path
    File.join(project.directory, 'spec/spec_helper.rb')
  end
end
