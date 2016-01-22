require 'unstrict_proc'

module JSONAPIonify::Api
  class Attribute
    using UnstrictProc
    attr_reader :name, :type, :description, :read, :write, :required

    def initialize(name, type, description, read: true, write: true, required: false, example: nil)
      raise ArgumentError, 'required attributes must be writable' if required && !write
      unless type.is_a? JSONAPIonify::Types::BaseType
        raise TypeError, "#{type} is not a valid JSON type"
      end
      @name        = name
      @type        = type
      @description = description
      @example     = example
      @read        = read
      @write       = write
      @required    = write ? required : false
    end

    def ==(other)
      self.class == other.class &&
        self.name == other.name
    end

    def options_json
      {
        name: name,
        read: read,
        write: write,
        required: required
      }
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

    def example(*args)
      case @example
      when Proc
        type.dump @example.unstrict.call(*args)
      when nil
        type.dump type.sample(name)
      else
        type.dump @example
      end
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
