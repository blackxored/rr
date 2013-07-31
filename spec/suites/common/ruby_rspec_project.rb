require File.expand_path('../ruby_project', __FILE__)
require File.expand_path('../rspec_project', __FILE__)

module RubyRSpecProject
  include RubyProject
  include RSpecProject

  def setuo
    super
    #test_file_generator.mixin RubyTestUnitTestFile
    #test_helper_generator.mixin RubyTestUnitTestHelper
  end

  def configure
    super
    if rspec_version == 1
      add_file 'Rakefile', <<-EOT
        require 'spec/rake/spectask'
        Spec::Rake::SpecTask.new(:spec)
      EOT
    else
      add_file 'Rakefile', <<-EOT
        require 'rspec/core/rake_task'
        RSpec::Core::RakeTask.new(:spec)
      EOT
    end
  end


  def generate_skeleton
    super
    FileUtils.mkdir_p File.join(directory, 'spec')
  end
end
