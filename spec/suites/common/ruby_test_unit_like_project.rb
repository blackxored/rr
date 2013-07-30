module RubyTestUnitLikeProject
  def setup
    super
    #test_file_generator.mixin RubyTestUnitTestFile
    #test_helper_generator.mixin RubyTestUnitTestHelper
  end

  def generate_skeleton
    super
    FileUtils.mkdir_p File.join(directory, 'test')
  end
end
