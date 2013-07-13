module RailsProject
  attr_accessor :rails_version

  def directory
    File.join(root_dir, 'tmp', 'rr-integration-tests', 'testapp')
  end

  def create
    super
    # remember that this has to be run with `bundle exec` to catch the correct
    # 'rails' executable (rails 3 or rails 4)!
    run_command "bundle exec rails new #{directory} --skip-bundle", :without_bundler_sandbox => true
    within do
      File.open('Gemfile', 'r+') do |f|
        contents = f.read
        contents << "\n\n" + build_partial_gemfile
        f.write(contents)
      end
      run_command('bundle env') if RR.debug?
      run_command('bundle check || bundle install')
      File.open('config/database.yml', 'w') do |f|
        f.write <<-EOT
          development: &development
            adapter: #{sqlite_adapter}
            database: #{database_file_path}
          test:
            <<: *development
        EOT
      end
      run_command 'bundle exec rake db:migrate'
    end
  end

  def build_partial_gemfile
    <<-EOT
      group :test do
        #{super}
      end
    EOT
  end

  def sqlite_adapter
    under_jruby? ? 'jdbcsqlite3' : 'sqlite3'
  end

  def database_file_path
    File.join(directory, 'db/test.sqlite3')
  end
end
