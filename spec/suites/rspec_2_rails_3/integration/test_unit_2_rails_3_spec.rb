require File.expand_path('../../spec_helper', __FILE__)
require File.expand_path('../../../common/rails_test_unit_integration_tests', __FILE__)
require File.expand_path('../../../common/rails_cucumber_integration_tests', __FILE__)

describe 'Integration with Test::Unit >= 2.5 and Rails 3' do
  include RailsIntegrationTests

  def configure_generic_project(project)
  end

  def create_project
    ProjectCreator.new.tap do |creator|
      creator << GenericProject.new.tap do |project|
        configure_generic_project(project)
      end
      creator << RailsProject.new.tap do |project|
        project.rails_version = 3
      end
      creator << TestUnitProject.new.tap do |project|
        project.test_framework_paths << 'test/unit'
        project.test_framework_dependencies << ['test-unit', '~> 2.5']
      end
      yield creator if block_given?
    end.create
  end

  def self.including_the_adapter_manually_works
    specify "including the adapter manually works" do
      project = create_project
      file = project.build_test_file <<-EOT
        class ActiveSupport::TestCase
          include RR::Adapters::TestUnit
        end

        class FooTest < ActiveSupport::TestCase
          # TODO: Do we need to include adapter tests here?

          def test_foo
            object = Object.new
            mock(object).foo
            object.foo
          end
        end
      EOT
      result = project.run_test_file(file)
      result.should be_success
    end
  end

  def self.rr_hooks_into_the_test_framework_automatically
    specify "RR hooks into the test framework automatically" do
      project = create_project
      file = project.build_test_file <<-EOT
        class FooTest < ActiveSupport::TestCase
          # TODO: Do we need to include adapter tests here?

          def test_foo
            object = Object.new
            mock(object).foo
            object.foo
          end
        end
      EOT
      result = project.run_test_file(file)
      result.should be_success
    end
  end

  def self.using_rr_with_cucumber_works
    specify "using RR with Cucumber works" do
      project = create_project do |creator|
        creator << CucumberProject.new
      end
      result = project.run_command_within("bundle exec cucumber")
      result.should be_success
    end
  end

  context 'when Bundler is autorequiring RR, and RR is listed before the test framework in the Gemfile' do
    def configure_generic_project(project)
      project.autorequire_gems = true
      project.require_rr_before_test_framework = true
    end

    including_the_adapter_manually_works
    using_rr_with_cucumber_works
  end

  context 'when Bundler is autorequiring RR, and RR is listed after the test framework in the Gemfile' do
    def configure_generic_project(project)
      project.autorequire_gems = true
      project.require_rr_before_test_framework = false
    end

    rr_hooks_into_the_test_framework_automatically
    including_the_adapter_manually_works
    using_rr_with_cucumber_works
  end

  context 'when RR is being required manually, and RR is required before the test framework' do
    def configure_generic_project(project)
      project.autorequire_gems = false
      project.require_rr_before_test_framework = true
    end

    including_the_adapter_manually_works
    using_rr_with_cucumber_works
  end

  context 'when RR is being required manually, and RR is required after the test framework' do
    def configure_generic_project(project)
      project.autorequire_gems = false
      project.require_rr_before_test_framework = false
    end

    rr_hooks_into_the_test_framework_automatically
    including_the_adapter_manually_works
    using_rr_with_cucumber_works

    specify "when RR raises an error it raises a failure not an exception" do
      project = create_project
      file = project.build_test_file <<-EOT
        class FooTest < ActiveSupport::TestCase
          def test_foo
            object = Object.new
            mock(object).foo
          end
        end
      EOT
      result = project.run_test_file(file)
      result.should fail_with_output(/1 failed/)
    end

    specify "the database is properly rolled back after an RR error" do
      project = create_project
      project.exec "echo 'create table if not exists people (name varchar(255));' | sqlite3 #{project.database_file}"
      project.add_file 'app/models/person.rb', <<-EOT
        class Person < ActiveRecord::Base; end
      EOT
      file = project.build_test_file <<-EOT
        class FooTest < ActiveRecord::TestCase
          def test_one
            Person.create!(:name => 'Joe Blow')
            object = Object.new
            mock(object).foo
          end
        end
      EOT
      expect { project.run_test_file(file) }.
        to_not change_database_table(project, :people)
    end

    specify "throwing an error in teardown doesn't mess things up" do
      project = create_project
      file = project.build_test_file <<-EOT
        class FooTest < ActiveRecord::TestCase
          teardown do
            raise 'hell'
          end

          def test_one
            # whatever
          end
        end
      EOT
      result = project.run_test_file(file)
      result.should fail_with_output(/1 error/)
    end
  end
end
