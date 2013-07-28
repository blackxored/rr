module RailsTestHelper
  def call
    super
    File.open(path, 'r+') do |f|
      content = f.read

      regexp = Regexp.new(
        '(' + start_of_requires.source + '.+?\n\n)',
        Regexp::MULTILINE
      )
      requires = project.requires_with_rr(@requires)
      require_lines = project.require_lines(requires).
        map { |str| "#{str}\n" }.
        join
      unless content.gsub!(regexp, '\1' + require_lines + "\n")
        raise "Regexp didn't match!\nRegex: #{regexp}\nContent:\n#{content}"
      end

      content << "\n\n" + @prelude

      puts "~ Content of #{File.basename(path)} ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
      puts content
      puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
      f.write(content)
    end
  end
end
