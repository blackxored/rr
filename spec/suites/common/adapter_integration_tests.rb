require File.expand_path('../project_generator', __FILE__)

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

  class HaveErrorsOrFailuresMatcher
    def matches?(result)
      match = result.output.match(/(\d+) error|(\d+) failure/)
      match && match.captures.any? {|value| value && value.to_i > 0 }
    end

    def description
      "have errors or failures"
    end

    def failure_message_for_should
      "Expected running the test to result in errors or failures but it did not"
    end

    def failure_message_for_should_not
      "Expected running the test to not result in errors or failures, but it did "
    end
  end

  def build_project_generator
    ProjectGenerator.factory do |generator|
      configure_project_generator(generator)
      yield generator if block_given?
    end
  end

  def generate_project(&block)
    build_project_generator.new(&block).tap { |project| project.call }
  end

  def configure_project_generator(generator)
  end

  def fail_with_output(pattern)
    FailWithOutputMatcher.new(pattern)
  end

  def have_errors_or_failures
    HaveErrorsOrFailuresMatcher.new
  end
end
