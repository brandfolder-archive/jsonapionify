require 'unstrict_proc'

module JSONAPIonify::Api
  class Attribute
    extend JSONAPIonify::Autoload
    autoload_all

    include Documentation
    using UnstrictProc
    attr_reader :name, :type, :description, :read, :write, :required, :hidden, :block

    def initialize(
      name,
      type,
      description,
      read: true,
      write: true,
      required: false,
      example: nil,
      hidden: false,
      &block
    )
      unless type.is_a? JSONAPIonify::Types::BaseType
        raise TypeError, "#{type} is not a valid JSON type"
      end

      @name              = name.to_sym
      @type              = type&.freeze
      @description       = description&.freeze
      @example           = example&.freeze
      @read              = read&.freeze
      @write             = write&.freeze
      @required          = required&.freeze
      @block             = block&.freeze
      @writeable_actions = write
      @readable_actions  = read
      @hidden            = !!hidden && (hidden == true || Array.wrap(hidden))

      freeze
    end

    def ==(other)
      self.class == other.class &&
        self.name == other.name
    end

    def hidden_for_action?(action_name)
      return false if hidden == false
      Array.wrap(hidden).any? { |h| h == true || h.to_s == action_name.to_s }
    end

    def supports_read_for_action?(action_name, context)
      case (setting = @readable_actions)
      when TrueClass, FalseClass
        setting
      when Hash
        !!JSONAPIonify::Continuation.new(setting).check(action_name, context) { true }
      when Array
        setting.map(&:to_sym).include? action_name
      when Symbol, String
        setting.to_sym === action_name
      else
        false
      end
    end

    def supports_write_for_action?(action_name, context)
      action = context.resource.class.actions.find { |a| a.name == action_name }
      return false unless %{POST PUT PATCH}.include? action.request_method
      case (setting = @writeable_actions)
      when TrueClass, FalseClass
        setting
      when Hash
        !!JSONAPIonify::Continuation.new(setting).check(action_name, context) { true }
      when Array
        setting.map(&:to_sym).include? action_name
      when Symbol, String
        setting.to_sym === action_name
      else
        false
      end
    end

    def resolve(instance, context, example_id: nil)
      if context.respond_to?(:_is_example_) && context._is_example_ == true
        return example(example_id)
      end
      block = self.block || proc { |attr, i| i.send attr }
      type.dump block.unstrict.call(self.name, instance, context, **context.kwargs(block))
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
        runtime_block: proc {}
      )
      nil
    end

    def required_for_action?(action_name, context)
      supports_write_for_action?(action_name, context) &&
        (required === true || Array.wrap(required).include?(action_name))
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

    def allow
      Array.new.tap do |ary|
        ary << 'read' if read?
        ary << 'write' if write?
      end
    end
  end
end
