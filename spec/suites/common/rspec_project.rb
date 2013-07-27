module RSpecProject
  attr_accessor :rspec_version

  def configure
    super
    gem_dependencies << gem_dependency(
      :name => 'rspec',
      :version => rspec_gem_version
    )
    add_to_test_requires 'rspec/autorun'

    add_file '.rspec', dot_rspec_content
  end

  def test_runner_command
    'rake spec'
  end

  private

  def rspec_gem_version
    case rspec_version
      when 2   then '~> 2.13'
      when 1   then '~> 1.3'
      when nil then raise ArgumentError, "rspec_version isn't set!"
      else          raise ArgumentError, "Invalid RSpec version '#{rspec_version}'"
    end
  end

  def dot_rspec_content
    content = <<-EOT
      --color
      --format documentation
    EOT
    if RR.debug?
      content << '--backtrace'
    end
    content
  end
end
