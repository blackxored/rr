require File.expand_path('../../spec_helper', __FILE__)
require File.expand_path('../../../common/rails_integration_tests', __FILE__)
require File.expand_path('../../../common/test_unit_project', __FILE__)
require File.expand_path('../../../common/rails_test_unit_project', __FILE__)
require File.expand_path('../../../common/cucumber_project', __FILE__)

describe 'Integration with Test::Unit >= 2.5 and Rails 3' do
  include RailsIntegrationTests

  def configure_rails_project(project)
    project.rails_version = 3
  end

  def create_project
    super do |creator|
      creator.add TestUnitProject do |project|
        project.test_unit_version = '~> 2.5'
      end
      creator.add RailsTestUnitProject
      yield creator if block_given?
    end
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
      result.should have_no_errors_or_failures
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
      result.should have_no_errors_or_failures
    end
  end

  def self.using_rr_with_cucumber_works
    specify "using RR with Cucumber works" do
      project = create_project do |creator|
        creator.add CucumberProject
      end
      result = project.run_command_within("bundle exec cucumber")
      result.should be_success
    end
  end

  context 'when Bundler is autorequiring RR, and RR is listed before the test framework in the Gemfile' do
    def configure_rails_project(project)
      project.autorequire_gems = true
      project.include_rr_before_test_framework = true
    end

    including_the_adapter_manually_works
    using_rr_with_cucumber_works
  end

  context 'when Bundler is autorequiring RR, and RR is listed after the test framework in the Gemfile' do
    def configure_rails_project(project)
      project.autorequire_gems = true
      project.include_rr_before_test_framework = false
    end

    rr_hooks_into_the_test_framework_automatically
    including_the_adapter_manually_works
    using_rr_with_cucumber_works
  end

  context 'when RR is being required manually, and RR is required before the test framework' do
    def configure_rails_project(project)
      project.autorequire_gems = false
      project.include_rr_before_test_framework = true
    end

    including_the_adapter_manually_works
    using_rr_with_cucumber_works
  end

  context 'when RR is being required manually, and RR is required after the test framework' do
    def configure_rails_project(project)
      project.autorequire_gems = false
      project.include_rr_before_test_framework = false
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
      result.should fail_with_output(/1 failure/)
    end

    specify "the database is properly rolled back after an RR error" do
      project = create_project
      project.exec "echo 'create table if not exists people (name varchar(255));' | sqlite3 #{project.database_file_path}"
      project.add_file 'app/models/person.rb', <<-EOT
        class Person < ActiveRecord::Base
          attr_accessible :name
        end
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
      expect {
        result = project.run_test_file(file)
        result.should be_success
      }.to leave_database_table_clear(project, :people)
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
