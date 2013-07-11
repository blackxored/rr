require File.expand_path('../generic_project', __FILE__)

module AdapterIntegrationTests
  class FailWithOutputMatcher < Struct.new(:pattern)
    def matches?(result)
      result.output =~ pattern
    end

    def description
      "fail with output #{pattern.inspect}"
    end

    def failure_message_for_should
      "Expected running the test to produce output #{pattern.inspect} but it didn't"
    end

    def failure_message_for_should_not
      "Expected running the test to not produce output #{pattern.inspect} but it did"
    end
  end

  class HaveNoErrorsOrFailuresMatcher
    def matches?(result)
      match = result.output.match(/(\d+) error|(\d+) failure/)
      !match.captures.any? {|n| n && n != '0' }
    end

    def description
      "have no errors or failures"
    end

    def failure_message_for_should
      "Expected running the test to not result in errors or failures but it did"
    end

    def failure_message_for_should_not
      "Expected running the test to result in errors or failures, but it did not"
    end
  end

  def build_project
    AdapterIntegrationTests::GenericProject.new
  end

  #def create_project(project_class)
    #project_class.new.tap do |project|
      #configure_project(project)
      #yield project if block_given?
      #project.create
    #end
  #end

  def build_test_file(body, options={})
    # If this is a Rails app then the include_rr_before_test_framework option
    # doesn't actually require rr before requiring the test framework
    # since we won't actually require the test framework. Instead, it will set
    # require: false for the test framework in question and then explicitly
    # require it after
    TestFile.new(body, options)
  end

  def fail_with_output(pattern)
    FailWithOutputMatcher.new(pattern)
  end

  def have_no_errors_or_failures
    HaveNoErrorsOrFailuresMatcher.new
  end

=begin
  def all_tests_should_run
    project = create_project
    yield project
    output = project.run_test_file
    if output =~ /(\d+) failure/
      $1.should eq '0'
    end
    if output =~ /(\d+) error/
      $1.should eq '0'
    end
  end

  def tests_should_fail_with(message)
    project = create_project
    yield project
    output = project.run_test_file
    output.should match message
  end
=end
end
