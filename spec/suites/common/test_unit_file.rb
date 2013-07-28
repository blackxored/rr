require File.expand_path('../test_unit_test_case', __FILE__)

module TestUnitFile
  def setup(project, index)
    super
    test_case_generator.mixin TestUnitTestCase
    self.directory = File.join(project.directory, 'test')
  end

  def content
    content = super
    <<-EOT + content
      require 'test_helper'
      require '#{File.join(project.root_dir, 'spec/suites/common/test_unit_adapter_tests')}'
    EOT
  end

  def filename_prefix
    "#{"%02d" % @index}_test"
  end

  # XXX: Do we need this if this is already in
  # TestUnitTestCase?
  def add_working_test_case_with_adapter_tests
    add_working_test_case do |test_case|
      test_case.add_to_before_tests <<-EOT
        include TestUnitAdapterTests
      EOT
      yield test_case if block_given?
    end
  end
end
