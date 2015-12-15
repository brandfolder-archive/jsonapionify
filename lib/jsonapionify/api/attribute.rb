module JSONAPIonify::Api
  class Attribute
    attr_reader :name, :type, :description, :read, :write, :required

    ExampleMap = {
      Array   => ['one', 'two', 'three'],
      Hash    => { one: 1, two: 2, three: 3 },
      String  => "Foo",
      Fixnum  => 42,
      Boolean => true,
      Float   => 3.14
    }

    def initialize(name, type, description, read: true, write: true, required: false)
      unless type.is_a? JSONAPIonify::Types::BaseType
        raise TypeError, "#{type} is not a valid JSON type"
      end
      @name        = name
      @type        = type
      @description = description
      @read        = read
      @write       = write
      @required    = required
    end

    def ==(other)
      self.class == other.class &&
        self.name == other.name
    end

    def required?
      !!@required
    end

    def optional?
      !required?
    end

    def read?
      !!@read
    end

    def write?
      !!@write
    end

    def example
      ExampleMap[@type]
    end

    def documentation_object
      OpenStruct.new(
        name:        name,
        type:        type.name,
        required:    required?,
        description: JSONAPIonify::Documentation.render_markdown(description),
        allow:       allow
      )
    end

    def allow
      Array.new.tap do |ary|
        ary << 'read' if read?
        ary << 'write' if write?
      end
    end
  end
end
