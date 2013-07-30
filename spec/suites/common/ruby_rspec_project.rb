require File.expand_path('../ruby_project', __FILE__)
require File.expand_path('../rspec_project', __FILE__)

module RubyRSpecProject
  include RubyProject
  include RSpecProject

  def setup
    super

    #test_file_generator.mixin RubyTestUnitTestFile
    #test_helper_generator.mixin RubyTestUnitTestHelper

    add_file 'Rakefile', <<-EOT
      require 'rspec/core/rake_task'
      RSpec::Core::RakeTask.new(:spec)
    EOT
  end


  def generate_skeleton
    super
    FileUtils.mkdir_p File.join(directory, 'spec')
  end
end
