module MinitestProject
  attr_accessor :minitest_gem_version

  def configure
    super
    if minitest_gem_version
      gem_dependencies << gem_dependency(
        :name => 'minitest',
        :version => minitest_gem_version
      )
    end
    add_to_test_requires 'minitest/autorun'
  end

  def test_runner_command
    'rake test'
  end
end
