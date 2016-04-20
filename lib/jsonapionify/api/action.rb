require 'unstrict_proc'

module JSONAPIonify::Api
  class Action
    attr_reader :name, :block, :content_type, :responses, :prepend,
                :path, :request_method, :only_associated, :cacheable,
                :callbacks

    def self.dummy(&block)
      new(nil, nil, &block)
    end

    def self.error(name, &block)
      dummy do
        error_now name, &block
      end
    end

    def initialize(name, request_method, path = nil,
                   example_input: nil,
                   content_type: nil,
                   prepend: nil,
                   only_associated: false,
                   cacheable: false,
                   callbacks: true,
                   &block)
      @request_method  = request_method
      @path            = path || ''
      @prepend         = prepend
      @only_associated = only_associated
      @name            = name
      @example_input   = example_input
      @content_type    = content_type || 'application/vnd.api+json'
      @block           = block || proc {}
      @responses       = []
      @cacheable       = cacheable
      @callbacks       = callbacks
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
      raw_reqexp =
        build_path(
          base, name, include_path
        ).gsub(
          ':id', '(?<id>[^\/]+)'
        ).gsub(
          '/*', '/?[^\/]*'
        )
      Regexp.new('^' + raw_reqexp + '(\.[A-Za-z_-]+)?$')
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
      url  = build_path(base, name.to_s, include_path)
      path = URI.parse(url).path
      OpenStruct.new(
        id:              [request_method, path].join('-').parameterize,
        label:           label,
        sample_requests: example_requests(resource, url)
      )
    end

    def example_input(resource)
      request = Server::Request.env_for('http://example.org', request_method)
      context = ContextDelegate::Mock.new(
        request: request, resource: resource.new, _is_example_: true, includes: []
      )
      case @example_input
      when :resource
        {
          'data' => resource.build_resource(
            context,
            resource.example_instance_for_action(name, context),
            relationships: false,
            links:         false,
            fields:        resource.fields_for_action(name, context)
          ).as_json
        }.to_json
      when :resource_identifier
        {
          'data' => resource.build_resource_identifier(
            resource.example_instance_for_action(name, context)
          ).as_json
        }.to_json
      when Proc
        @example_input.call
      end
    end

    def example_requests(resource, url)
      responses.map do |response|
        opts                 = {}
        opts['CONTENT_TYPE'] = content_type if @example_input
        opts['HTTP_ACCEPT']  = response.accept
        if content_type == 'application/vnd.api+json' && @example_input
          opts[:input] = example_input(resource)
        end
        request  = Server::Request.env_for(url, request_method, opts)
        response = Server::MockResponse.new(*sample_request(resource, request))

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

    def response(**options, &block)
      new_response = Response.new(self, **options, &block)
      @responses.delete new_response
      @responses.push new_response
      self
    end

    def sample_context(resource)
      resource.context_definitions.dup.tap do |defs|
        collection_context          = proc do |context|
          3.times.map { resource.example_instance_for_action(action.name, context) }
        end
        defs[:_is_example_]         = Context.new proc { true }, true
        defs[:collection]           = Context.new collection_context
        defs[:paginated_collection] = Context.new proc { |context| context.collection }
        defs[:instance]             = Context.new proc { |context| context.collection.first }
        defs[:owner_context]        = Context.new proc { ContextDelegate::Mock.new }, true if defs.has_key? :owner_context
      end
    end

    def sample_request(resource, request)
      call(resource, request, context_definitions: sample_context(resource), callbacks: false)
    end

    def call(resource, request, context_definitions: nil, commit: true, callbacks: self.callbacks)
      action        = dup
      cache_options = {}
      resource.new.instance_eval do
        # Bootstrap the Action
        context = ContextDelegate.new(
          request,
          self,
          context_definitions || resource.context_definitions
        )

        context.action_name = action.name

        # Define Singletons
        define_singleton_method :cache do |key, **options|
          raise Errors::DoubleCacheError, "Cache was already called for this action" if @called
          @called = true
          cache_options.merge! options

          # Build the cache key, and obscure it.
          context.meta[:cache_key] = cache_options[:key] = cache_key(
            path:   request.path,
            accept: request.accept,
            params: context.params,
            key:    key
          )
          # If the cache exists, then fail to cache miss
          if self.class.cache_store.exist?(cache_options[:key]) && !context.invalidate_cache?
            raise Errors::CacheHit, cache_options[:key]
          end
        end if action.cacheable

        define_singleton_method :action do
          action
        end

        define_singleton_method :action_name do
          action.name
        end

        define_singleton_method :errors do
          context.errors
        end

        define_singleton_method :response_headers do
          context.response_headers
        end

        define_singleton_method :response_definition do
          action.responses.find { |response| response.accept_with_matcher? context } ||
            action.responses.find { |response| response.accept_with_header? context } ||
            error_now(:not_acceptable)
        end

        define_singleton_method :respond do |**options|
          raise Errors::DoubleRespondError if @response_called
          @response_called = true
          response_definition.call(self, context, **options).tap do |status, headers, body|
            raise Errors::RequestError if errors.present?
            if response_definition.cacheable && cache_options.present?
              JSONAPIonify.logger.info "Cache Miss: #{cache_options[:key]}"
              self.class.cache_store.write(
                cache_options[:key],
                [status, headers, body.body],
                **cache_options.except(:key)
              )
            end
          end
        end

        # Blocks
        do_respond = proc { respond }

        do_commit = proc {
          instance_exec(context, &action.block) if commit
          fail Errors::RequestError if errors.present?
        }

        do_commit_and_respond = proc {
          fail Errors::RequestError if errors.present?
          action.name && callbacks ? run_callbacks("commit_#{action.name}", context, &do_commit) : do_commit.call
          callbacks ? run_callbacks(:response, context, &do_respond) : do_respond.call
        }

        do_request = proc {
          action.name && callbacks ? run_callbacks(action.name, context, &do_commit_and_respond) : do_commit_and_respond.call
        }

        response = [0, {}, []]
        begin
          response = callbacks ? run_callbacks(:request, context, &do_request) : do_request.call
        rescue Errors::RequestError
          response = error_response
        rescue Errors::CacheHit
          JSONAPIonify.logger.info "Cache Hit: #{cache_options[:key]}"
          response = self.class.cache_store.read cache_options[:key]
        rescue Exception => exception
          response = rescued_response exception, context, do_respond
        ensure
          self.class.cache_store.delete cache_options[:key] unless response[0] < 300
        end
      end
    end
  end
end
