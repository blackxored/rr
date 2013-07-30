require File.expand_path('../ruby_project', __FILE__)
require File.expand_path('../minitest_project', __FILE__)
require File.expand_path('../ruby_test_unit_like_project', __FILE__)

module RubyMinitestProject
  include RubyProject
  include MinitestProject
  include RubyTestUnitLikeProject
end
