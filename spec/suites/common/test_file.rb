class TestFile
  attr_accessor \
    :body,
    :test_framework_paths,
    :prelude,
    :include_rr_before_test_framework,
    :before_require_test_framework,
    :after_require_test_framework,
    :autorequire_gems

  def initialize(body)
    self.body = body
    self.test_framework_paths = []
  end

  def to_s
    prelude_lines = []
    prelude_lines << prelude if prelude
    unless autorequire_gems
      if include_rr_before_test_framework
        prelude_lines << "require 'rr'"
        prelude_lines += lines_to_require_test_framework
      else
        prelude_lines += lines_to_require_test_framework
        prelude_lines << "require 'rr'"
      end
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
