require File.expand_path('../test_unit_file', __FILE__)

module MinitestFile
  include TestUnitFile

  def setup(project, index)
    super
    test_case_generator.configure do |test_case|
      test_case.superclass =
        if project.minitest_version == 5
          'Minitest::Test'
        else
          'MiniTest::Unit::TestCase'
        end
    end
  end
end
