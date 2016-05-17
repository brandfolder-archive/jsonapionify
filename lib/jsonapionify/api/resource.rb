require 'active_support/rescuable'
require 'rack/response'
require 'active_support/json'

module JSONAPIonify::Api
  class Resource
    extend JSONAPIonify::Autoload
    autoload_all

    extend Definitions
    extend ClassMethods

    include ErrorHandling
    include Includer
    include Builders
    include Defaults

    delegate :type, :attributes, :relationships, to: :class

    def self.inherited(subclass)
      super(subclass)
      subclass.class_eval do
        context(:api, readonly: true, persisted: true) { self.class.api }
        context(:resource, readonly: true, persisted: true) { self }
      end
    end

    def self.cache_key(**options)
      api.cache_key(
        **options,
        resource: name
      )
    end

    def self.example_id_generator(&block)
      index = 0
      define_singleton_method(:generate_id) do
        instance_exec index += 1, &block
      end
      context :example_id do
        self.class.generate_id
      end
    end

    def self.example_instance_for_action(action, context)
      id = generate_id
      OpenStruct.new.tap do |instance|
        instance.send "#{id_attribute}=", id.to_s
        actionable_attributes = attributes.select do |attr|
          attr.supports_read_for_action?(action, context)
        end
        actionable_attributes.each do |attribute|
          instance.send "#{attribute.name}=", attribute.example(id)
        end
      end
    end

    example_id_generator { |val| val }

    def action_name
    end

    def cache_key(**options)
      self.class.cache_key(
        **options,
        action_name: action_name
      )
    end

  end
end
