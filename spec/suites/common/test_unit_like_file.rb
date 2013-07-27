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
end
