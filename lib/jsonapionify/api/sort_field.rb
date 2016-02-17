module JSONAPIonify::Api
  class SortField
    delegate :to_s, :inspect, to: :to_hash
    attr_reader :name, :order

    def initialize(name)
      @str = name.to_s
      if name.to_s.start_with? '-'
        @name  = name.to_s[1..-1].to_sym
        @order = :desc
      else
        @name  = name.to_sym
        @order = :asc
      end
      freeze
    end

    def ==(other)
      other.class == self.class &&
        other.name == self.name
    end

    def ===(other)
      other.class == self.class &&
        other.name == self.name
    end

    def id?
      name == :id
    end

    def contains_operator
      case @order
      when :asc
        :>=
      when :desc
        :<=
      end
    end

    def outside_operator
      case @order
      when :asc
        :>
      when :desc
        :<
      end
    end

    def to_s
      @str
    end

    def to_hash
      { name => order }
    end

  end
end
