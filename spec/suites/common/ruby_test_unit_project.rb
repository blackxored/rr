require File.expand_path('../ruby_test_unit_like_project', __FILE__)
require File.expand_path('../test_unit_project', __FILE__)
require File.expand_path('../ruby_project', __FILE__)

module RubyTestUnitProject
  include RubyTestUnitLikeProject
  include TestUnitProject
  include RubyProject
end
