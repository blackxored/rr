module TestUnitProject
  attr_accessor :test_unit_version

  def initialize
    super
    test_framework_paths << 'test/unit'
    test_framework_dependencies << ['test-unit', test_unit_version]
  end

  def test_dir
    File.join(directory, 'test')
  end

  def test_filename
    'the_test.rb'
  end

  def test_runner_command
    'rake test'
  end
end
