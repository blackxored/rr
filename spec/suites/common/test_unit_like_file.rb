require File.expand_path('../test_unit_like_test_case', __FILE__)

module TestUnitLikeFile
  def setup(project, index)
    super
    @prelude << <<-EOT
      require 'test_helper'
      require '#{File.join(project.root_dir, 'spec/suites/common/test_unit_like_adapter_tests')}'
    EOT
    test_case_generator.mixin TestUnitLikeTestCase
  end

  def filename_prefix
    "#{"%02d" % @index}_test"
  end

  def add_working_test_case
    add_test_case do |test_case|
      test_case.add_test <<-EOT
        object = Object.new
        mock(object).foo
        object.foo
      EOT
      yield test_case if block_given?
    end
  end

  def add_working_test_case_with_adapter_tests
    add_working_test_case do |test_case|
      test_case.add_to_before_tests <<-EOT
        include TestUnitLikeAdapterTests
      EOT
      yield test_case if block_given?
    end
  end
end
