module RailsProject
  attr_accessor :rails_version

  def setup
    super
    @file_creators = []
  end

  def directory
    File.join(root_dir, 'tmp', 'rr-integration-tests', 'testapp')
  end

  def add_to_prelude(string)
    test_helper_generator.configure do |file|
      file.add_to_prelude(string)
    end
  end

  def add_to_test_requires(path)
    test_helper_generator.configure do |file|
      file.add_to_requires(path)
    end
  end

  def call
    super
    create_rails_project
    test_helper_generator.call(self)
  end

  def add_file(file_name, content)
    @file_creators << lambda { super(file_name, content) }
  end

  def add_model_and_migration(model_name, table_name, attributes)
    model_class_name = model_name.to_s.capitalize
    symbolized_attribute_names = attributes.keys.map {|v| ":#{v}" }.join(', ')
    migration_timestamp = Time.now.strftime("%Y%m%d%H%M%S")
    camelized_table_name = table_name.to_s.capitalize
    migration_column_definitions = attributes.map do |name, type|
      "t.#{type} :#{name}"
    end.join("\n")

    model_content = "class #{model_class_name} < ActiveRecord::Base\n"
    if rails_version == 3
      model_content << "attr_accessible #{symbolized_attribute_names}\n"
    end
    model_content << "end\n"
    add_file "app/models/#{model_name}.rb", model_content

    add_file "db/migrate/#{migration_timestamp}_create_#{table_name}.rb", <<-EOT
      class Create#{camelized_table_name} < ActiveRecord::Migration
        def up
          create_table :#{table_name} do |t|
            #{migration_column_definitions}
          end
        end

        def down
          drop_table :#{table_name}
        end
      end
    EOT
  end

  def gem_dependency(dep)
    groups = Array(dep[:group] || [])
    groups << :test unless groups.include?(:test)
    dep[:group] = groups
    dep
  end

  def sqlite_adapter
    under_jruby? ? 'jdbcsqlite3' : 'sqlite3'
  end

  def database_file_path
    File.join(directory, 'db/test.sqlite3')
  end

  def test_helper_generator
    @test_helper_generator ||= TestHelperGenerator.factory
  end

  private

  def create_additional_files
    @file_creators.each { |creator| creator.call }
  end

  def create_rails_project
    # remember that this has to be run with `bundle exec` to catch the correct
    # 'rails' executable (rails 3 or rails 4)!
    run_command "bundle exec rails new #{directory} --skip-bundle", :without_bundler_sandbox => true
    within do
      File.open('Gemfile', 'r+') do |f|
        contents = f.read
        contents << "\n\n" + build_partial_gemfile
        f.write(contents)
      end
      create_additional_files
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
end
