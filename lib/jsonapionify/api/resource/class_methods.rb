require 'active_support/rescuable'

module JSONAPIonify::Api
  module Resource::ClassMethods

    def self.extended(klass)
      klass.include ActiveSupport::Rescuable
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

    def type
      nil
    end

    def api
      nil
    end

    def get_url(base)
      URI.parse(base).tap do |uri|
        uri.path  = File.join(uri.path, type)
        params    = sticky_params(Rack::Utils.parse_nested_query(uri.query))
        uri.query = params.to_param if params.present?
      end.to_s
    end

    def actions_in_order
      indexes = %i{list create read update delete add replace remove}
      actions.sort_by { |action| indexes.index(action.name) || indexes.length }
    end

    def documentation_object(base_url)
      url = File.join(base_url, type)
      OpenStruct.new(
        name:          type,
        description:   JSONAPIonify::Documentation.render_markdown(@description || ''),
        relationships: relationships.map { |r| r.documentation_object url },
        attributes:    attributes.map(&:documentation_object),
        actions:       actions_in_order.map { |a| a.documentation_object self, base_url, type, true }
      )
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

    def default_strategy
      if defined?(ActiveRecord) && current_scope.is_a?(Class) && current_scope < ActiveRecord::Base
        :active_record
      elsif Enumerable === current_scope || (current_scope.is_a?(Class) && current_scope < Enumerable)
        :enumerable
      end
    rescue NotImplementedError
      nil
    end

  end
end
