require 'rspec/core/formatters/base_text_formatter'

class FullExampleNameFormatter < RSpec::Core::Formatters::BaseTextFormatter
  def initialize(output)
    super(output)
    @group_level = 0
  end

  def example_passed(example)
    super(example)
    output.puts passed_output(example)
  end

  def example_pending(example)
    super(example)
    output.puts pending_output(example, example.execution_result[:pending_message])
  end

  def example_failed(example)
    super(example)
    output.puts failure_output(example, example.execution_result[:exception])
  end

  def failure_output(example, exception)
    failure_color("#{example.full_description.strip} (FAILED - #{next_failure_index})")
  end

  def next_failure_index
    @next_failure_index ||= 0
    @next_failure_index += 1
  end

  def passed_output(example)
    success_color("#{example.full_description.strip}")
  end

  def pending_output(example, message)
    pending_color("#{example.full_description.strip} (PENDING: #{message})")
  end

  def example_group_chain
    example_group.parent_groups.reverse
  end
end
