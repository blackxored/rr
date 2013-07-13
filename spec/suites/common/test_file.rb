class TestFile
  attr_accessor \
    :body,
    :test_framework_paths,
    :prelude,
    :include_rr_before_test_framework,
    :before_require_test_framework,
    :after_require_test_framework,
    :autorequire_gems

  def initialize(project, body)
    self.prelude = project.test_file_prelude
    self.test_framework_paths = project.test_framework_paths
    self.include_rr_before_test_framework = project.include_rr_before_test_framework
    self.autorequire_gems = project.autorequire_gems
    self.body = body
  end

  def to_s
    prelude_lines = []
    prelude_lines.concat lines_to_require_test_framework
    if include_rr_before_test_framework
      prelude_lines.unshift "require 'rr'"
    else
      prelude_lines.push "require 'rr'"
    end
    if prelude
      prelude_lines.unshift prelude
    end
    join_lines(prelude_lines) + body
  end

  def lines_to_require_test_framework
    lines = test_framework_paths.map { |path| "require '#{path}'" }
    if before_require_test_framework
      lines.unshift before_require_test_framework
    end
    if after_require_test_framework
      lines.push after_require_test_framework
    end
    lines
  end

  private

  def join_lines(lines)
    lines.map { |line| line + "\n" }.join
  end
end
