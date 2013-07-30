require File.expand_path('../ruby_integration_tests', __FILE__)
require File.expand_path('../ruby_rspec_project', __FILE__)

module RubyRSpecIntegrationTests
  include RubyIntegrationTests

  def configure_project_generator(generator)
    super
    generator.mixin RubyRSpecProject
  end
end
