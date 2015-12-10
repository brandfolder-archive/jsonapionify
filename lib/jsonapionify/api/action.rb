module JSONAPIonify::Api
  class Action
    attr_reader :name, :request_block, :content_type, :responses

    def initialize(name, content_type: 'application/vnd.api+json', &block)
      @name          = name
      @content_type  = content_type
      @request_block = block || proc {}
      @responses     = []
    end

    def initialize_copy(new_instance)
      super
      %i{@responses}.each do |ivar|
        value = instance_variable_get(ivar)
        new_instance.instance_variable_set(
          ivar, value.frozen? ? value : value.dup
        )
      end
    end

    def ==(other)
      self.class == other.class &&
        %i{@name @content_type}.all? do |ivar|
          instance_variable_get(ivar) == other.instance_variable_get(ivar)
        end
    end

    def supports?(request)
      @content_type == request.content_type
    end

    def response(status: nil, accept: nil, &block)
      new_response = Response.new(self, status: status, accept: accept, &block)
      @responses.delete new_response
      @responses << new_response
    end

    def call(resource, request)
      action = dup
      resource.new(request).instance_eval do
        define_singleton_method :response do |*args, &block|
          action.response(*args, &block)
        end

        begin
          instance_eval(&action.request_block)
          fail error_exception if errors.present?
          response_definition =
            action.responses.find { |response| response.accept? request } ||
              error_now(:not_acceptable)
          response_definition.call(self)
        rescue error_exception
          error_response
        rescue Exception => exception
          rescued_response exception
        end
      end
    end
  end
  Action::NotFound = Action.new(:not_found) do
    error_now :not_found
  end
end
