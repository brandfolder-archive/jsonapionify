module JSONAPIonify::Api
  class SortFieldSet
    include Enumerable
    delegate :[], :length, :to_s, :inspect, :each, to: :@list

    def initialize
      @list = []
      freeze
    end

    def to_hash
      map(&:to_hash).reduce(:merge)
    end

    def invert
      self.class.new.tap do |set|
        each do |field|
          name =
            case field.order
            when :asc
              "-#{field.name}"
            when :desc
              "#{field.name}"
            end
          set << SortField.new(name)
        end
      end
    end

    def <<(field)
      raise TypeError unless field.is_a? SortField
      @list << field unless @list.include? field
    end

  end
end
