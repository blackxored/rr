require File.expand_path('../../spec_helper', __FILE__)
require File.expand_path('../../../common/rails_integration_tests', __FILE__)
require File.expand_path('../../../common/rails_minitest_project', __FILE__)
require File.expand_path('../../../common/cucumber_project', __FILE__)

describe 'Integration with MiniTest 4 and Rails 3' do
  include RailsIntegrationTests

  def configure_project_creator(creator)
    super
    creator.add RailsMinitestProject
    creator.configure do |project|
      project.rails_version = 3
      project.minitest_version = '~> 4.0'
    end
  end

  def self.including_the_adapter_manually_works(args={})
    specify "including the adapter manually works" do
      project = create_project
      file = project.build_test_file <<-EOT
        class ActiveSupport::TestCase
          include RR::Adapters::MiniTest
        end

        class FooTest < ActiveSupport::TestCase
          def test_the_correct_adapters_are_loaded
            assert_adapters_loaded #{matching_adapters.inspect}
          end

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

  def self.rr_hooks_into_the_test_framework_automatically(args={})
    specify "RR hooks into the test framework automatically" do
      project = create_project
      file = project.build_test_file <<-EOT
        class FooTest < ActiveSupport::TestCase
          include TestUnitLikeAdapterTests

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
      project_creator = build_project_creator do |creator|
        creator.add CucumberProject
      end
      project = project_creator.create
      result = project.run_command_within("bundle exec cucumber")
      result.should be_success
    end
  end

  # NOTE: We do not have tests here for autorequiring RR because MiniTest 4 does
  # not define lib/minitest.rb, so autorequiring it in the Gemfile doesn't
  # actually load it. So this is not supported.

  context 'when RR is being required manually, and RR is required before the test framework' do
    def configure_project_creator(creator)
      super
      creator.configure do |project|
        project.autorequire_gems = false
        project.include_rr_before_test_framework = true
      end
    end

    def matching_adapters
      [:MiniTest4, :MiniTest4ActiveSupport, :TestUnit200,
        :TestUnit200ActiveSupport]
    end

    including_the_adapter_manually_works
    using_rr_with_cucumber_works
  end

  context 'when RR is being required manually, and RR is required after the test framework' do
    def configure_project_creator(creator)
      super
      creator.configure do |project|
        project.autorequire_gems = false
        project.include_rr_before_test_framework = false
      end
    end

    def matching_adapters
      [:MiniTest4, :MiniTest4ActiveSupport, :TestUnit200,
        :TestUnit200ActiveSupport]
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
      project = create_project do |project|
        project.add_file 'app/models/person.rb', <<-EOT
          class Person < ActiveRecord::Base
            attr_accessible :name
          end
        EOT
        project.add_file "db/migrate/#{Time.now.strftime("%Y%m%d%H%M%S")}_create_people.rb", <<-EOT
          class CreatePeople < ActiveRecord::Migration
            def up
              create_table :people do |t|
                t.string :name
              end
            end

            def down
              drop_table :people
            end
          end
        EOT
      end
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
