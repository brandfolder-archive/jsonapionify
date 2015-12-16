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
    include Builders
    include Defaults

    def self.inherited(subclass)
      super(subclass)
      subclass.class_eval do
        context(:api, readonly: true) { api }
        context(:resource, readonly: true) { self }
      end
    end

    def self.example_instance(id=1)
      OpenStruct.new.tap do |instance|
        instance.send "#{id_attribute}=", (id).to_s
        attributes.select(&:read?).each do |attribute|
          instance.send "#{attribute.name}=", attribute.example
        end
      end
    end

  end
end
