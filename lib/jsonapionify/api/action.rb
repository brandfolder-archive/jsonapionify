module JSONAPIonify::Api
  class Action
    attr_reader :name, :request_block, :content_type, :responses, :prepend,
                :path, :request_method, :only_associated

    def self.dummy(&block)
      new(nil, nil, &block)
    end

    def self.error(name, &block)
      dummy do
        error_now name, &block
      end
    end

    def initialize(name, request_method, path = nil, require_body = nil, example_type = :resource, content_type: nil, prepend: nil, only_associated: false, &block)
      @request_method  = request_method
      @require_body    = require_body.nil? ? %w{POST PUT PATCH}.include?(@request_method) : require_body
      @path            = path || ''
      @prepend         = prepend
      @only_associated = only_associated
      @name            = name
      @example_type    = example_type
      @content_type    = content_type || 'application/vnd.api+json'
      @request_block   = block || proc {}
      @responses       = []
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

    def build_path(base, name, include_path)
      File.join(*[base].tap do |parts|
        parts << prepend if prepend
        parts << name
        parts << path if path.present? && include_path
      end)
    end

    def path_regex(base, name, include_path)
      raw_reqexp = build_path(base, name, include_path).gsub(':id', '(?<id>[^\/]+)')
      Regexp.new('^' + raw_reqexp + '$')
    end

    def ==(other)
      self.class == other.class &&
        %i{@request_method @path @content_type @prepend}.all? do |ivar|
          instance_variable_get(ivar) == other.instance_variable_get(ivar)
        end
    end

    def supports_path?(request, base, name, include_path)
      request.path_info.match(path_regex(base, name, include_path))
    end

    def documentation_object(base, resource, name, include_path, label)
      url = build_path(base, name.to_s, include_path)
      OpenStruct.new(
        label:           label,
        sample_requests: example_requests(resource, url)
      )
    end


    def example_requests(resource, url)
      responses.map do |response|
        opts                      = {}
        opts['HTTP_CONTENT_TYPE'] = content_type if @require_body
        opts['HTTP_ACCEPT']       = response.accept
        request                   = Server::Request.env_for(url, request_method, opts)
        opts[:input]              = case @example_type
                                    when :resource
                                      { 'data' => resource.build_resource(request, resource.example_instance, relationships: false, links: false).as_json }.to_json
                                    when :resource_identifier
                                      { 'data' => resource.build_resource_identifier(resource.example_instance).as_json }.to_json
                                    end if @content_type == 'application/vnd.api+json' && !%w{GET DELETE}.include?(request_method)
        request                   = Server::Request.env_for(url, request_method, opts)
        response                  = Server::MockResponse.new(*sample_request(resource, request))

        OpenStruct.new(
          request:  request.http_string,
          response: response.http_string
        )
      end
    end

    def supports_content_type?(request)
      @content_type == request.content_type || !request.has_body?
    end

    def supports_request_method?(request)
      request.request_method == @request_method
    end

    def supports?(request, base, name, include_path)
      supports_path?(request, base, name, include_path) &&
        supports_request_method?(request) &&
        supports_content_type?(request)
    end

    def response(status: nil, accept: nil, &block)
      new_response = Response.new(self, status: status, accept: accept, &block)
      @responses.delete new_response
      @responses << new_response
      self
    end

    def sample_request(resource, request)
      action = dup
      resource.new.instance_eval do
        sample_context                        = self.class.context_definitions.dup
        sample_context[:collection]           =
          Context.new proc { 3.times.map.each_with_index { |i| resource.example_instance(i + 1) } }, true
        sample_context[:paginated_collection] = Context.new proc { |context| context.collection }
        sample_context[:instance]             = Context.new proc { |context| context.collection.first }
        if sample_context.has_key? :owner_context
          sample_context[:owner_context] = Context.new proc { ContextDelegate::Mock.new }, true
        end

        # Bootstrap the Action
        context = ContextDelegate.new(request, self, sample_context)

        define_singleton_method :response_headers do
          context.response_headers
        end

        # Render the response
        response_definition =
          action.responses.find { |response| response.accept? request } ||
            error_now(:not_acceptable)
        response_definition.call(self, context)
      end
    end

    def call(resource, request)
      action        = dup
      cache_options = {}
      resource.new.instance_eval do
        # Bootstrap the Action
        callbacks = resource.callbacks_for(action.name).new
        context   = ContextDelegate.new(request, self, self.class.context_definitions)

        define_singleton_method :action_name do
          action.name
        end

        define_singleton_method :cache do |key, **options|
          cache_options.merge! options
          cache_options[:key] = [*{
            dsl:          JSONAPIonify.digest,
            api:          [self.class.api.name, self.class.api.resource_signature].join('@'),
            resource:     self.class.type,
            content_type: request.content_type || '*',
            accept:       request.accept.join(','),
            params:       context.params.to_param
          }.map { |kv| kv.join(':') }, key].join('|')
          raise Errors::CacheHit, cache_options[:key] if self.class.cache_store.exist?(cache_options[:key])
        end if request.get?

        # Define Shared Singletons
        [self, callbacks].each do |target|
          target.define_singleton_method :errors do
            context.errors
          end

          define_singleton_method :response_headers do
            context.response_headers
          end
        end

        begin
          # Run Callbacks
          case callbacks.run_callbacks(:request, context) { errors.present? }
          when true # Boolean true means errors
            raise Errors::RequestError
          when nil # nil means no result, callback failed
            error_now :internal_server_error
          end

          # Start the request
          instance_exec(context, &action.request_block)
          fail Errors::RequestError if errors.present?
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
        rescue Errors::RequestError
          error_response
        rescue Errors::CacheHit
          self.class.cache_store.read cache_options[:key]
        rescue Exception => exception
          rescued_response exception
        end
      end
    end
  end
end
