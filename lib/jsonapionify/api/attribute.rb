module JSONAPIonify::Api
  class Attribute
    attr_reader :name, :type, :description, :read, :write, :required

    def initialize(name, type, description, read: true, write: true, required: false)
      @name        = name
      @type        = type
      @description = JSONAPIonify::Documentation.render_markdown description
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

    def allow
      Array.new.tap do |ary|
        ary << 'read' if read?
        ary << 'write' if write?
      end
    end
  end
end
