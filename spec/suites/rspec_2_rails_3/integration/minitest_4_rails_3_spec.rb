require File.expand_path('../../spec_helper', __FILE__)
require File.expand_path('../../../common/rails_integration_tests', __FILE__)
require File.expand_path('../../../common/rails_test_unit_like_project', __FILE__)
require File.expand_path('../../../common/cucumber_project', __FILE__)

describe 'Integration with MiniTest 4 and Rails 3' do
  include RailsIntegrationTests

  def configure_project_generator(project_generator)
    super
    project_generator.mixin RailsTestUnitLikeProject
    project_generator.configure do |project|
      project.rails_version = 3
      project.test_dependencies << ['minitest', '~> 4.0']
      project.test_file_generator.configure do |file|
        file.requires << 'minitest/autorun'
      end
    end
  end

  def self.including_the_adapter_manually_works(args={})
    specify "including the adapter manually works" do
      project = generate_project
      project.add_test_file do |file|
        file.add_to_body <<-EOT
          class ActiveSupport::TestCase
            include RR::Adapters::MiniTest
          end
        EOT
        file.add_working_test_case_with_adapter_tests do |test_case|
          test_case.add_to_body <<-EOT
            def test_the_correct_adapters_are_loaded
              assert_adapters_loaded #{matching_adapters.inspect}
            end
          EOT
        end
      end
      result = project.run_tests
      result.should be_success
      result.should have_no_errors_or_failures
    end
  end

  def self.rr_hooks_into_the_test_framework_automatically(args={})
    specify "RR hooks into the test framework automatically" do
      project = generate_project
      project.add_test_file do |file|
        file.add_working_test_case
      end
      result = project.run_tests
      result.should be_success
      result.should have_no_errors_or_failures
    end
  end

  def self.using_rr_with_cucumber_works
    specify "using RR with Cucumber works" do
      project_generator = build_project_generator do |project_generator|
        project_generator.mixin CucumberProject
      end
      project = project_generator.call
      result = project.run_command_within("bundle exec cucumber")
      result.should be_success
    end
  end

  # NOTE: We do not have tests here for autorequiring RR because MiniTest 4 does
  # not define lib/minitest.rb, so autorequiring it in the Gemfile doesn't
  # actually load it. So this is not supported.

  context 'when RR is being required manually, and RR is required before the test framework' do
    def configure_project_generator(project_generator)
      super
      project_generator.configure do |project|
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
    def configure_project_generator(project_generator)
      super
      project_generator.configure do |project|
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
        result.should be_success
      }.to leave_database_table_clear(project, :people)
    end

    specify "throwing an error in teardown doesn't mess things up" do
      project = generate_project
      project.add_test_file do |file|
        file.add_test_case do |test_case|
          test_case.add_to_body <<-EOT
            def teardown
              raise 'hell'
            end
          EOT
          test_case.add_test("")   # doesn't matter
        end
      end
      result = project.run_tests
      result.should fail_with_output(/1 error/)
    end
  end
end
