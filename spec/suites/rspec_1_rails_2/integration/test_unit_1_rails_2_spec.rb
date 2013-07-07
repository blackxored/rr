require File.expand_path('../../spec_helper', __FILE__)
require File.expand_path('../../../common/rails_test_unit_integration_tests', __FILE__)
require File.expand_path('../../../common/rails_cucumber_integration_tests', __FILE__)

describe 'Integration with Test::Unit 1 and Rails 2' do
  include RailsTestUnitIntegrationTests

  def configure_project(project)
    project.adapter_name = :test_unit_1_rails_2
    project.test_framework_path = 'test/unit'
  end

  specify "when RR raises an error it raises a failure not an exception" do
    tests_should_fail_with(/1 failure/) do |project|
      project.test_file_contents = <<-EOT
        class FooTest < ActiveSupport::TestCase
          def test_foo
            object = Object.new
            mock(object).foo
          end
        end
      EOT
    end
  end

  specify "it is still possible to include the adapter into the test framework manually" do
    all_tests_should_run do |project|
      project.test_file_contents = <<-EOT
        class ActiveSupport::TestCase
          include RR::Adapters::TestUnit
        end

        class FooTest < ActiveSupport::TestCase
          def test_foo
            object = Object.new
            mock(object).foo
            object.foo
          end
        end
      EOT
    end
  end

  specify "it is still possible to include the adapter into the test framework manually when RR is included before the test framework" do
    all_tests_should_run do |project|
      project.include_rr_before_test_framework = true
      project.test_file_contents = <<-EOT
        class ActiveSupport::TestCase
          include RR::Adapters::TestUnit
        end

        class FooTest < ActiveSupport::TestCase
          def test_foo
            object = Object.new
            mock(object).foo
            object.foo
          end
        end
      EOT
    end
  end

  specify "the database is properly rolled back after an RR error" do
    should_not_roll_back_database_table(:people) do |project|
      project.exec "echo 'create table if not exists people (name varchar(255));' | sqlite3 #{project.database_file}"
      project.add_file 'app/models/person.rb', <<-EOT
        class Person < ActiveRecord::Base; end
      EOT
      project.test_file_contents = <<-EOT
        class FooTest < ActiveRecord::TestCase
          def test_one
            Person.create!(:name => 'Joe Blow')
            object = Object.new
            mock(object).foo
          end
        end
      EOT
    end
  end

  specify "throwing an error in teardown doesn't mess things up" do
    all_tests_should_run do |project|
      project.test_file_contents = <<-EOT
        class FooTest < ActiveRecord::TestCase
          teardown do
            raise 'hell'
          end

          def test_one
            # whatever
          end
        end
      EOT
    end
  end

  context 'Cucumber' do
    include RailsCucumberIntegrationTests

    it "doesn't mess up RR's autohook mechanism" do
      project = create_project
      project.within do
        successfully_run_command("bundle exec cucumber")
      end
    end
  end
end
