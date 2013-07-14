module TestUnitLikeProject
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
