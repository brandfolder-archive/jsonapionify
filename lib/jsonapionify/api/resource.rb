require 'active_support/rescuable'
require 'rack/response'
require 'active_support/json'

module JSONAPIonify::Api
  class Resource
    extend JSONAPIonify::Autoload
    autoload_all

    include Callbacks
    include Caller
    include Exec
    extend ClassMethods
    extend Definitions
    extend Documentation

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
      api.cache_key(**options, resource: name)
    end

    attr_reader :errors, :response_headers
    delegate :callbacks, :cacheable, to: :action, allow_nil: true

    def initialize(request:, context_overrides: {}, action: nil)
      @__context        = ContextDelegate.new(request, self, context_overrides)
      @errors           = @__context.errors
      @action           = action
      @response_headers = @__context.response_headers
      extend Caching if cacheable
    end

    def action
      @action ||= actions.find(&:supports?)
    end

    def path_actions
      @path_actions ||= actions.select(&:supports_path?)
    end

    def request_method_actions
      @request_method_actions ||= path_actions.select(&:supports_request_method?)
    end

    def relationship
      @relationship ||= relationships.find(&:supports?)
    end

    def relationships
      @relationships ||= self.class.relationship_definitions.map do |rel|
        self.class.relationship(rel.name).new(request: @__context.request)
      end
    end

    def actions
      @actions ||= self.class.actions.map do |unbound_action|
        unbound_action.bind(self, @__context)
      end
    end

  end
end
