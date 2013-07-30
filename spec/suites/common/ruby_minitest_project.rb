require File.expand_path('../ruby_test_unit_project', __FILE__)
require File.expand_path('../minitest_project', __FILE__)

module RubyMinitestProject
  include RubyTestUnitProject
  include MinitestProject
end
