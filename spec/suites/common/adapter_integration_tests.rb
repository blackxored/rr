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

  def create_project
    ProjectCreator.new.tap do |creator|
      configure_project_creator(creator)
      yield creator if block_given?
    end.create
  end

  def configure_project_creator(creator)
  end

  def build_test_file(body, options={})
    TestFile.new(body, options)
  end

  def fail_with_output(pattern)
    FailWithOutputMatcher.new(pattern)
  end

  def have_no_errors_or_failures
    HaveNoErrorsOrFailuresMatcher.new
  end
end
