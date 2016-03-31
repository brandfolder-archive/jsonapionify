require 'unstrict_proc'

module JSONAPIonify::Api
  class Attribute
    using UnstrictProc
    attr_reader :name, :type, :description, :read, :write, :required, :block

    def initialize(
      name,
      type,
      description,
      read: true,
      write: true,
      required: false,
      example: nil,
      only: nil,
      except: nil,
      &block
    )
      unless type.is_a? JSONAPIonify::Types::BaseType
        raise TypeError, "#{type} is not a valid JSON type"
      end

      @name           = name.to_sym
      @type           = type&.freeze
      @description    = description&.freeze
      @example        = example&.freeze
      @read           = read&.freeze
      @write          = write&.freeze
      @required       = required&.freeze
      @block          = block&.freeze
      @only_actions   = Array.wrap(only)&.freeze if only
      @except_actions = Array.wrap(except)&.freeze if except

      if required && required.is_a?(Symbol) && !supports_action?(required)
        raise ArgumentError,
              'required argument does not match a supported action'
      end
      freeze
    end

    def ==(other)
      self.class == other.class &&
        self.name == other.name
    end

    def supports_action?(action)
      !!JSONAPIonify::Continuation.new(
        if:     ->(a) { @only_actions.nil? || @only_actions.include?(a) },
        unless: ->(a) { @except_actions.present? && @except_actions.include?(a) }
      ).check(action) do
        true
      end
    end

    def resolve(instance, context, example_id: nil)
      if context.respond_to?(:_is_example_) && context._is_example_ == true
        return example(example_id)
      end
      block = self.block || proc { |attr, instance| instance.send attr }
      type.dump block.unstrict.call(self.name, instance, context)
    rescue JSONAPIonify::Types::DumpError => ex
      error_block =
        context.resource.class.error_definitions[:attribute_type_error]
      context.errors.evaluate(
        name,
        error_block:   error_block,
        backtrace:     ex.backtrace,
        runtime_block: proc {
          detail ex.message
        }
      )
    rescue JSONAPIonify::Types::NotNullError => ex
      error_block =
        context.resource.class.error_definitions[:attribute_cannot_be_null]
      context.errors.evaluate(
        name,
        error_block:   error_block,
        backtrace:     ex.backtrace,
        runtime_block: proc { detail ex.message }
      )
      nil
    end

    def required_for_action?(action_name)
      supports_action?(action_name) &&
        (required === true || Array.wrap(required).include?(action_name))
    end

    def options_json_for_action(action_name)
      {
        name:     name,
        required: required_for_action?(action_name)
      }
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
        required:    Array.wrap(required).join(', '),
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
