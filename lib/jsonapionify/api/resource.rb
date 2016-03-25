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

    def self.inherited(subclass)
      super(subclass)
      subclass.class_eval do
        context(:api, readonly: true) { self.class.api }
        context(:resource, readonly: true) { self }
      end
    end

    def self.cache_key(**options)
      api.cache_key(
        **options,
        resource: name
      )
    end

    def self.example_id_generator(&block)
      define_singleton_method :generate_id, &block
    end

    def self.example_instance_for_action(action, index: 1)
      id = generate_id(index)
      OpenStruct.new.tap do |instance|
        instance.send "#{id_attribute}=", (id).to_s
        actionable_attributes = attributes.select do |attr|
          attr.read? && attr.supports_action?(action)
        end
        actionable_attributes.each do |attribute|
          instance.send "#{attribute.name}=", attribute.example(id, index)
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
