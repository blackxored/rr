require File.expand_path('../test_unit_like_file', __FILE__)

module RailsTestUnitLikeFile
  include TestUnitLikeFile

  def setup(project, index)
    super
    self.directory = File.join(project.directory, 'test', 'unit')
    test_case_generator.configure do |test_case|
      test_case.superclass = 'ActiveSupport::TestCase'
    end
  end
end
