require File.expand_path('../../spec_helper', __FILE__)
require File.expand_path('../../../common/rails_rspec_integration_tests', __FILE__)
require File.expand_path('../../../common/cucumber_project', __FILE__)

describe 'Integration with RSpec 2 and Rails 4' do
  include RailsRSpecIntegrationTests

  def configure_project_generator(project_generator)
    super
    project_generator.configure do |project|
      project.rails_version = 4
      project.rspec_version = 2
    end
  end

  def self.including_the_adapter_manually_works
    specify "including the adapter manually works" do
      project = generate_project do |project|
        project.add_to_prelude <<-EOT
          RSpec.configure do |c|
            c.mock_with :rr
          end
        EOT
      end
      project.add_test_file do |file|
        file.add_working_test_case_with_adapter_tests do |test_case|
          test_case.add_to_body <<-EOT
            it 'loads the correct adapters' do
              assert_adapters_loaded(#{adapters_that_should_be_loaded.inspect})
            end
          EOT
        end
      end
      result = project.run_tests
      result.should be_success
      result.should_not have_errors_or_failures
    end
  end

  def self.rr_hooks_into_the_test_framework_automatically
    specify "RR hooks into the test framework automatically" do
      project = generate_project
      project.add_test_file do |file|
        file.add_working_test_case
      end
      result = project.run_tests
      result.should be_success
      result.should_not have_errors_or_failures
    end
  end

  def self.using_rr_with_cucumber_works
    specify "using RR with Cucumber works" do
      pending "Cucumber doesn't work with Rails 4 just yet"
      project_generator = build_project_generator do |project_generator|
        project_generator.mixin CucumberProject
      end
      project = project_generator.call
      result = project.run_command_within("bundle exec cucumber")
      result.should be_success
    end
  end

  context 'when Bundler is autorequiring RR' do
    def configure_project_generator(project_generator)
      super
      project_generator.configure do |project|
        project.autorequire_gems = true
      end
    end

    def adapters_that_should_be_loaded
      [:RSpec2]
    end

    including_the_adapter_manually_works
    using_rr_with_cucumber_works
  end

  context 'when RR is being required manually' do
    def configure_project_generator(project_generator)
      super
      project_generator.configure do |project|
        project.autorequire_gems = false
      end
    end

    def adapters_that_should_be_loaded
      [:RSpec2]
    end

    rr_hooks_into_the_test_framework_automatically
    including_the_adapter_manually_works
    using_rr_with_cucumber_works

    specify "when RR raises an error it raises a failure not an exception" do
      project = generate_project
      project.add_test_file do |file|
        file.add_test_case do |test_case|
          test_case.add_test <<-EOT
            object = Object.new
            mock(object).foo
          EOT
        end
      end
      result = project.run_tests
      result.should fail_with_output(/1 failure/)
    end

    specify "the database is properly rolled back after an RR error" do
      project = generate_project do |project|
        project.add_model_and_migration(:person, :people, :name => :string)
      end
      project.add_test_file do |file|
        file.add_test_case do |test_case|
          test_case.add_test <<-EOT
            Person.create!(:name => 'Joe Blow')
            object = Object.new
            mock(object).foo
          EOT
        end
      end
      expect {
        result = project.run_tests
        result.should have_errors_or_failures
      }.to leave_database_table_clear(project, :people)
    end

    specify "it is still possible to use a custom RSpec-2 adapter" do
      project = generate_project do |project|
        project.add_to_prelude <<-EOT
          module RR
            module Adapters
              module RSpec2
                include RRMethods

                def setup_mocks_for_rspec
                  RR.reset
                end

                def verify_mocks_for_rspec
                  RR.verify
                end

                def teardown_mocks_for_rspec
                  RR.reset
                end

                def have_received(method = nil)
                  RR::Adapters::Rspec::InvocationMatcher.new(method)
                end
              end
            end
          end

          RSpec.configure do |c|
            c.mock_with RR::Adapters::RSpec2
          end
        EOT
      end
      project.add_test_file do |file|
        file.add_test_case_with_adapter_tests
      end
      result = project.run_tests
      result.should be_success
      result.should_not have_errors_or_failures
    end
  end
end
