module RailsTestHelper
  def call
    super
    File.open(path, 'r+') do |f|
      content = f.read

      regexp = Regexp.new(Regexp.escape(start_of_requires) + '.+?\n\n', Regexp::MULTILINE)
      requires = project.requires_with_rr(@requires)
      require_lines = project.require_lines(requires).map { |str| "#{str}\n" }.join + "\n\n"
      content.gsub!(regexp, require_lines)

      content << "\n\n" + @prelude

      puts "~ Content of #{File.basename(path)} ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
      puts content
      puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
      f.write(content)
    end
  end
end
