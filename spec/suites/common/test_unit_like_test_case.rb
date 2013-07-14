module TestUnitLikeTestCase
  attr_accessor :superclass

  private

  def start_of_test_case
    "class FooTest < #{superclass}"
  end

  def build_test(index, body)
    ["def test_#{index}", body, "end"].map { |line| line + "\n" }.join
  end
end
