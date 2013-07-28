require File.expand_path('../test_unit_like_project', __FILE__)

module TestUnitProject
  include TestUnitLikeProject

  attr_accessor :test_unit_gem_version

  def configure
    super
    if test_unit_gem_version
      gem_dependencies << gem_dependency(
        :name => 'test-unit',
        :version => test_unit_gem_version
      )
    end
    add_to_test_requires 'test/unit'
  end
end
