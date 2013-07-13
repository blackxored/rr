module CucumberProject
  def create
    test_framework_dependencies << ['cucumber-rails', '~> 1.3.1', :require => false]
    test_framework_dependencies << ['database_cleaner']
    super
    run_command_within('bundle exec rails generate cucumber:install')
  end

  def test_runner_program
    'cucumber'
  end

  def test_dir
    File.join(directory, 'features')
  end
end
