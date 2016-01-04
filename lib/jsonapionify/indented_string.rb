module JSONAPIonify
  module IndentedString
    extend self

    refine String do
      def deindent
        shortest_line_length = lines.each_with_object([]) do |line, ary|
          next if line.empty?
          ary << line.match(/^\s*/)[0].length if line.rstrip.present?
        end.sort.first

        lines.map do |string|
          if string.length && !string.match(/^\s*$/)
            string.rstrip[shortest_line_length..-1]
          else
            string
          end
        end.join("\n")
      end
    end

    using self

    def deindent_string(string)
      string.deindent
    end
  end
end
