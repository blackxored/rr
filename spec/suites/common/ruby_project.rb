require File.expand_path('../ruby_test_helper', __FILE__)

module RubyProject
  def setup
    super
    #test_file_generator.mixin RubyTestFile
    test_helper_generator.mixin RubyTestHelper
  end

  private

  def generate_skeleton
    FileUtils.mkdir_p(directory)

    within do
      File.open('Gemfile', 'w') do |f|
        contents = <<-EOT
          source 'https://rubygems.org'
          gem 'rake'
        EOT
        contents << "\n\n" + build_partial_gemfile
        f.write(contents)
      end
      run_command('bundle env') if RR.debug?
      run_command('bundle check || bundle install')

      create_files
    end
  end
end
