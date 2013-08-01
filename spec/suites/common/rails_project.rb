require File.expand_path('../test_helper_generator', __FILE__)

module RailsProject
  attr_accessor :rails_version

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
    dep = dep.dup
    dep[:version] ||= '>= 0'
    if rails_version == 2
      dep[:lib] = dep.delete(:require) if dep.key?(:require)
      dep.delete(:path)
    else
      groups = Array(dep[:group] || [])
      groups << :test unless groups.include?(:test)
      dep[:group] = groups
    end
    dep
  end

  def sqlite_adapter
    under_jruby? ? 'jdbcsqlite3' : 'sqlite3'
  end

  def database_file_path
    File.join(directory, 'db/test.sqlite3')
  end

  def run_command_within(command, opts={})
    if using_bundler?
      command = "bundle exec #{command}"
    end
    super(command, opts)
  end

  def test_helper_generator
    @test_helper_generator ||= TestHelperGenerator.factory
  end

  private

  def generate_skeleton
    super

    create_rails_app

    within do
      if rails_version == 2
        fix_obsolete_reference_to_rdoctask_in_rakefile
        monkeypatch_gem_source_index
        copy_rr_to_vendor_gems
      end

      declare_and_install_gems
      create_files
      configure_database
      run_migrations
    end
  end

  def create_rails_app
    # remember that this has to be run with `bundle exec` to catch the correct
    # 'rails' executable (rails 3 or rails 4)!
    run_command create_rails_app_command, :without_bundler_sandbox => true
  end

  def create_rails_app_command
    command = "bundle exec rails"
    if rails_version == 2
      command << " #{directory}"
    else
      command << " new #{directory} --skip-bundle"
    end
    command
  end

  def copy_rr_to_vendor_gems
    FileUtils.rm_rf('vendor/gems')

    directory = "vendor/gems/rr-#{RR.version}"
    FileUtils.mkdir_p(directory)

    files = %w(rr.gemspec lib).map { |path| File.join(root_dir, path) }
    files.each do |file|
      FileUtils.cp_r(file, directory)
    end

    require 'yaml'
    Dir.chdir(directory) do
      spec = Gem::Specification.load(File.join(root_dir, 'rr.gemspec'))
      File.open('.specification', 'w') do |f|
        f.write(spec.to_yaml)
      end
    end
  end

  def monkeypatch_gem_source_index
    # http://djellemah.com/blog/2013/02/27/rails-23-with-ruby-20/
    prepend_to_file 'config/boot.rb', <<-EOT
      require 'rubygems'

      module Gem
        class << self
          undef_method :source_index if method_defined?(:source_index)
          undef_method :source_index= if method_defined?(:source_index)

          def source_index
            @source_index ||= sources
          end

          def source_index=(index)
            @source_index = index
          end

          #def cache
          #  source_index
          #end
        end

        SourceIndex = Specification

        class SourceList
          def search(dep)
            Specification.find_all_by_name(dep.name, dep.requirement)
          end
          #def each( &block ); end
          #include Enumerable
        end
      end
    EOT
  end

  def fix_obsolete_reference_to_rdoctask_in_rakefile
    replace_in_file 'Rakefile', 'rake/rdoctask', 'rdoc/task'
  end

  def declare_and_install_gems
    if using_bundler?
      super
    else
      declare_gems_within_environment
      install_gems_via_gems_install
    end
  end

  def declare_gems_within_environment
    replace_in_file 'config/environment.rb',
      /# Specify gems that this application depends on.+?\n\n/m,
      "#{build_gem_list}\n\n"
  end

  def install_gems_via_gems_install
    run_command 'gem list | grep rdoc || gem install rdoc --force'
    #run_command_within 'rake gems:refresh_specs gems:install --trace'
  end

  def declare_gems_within_gemfile
    append_to_file 'Gemfile', "\n\n#{build_gem_list}"
  end

  def install_gems_via_bundler
    if RR.debug?
      run_command 'bundle env'
    end

    run_command 'bundle check || bundle install'
  end

  def gem_dependency_line(dep)
    dep = dep.dup
    name = dep.delete(:name)
    if using_bundler?
      super
    else
      "config.gem #{name.to_s.inspect}, #{dep.inspect}"
    end
  end

  def configure_database
    create_file 'config/database.yml', <<-EOT
      development: &development
        adapter: #{sqlite_adapter}
        database: #{database_file_path}
      test:
        <<: *development
    EOT
  end

  def run_migrations
    run_command_within 'rake db:migrate --trace'
  end

  def using_bundler?
    rails_version > 2
  end
end
