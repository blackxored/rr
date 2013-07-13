module MinitestProject
  attr_accessor :minitest_version

  def create
    test_framework_paths << 'minitest/autorun'
    test_framework_dependencies << ['minitest', minitest_version]
    super
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
