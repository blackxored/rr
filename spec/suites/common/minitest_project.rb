require File.expand_path('../test_unit_like_project', __FILE__)
require File.expand_path('../minitest_file', __FILE__)
require File.expand_path('../minitest_test_helper', __FILE__)

module MinitestProject
  include TestUnitLikeProject

  attr_accessor :minitest_version

  def configure
    super
    if minitest_version
      gem_dependencies << gem_dependency(
        :name => 'minitest',
        :version => minitest_gem_version
      )
    end
    add_to_test_requires 'minitest/autorun'
  end

  def setup
    super
    test_file_generator.mixin MinitestFile
    test_helper_generator.mixin MinitestTestHelper
  end

  private

  def minitest_gem_version
    case minitest_version
      when 4   then '~> 4.0'
      when 5   then '~> 5.0'
      when nil then raise ArgumentError, "minitest_version isn't set!"
      else          raise ArgumentError, "Invalid Minitest version '#{minitest_version}'"
    end
  end
end
