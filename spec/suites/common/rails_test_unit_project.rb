require File.expand_path('../test_unit_project', __FILE__)

module RailsTestUnitProject
  include TestUnitProject

  def initialize
    super
    self.test_file_prelude = <<-EOT
      require 'test_helper'
      require '#{File.join(root_dir, 'spec/suites/common/test_unit_like_adapter_tests')}'
    EOT
  end

  def test_dir
    File.join(directory, 'test', 'unit')
  end
end
