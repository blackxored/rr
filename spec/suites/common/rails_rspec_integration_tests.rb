require File.expand_path('../rails_integration_tests', __FILE__)
require File.expand_path('../rails_rspec_project', __FILE__)

module RailsRSpecIntegrationTests
  include RailsIntegrationTests

  def configure_project_generator(generator)
    super
    generator.mixin RailsRSpecProject
  end
end
