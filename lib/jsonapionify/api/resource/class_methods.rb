require 'active_support/rescuable'
require 'redcarpet'

module JSONAPIonify::Api
  module Resource::ClassMethods

    def self.extended(klass)
      klass.include ActiveSupport::Rescuable
    end

    def inherited(subclass)
      super
      subclass.class_eval do
        context(:api, readonly: true) { api }
        context(:resource, readonly: true) { self }
      end
    end

    def description(description)
      @description = description
    end

    def set_api(api)
      self.tap do
        define_singleton_method :api do
          api
        end
      end
    end

    def set_type(type)
      type = type.to_s
      self.tap do
        define_singleton_method :type do
          type
        end
      end
    end

    def api
      nil
    end

    def get_url(base)
      File.join base, type.to_s
    end

    def documentation_object(request)
      description           = JSONAPIonify::Documentation.render_markdown @description || ''
      @documentation_object ||= Class.new(SimpleDelegator) do
        define_method(:url) do
          File.join request.host, type
        end

        define_method(:description) do
          description
        end

        define_method(:resources) do
          defined_resources.each_with_object({}) do |(name, _), hash|
            hash[name.to_s] = resource(name).documentation_object
          end
        end

        define_method(:attributes) do
          super().each_with_object({}) do |attribute, hash|
            hash[attribute.name] = attribute
          end
        end

        define_method(:relationships) do
          relationship_definitions.each_with_object({}) do |relationship, hash|
            hash[relationship.name.to_s] = OpenStruct.new(
              resource: relationship.resource,
              allow:    relationship.allow
            )
          end
        end
      end.new(self)
    end

    def cache(store, *args)
      self.cache_store = ActiveSupport::Cache.lookup_store(store, *args)
    end

    def cache_store=(store)
      @cache_store = store
    end

    def cache_store
      @cache_store ||= api.cache_store
    end

  end
end
