require File.expand_path('../rspec_test_case', __FILE__)

module RSpecFile
  def setup(project, index)
    super
    test_case_generator.mixin RSpecTestCase
    self.directory = File.join(project.directory, 'spec')
  end

  def content
    content = super
    <<-EOT + content
      require 'spec_helper'
      require '#{File.join(project.root_dir, 'spec/suites/common/rspec_adapter_tests')}'
    EOT
  end

  def filename_prefix
    "#{"%02d" % @index}_spec"
  end

  def add_working_test_case_with_adapter_tests
    add_working_test_case do |test_case|
      test_case.add_to_before_tests <<-EOT
        include RSpecAdapterTests
      EOT
      yield test_case if block_given?
    end
  end
end
