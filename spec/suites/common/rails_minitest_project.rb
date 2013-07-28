require File.expand_path('../minitest_project', __FILE__)
require File.expand_path('../rails_project', __FILE__)
require File.expand_path('../rails_minitest_file', __FILE__)
require File.expand_path('../rails_minitest_test_helper', __FILE__)
require File.expand_path('../test_helper_generator', __FILE__)

module RailsMinitestProject
  include MinitestProject
  include RailsProject

  def setup
    super
    test_file_generator.mixin RailsMinitestFile
    test_helper_generator.mixin RailsMinitestTestHelper
  end
end
