require File.expand_path('../test_helper', __FILE__)

class TestUnitBacktraceTest < Test::Unit::TestCase
  def setup
    super
    @subject = Object.new
  end

  def teardown
    super
  end

  def test_trim_backtrace_is_set
    assert RR.trim_backtrace
  end

=begin
  def test_backtrace_tweaking
    if defined?(Test::Unit::TestResult)
      old_result = @_result
      result = Test::Unit::TestResult.new

      error_display = nil
      result.add_listener(Test::Unit::TestResult::FAULT) do |f|
        error_display = f.long_display
      end
      test_case = self.class.new(:backtrace_tweaking)
      test_case.run(result) {}

      assert !error_display.include?("lib/rr")
    end
  end
=end
end
