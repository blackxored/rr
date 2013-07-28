module TestUnitProject
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

  def test_runner_command
    'rake test'
  end
end
