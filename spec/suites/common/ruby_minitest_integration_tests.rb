require File.expand_path('../ruby_integration_tests', __FILE__)
require File.expand_path('../ruby_minitest_project', __FILE__)

module RubyMinitestIntegrationTests
  include RubyIntegrationTests

  def configure_project_generator(generator)
    super
    generator.mixin RubyMinitestProject
  end
end
