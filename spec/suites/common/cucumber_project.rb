module CucumberProject
  def setup
    super
    test_dependencies << ['cucumber-rails', '~> 1.3.1', :require => false]
    test_dependencies << ['database_cleaner']
  end

  def call
    super
    run_command_within('bundle exec rails generate cucumber:install')
  end

  def test_runner_program
    'cucumber'
  end

  # XXX: Does this even take effect?
  def test_dir
    File.join(directory, 'features')
  end
end
