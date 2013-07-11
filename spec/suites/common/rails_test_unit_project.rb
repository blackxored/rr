module RailsTestUnitProject
  def initialize
    super
    self.test_file_prelude = <<-EOT
      require 'test_helper'
    EOT
  end
end
