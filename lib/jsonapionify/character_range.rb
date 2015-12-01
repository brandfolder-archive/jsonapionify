module JSONAPIonify
  class CharacterRange
    include Enumerable

    class << self
      def [](*args)
        new(*args)
      end
    end

    def initialize(start_char, end_char)
      if [start_char, end_char].any? { |c| c.length > 1 }
        raise ArgumentError, 'must be single characters'
      end
      @start_char = start_char
      @end_char   = end_char
    end

    def each
      range.each do |ord|
        begin
          char = ord.chr(Encoding::UTF_8)
          yield char
        rescue RangeError
          next
        end
      end
    end

    def to_a
      each.to_a
    end

    private

    def range
      (@start_char.ord)..(@end_char.ord)
    end

  end
end
