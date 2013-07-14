require File.expand_path('../generator', __FILE__)
require File.expand_path('../test_case_generator', __FILE__)

class TestFileGenerator
  include Generator

  attr_accessor \
    :requires,
    :include_rr_before_test_framework,
    :autorequire_gems,
    :directory

  attr_reader :project, :index

  def setup(project, index)
    super
    self.include_rr_before_test_framework = project.include_rr_before_test_framework
    self.autorequire_gems = project.autorequire_gems
    @project = project
    @index = index
    @prelude = ""
    @body = ""
    @requires = []
  end

  def add_to_prelude(string)
    @prelude << string + "\n"
  end

  def add_to_body(string)
    @body << string + "\n"
  end

  def add_test_case(content=nil, &block)
    if content.nil?
      test_case = test_case_generator.call(self, &block)
      content = test_case.string
    end
    @body << content + "\n"
  end

  def call
    path = File.join(directory, "#{filename_prefix}.rb")
    if RR.debug?
      puts "Test file path: #{path}"
    end
    File.open(path, 'w') do |f|
      if RR.debug?
        puts "~ Test file contents ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        puts content
        puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
      end
      f.write(content)
    end
  end

  def test_case_generator
    @test_case_generator ||= TestCaseGenerator.factory
  end

  private

  def content
    prelude_lines = []

    if @prelude
      prelude_lines << @prelude
    end

    requires = lines_to_require_test_framework.dup
    unless autorequire_gems
      if include_rr_before_test_framework
        requires.unshift "require 'rr'"
      else
        requires.push "require 'rr'"
      end
    end
    prelude_lines.concat(requires)

    join_lines(prelude_lines) + @body
  end

  def lines_to_require_test_framework
    requires.map { |path| "require '#{path}'" }
  end

  def join_lines(lines)
    lines.map { |line| line + "\n" }.join
  end
end
