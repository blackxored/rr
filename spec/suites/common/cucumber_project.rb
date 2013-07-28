module CucumberProject
  def setup
    super
    gem_dependencies << gem_dependency(
      :name => 'cucumber-rails',
      :version => '~> 1.3.1',
      :require => false
    )
    gem_dependencies << gem_dependency(
      :name => 'database_cleaner'
    )
  end

  def call
    super
    run_command_within('bundle exec rails generate cucumber:install')
  end

  def test_runner_command
    'cucumber'
  end

  # XXX: Does this even take effect?
  #def test_dir
  #  File.join(directory, 'features')
  #end
end
