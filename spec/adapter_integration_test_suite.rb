class AdapterIntegrationTestSuite
  ROOT_DIR = File.expand_path('../..', __FILE__)
  LIB_DIR = File.join(ROOT_DIR, 'lib')
  SANDBOX_DIR = File.join(ROOT_DIR, 'tmp/rr_integration_app')

  def initialize(adapter_name, test_runner, pattern, &block)
    @adapter_name = adapter_name
    @test_runner = test_runner
    @file_list = Dir.glob(File.join(SANDBOX_DIR, pattern))
    destroy
    FileUtils.mkdir_p(SANDBOX_DIR)
    yield self if block_given?
  end

  def destroy
    FileUtils.rm_rf(SANDBOX_DIR)
  end

  def add_file(filename, content)
    File.open(filename, 'w') {|f| f.write(content) }
  end

  def run
    bash = Session::Bash.new
    # Bundler will set RUBYOPT to "-I <path to bundler> -r bundler/setup".
    # This is unfortunate as it causes Bundler to be loaded before we
    # load Bundler in RR::Test.setup_test_suite, thereby rendering our
    # second Bundler.setup a no-op.
    files = @file_list.map {|f| "\"#{f}\"" }.join(" ")
    command = "env RUBYOPT='' #{@test_runner} #{files} 2>&1"
    puts command if RR.debug?
    @stdout, _ = bash.execute(command)
    exit_status = bash.exit_status
    @success = !!(exit_status == 0 || @stdout =~ /Finished/)
    if RR.debug? or !@success
      puts stdout
    end
  end

  attr_reader :stdout

  def success?
    @success
  end
end
