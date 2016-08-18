require 'unstrict_proc'

module JSONAPIonify::Api
  class UnboundAction

    def self.error(name, &block)
      UnboundAction.new(name, nil) { error_now name, &block }
    end

    attr_reader :name, :block, :content_type, :responses, :prepend,
                :pathname, :request_method, :only_associated, :cacheable,
                :callbacks

    def initialize(name, request_method, pathname = nil,
                   content_type: nil,
                   prepend: '/',
                   only_associated: false,
                   cacheable: false,
                   callbacks: true,
                   body: true,
                   &block)
      @request_method  = request_method
      @pathname        = pathname || ''
      @prepend         = prepend
      @only_associated = only_associated
      @name            = name
      @content_type    = content_type || 'application/vnd.api+json' unless request_method == 'GET' || body == false
      @block           = block || proc {}
      @responses       = []
      @cacheable       = cacheable
      @callbacks       = callbacks
    end

    def bind(resource, context)
      Action.allocate.tap do |action|
        JSONAPIonify.copy_ivars(self, action)
        action.instance_variable_set :@resource, resource
        action.instance_variable_set :@context, context
      end
    end

    def inspect
      to_s.chomp('>') + " " +
        %i{name request_method pathname prepend content_type cacheable callbacks only_associated}.map do |method|
          "#{method}=#{send(method).inspect}"
        end.join(', ')
    end

    def ==(other)
      self.class == other.class &&
        %i{@request_method @pathname @content_type @prepend}.all? do |ivar|
          instance_variable_get(ivar) == other.instance_variable_get(ivar)
        end
    end

    def response(**options, &block)
      new_response = Response.new(self, **options, &block)
      @responses.delete new_response
      @responses.push new_response
      self
    end
  end
end
