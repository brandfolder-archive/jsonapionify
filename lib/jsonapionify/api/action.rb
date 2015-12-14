module JSONAPIonify::Api
  class Action
    attr_reader :name, :request_block, :content_type, :responses, :prepend, :path

    def initialize(name, request_method, path = nil, content_type: nil, prepend: nil, &block)
      @request_method = request_method
      @path           = path || ''
      @prepend        = prepend
      @name           = name
      @content_type   = content_type || 'application/vnd.api+json'
      @request_block  = block || proc {}
      @responses      = []
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

    def path_regex(base, name)
      raw_reqexp = File.join(base, *[prepend, name, path].reject(&:blank?)).gsub(':id', '(?<id>[^\/]+)')
      Regexp.new('^' + raw_reqexp + '$')
    end

    def ==(other)
      self.class == other.class &&
        %i{@request_method @path @content_type @prepend}.all? do |ivar|
          instance_variable_get(ivar) == other.instance_variable_get(ivar)
        end
    end

    def supports?(request, base, name)
      (@content_type == request.content_type || request.content_type.nil?) &&
        request.request_method == @request_method &&
        request.path_info.match(path_regex(base, name))
    end

    def response(status: nil, accept: nil, &block)
      new_response = Response.new(self, status: status, accept: accept, &block)
      @responses.delete new_response
      @responses << new_response
    end

    def call(resource, request)
      action              = dup
      cache_hit_exception = Class.new StandardError
      cache_options       = {}
      resource.new.instance_eval do
        # Bootstrap the Action
        callbacks = resource.callbacks_for(action.name).new
        context   = ContextDelegate.new(request, self, self.class.context_definitions)

        # Define Singletons
        define_singleton_method :response do |*args, &block|
          action.response(*args, &block)
        end

        define_singleton_method :cache do |key, **options|
          cache_options.merge! options
          cache_options[:key] = [*{
            api:          [self.class.api.name, self.class.api.resource_signature].join('@'),
            resource:     self.class.type,
            content_type: request.content_type || '*',
            accept:       request.accept.join(','),
            params:       context.params.to_param
          }.map { |kv| kv.join(':') }, key].join('|')
          raise cache_hit_exception, cache_options[:key] if self.class.cache_store.exist?(cache_options[:key])
        end if request.get?

        # Define Shared Singletons
        [self, callbacks].each do |target|
          target.define_singleton_method :errors do
            context.errors
          end

          target.define_singleton_method :headers do
            context.headers
          end

          target.define_singleton_method :error_exception do
            context.error_exception
          end
        end

        begin
          # Run Callbacks
          case callbacks.run_callbacks(:request, context) { errors.present? }
          when true # Boolean true means errors
            raise error_exception
          when nil # nil means no result, callback failed
            error_now :internal_server_error
          end

          # Start the request
          instance_exec(context, &action.request_block)
          fail error_exception if errors.present?
          response_definition =
            action.responses.find { |response| response.accept? request } ||
              error_now(:not_acceptable)
          response_definition.call(self, context).tap do |status, headers, body|
            self.class.cache_store.write(
              cache_options[:key],
              [status, headers, body.body],
              **cache_options.except(:key)
            ) if request.get?
          end
        rescue error_exception
          error_response
        rescue cache_hit_exception
          self.class.cache_store.read cache_options[:key]
        rescue Exception => exception
          rescued_response exception
        end
      end
    end
  end
  Action::NotFound = Action.new(nil, nil) do
    error_now :not_found
  end
end
