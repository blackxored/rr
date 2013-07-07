require File.expand_path('../generic_project', __FILE__)

module AdapterIntegrationTests
  class RailsProject < GenericProject
    attr_accessor :rails_version

    def directory
      File.join(root_dir, 'tmp', 'rr-integration-tests', 'testapp')
    end

    def setup
      run_command("rails new #{directory} --skip-bundle")
      File.open('Gemfile', 'r+') do |f|
        contents = f.read
        contents << "\n\n" + build_partial_gemfile
      end
      copy_file("gemfiles/#{appraisal_name}.gemfile", 'Gemfile')
      within do
        run_command('bundle install')
        File.open('config/database.yml', 'w') do |f|
          f.write <<-EOT
            development: &development
              adapter: #{sqlite_adapter}
              database: #{sqlite_db_file_path}
            test:
              <<: *development
          EOT
        end
=begin
        File.open('app/models/person.rb', 'w') do |f|
          f.write <<-EOT
            class Person < ActiveRecord::Base
            end
          EOT
        end
        FileUtils.cp(
          File.join(root_dir, 'spec/suites/common/test.sqlite3'),
          sqlite_db_file_path
        )
=end
      end
    end

    private

    def sqlite_adapter
      $is_java ? 'jdbcsqlite3' : 'sqlite3'
    end

    def sqlite_db_file_path
      File.join(directory, 'db/test.sqlite3')
    end

    def build_partial_gemfile
      "group :test do\n#{super}\nend"
    end
  end
end
