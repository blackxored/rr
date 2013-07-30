require File.expand_path('../test_unit_project', __FILE__)
require File.expand_path('../ruby_project', __FILE__)
require File.expand_path('../ruby_test_unit_like_project', __FILE__)

module RubyTestUnitProject
  include TestUnitProject
  include RubyProject
  include RubyTestUnitLikeProject

  def setup
    super
    add_file 'Rakefile', <<-EOT
      require 'rake/testtask'

      Rake::TestTask.new do |t|
        t.libs << 'test'
        t.test_files = FileList['test/*_test.rb']
      end
    EOT
  end
end
