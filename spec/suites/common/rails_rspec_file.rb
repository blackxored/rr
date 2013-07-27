require File.expand_path('../rspec_file', __FILE__)

module RailsRSpecFile
  include RSpecFile
=begin
  # No need for the prelude as it goes in the spec helper.
  def setup(project, index)
    super
    @prelude = ""
  end
=end

  # Don't require anything; this will happen in the spec helper
  def all_requires
    []
  end
end
