module RSpecTestHelper
  def path
    File.join(project.directory, 'spec/spec_helper.rb')
  end
end
