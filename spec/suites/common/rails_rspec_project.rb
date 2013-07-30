require File.expand_path('../rspec_project', __FILE__)
require File.expand_path('../rails_project', __FILE__)
require File.expand_path('../rails_rspec_file', __FILE__)
require File.expand_path('../rails_rspec_test_helper', __FILE__)

module RailsRSpecProject
  include RSpecProject
  include RailsProject

  def setup
    super
    test_file_generator.mixin RailsRSpecFile
    test_helper_generator.mixin RailsRSpecTestHelper
  end

  def configure
    super
    gem_dependencies << gem_dependency(
      :name => 'rspec-rails',
      :version => rspec_gem_version,
      :group => [:development, :test]
    )
    add_to_test_requires 'rspec/rails'
  end

  def generate_skeleton
    super
    run_command_within('bundle exec rails generate rspec:install --skip')
  end
end
