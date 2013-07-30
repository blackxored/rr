module TestUnitTestHelper
  def path
    File.join(project.directory, 'test/test_helper.rb')
  end
end
