module AdapterIntegrationTests
  class TestFile
    attr_accessor \
      :body,
      :test_framework_paths,
      :include_rr_before_test_framework,
      :lines_to_require_helpers,
      :before_require_test_framework,
      :after_require_test_framework

    def initialize(body, options={})
      @body = body
      @options = options
      @test_framework_paths = []
    end

    def to_s
      prelude + @body
    end

    def prelude
      lines = []
      lines += lines_to_require_helpers
      if include_rr_before_test_framework
        lines << "require 'rr'"
        lines += lines_to_require_test_framework
      else
        lines += lines_to_require_test_framework
        lines << "require 'rr'"
      end
      join_lines(lines)
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
end
