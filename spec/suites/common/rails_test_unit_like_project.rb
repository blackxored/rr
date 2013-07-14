require File.expand_path('../test_unit_like_project', __FILE__)

module RailsTestUnitLikeProject
  include TestUnitLikeProject

  def setup
    super
    test_file_generator.mixin RailsTestUnitLikeFile
  end
end
