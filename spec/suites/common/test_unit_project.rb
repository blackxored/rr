module TestUnitProject
  attr_accessor :test_unit_version

  def initialize
    super
    test_framework_paths << 'test/unit'
    test_framework_dependencies << ['test-unit', test_unit_version]
  end

  def test_runner_program
    "ruby -I #{test_dir}"
  end

  def test_dir
    File.join(directory, 'test')
  end
end
