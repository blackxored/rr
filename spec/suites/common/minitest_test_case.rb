require File.expand_path('../test_unit_test_case', __FILE__)

module MinitestTestCase
  include TestUnitTestCase

  def include_adapter_tests
    add_to_before_tests <<-EOT
      include MinitestAdapterTests
    EOT
  end
end
