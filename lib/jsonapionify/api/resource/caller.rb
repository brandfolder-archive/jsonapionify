module JSONAPIonify::Api
  module Resource::Caller
    def call
      do_respond = proc { __respond }
      do_request = proc { __request }
      response   = @callbacks ? run_callbacks(:request, @__context, &do_request) : do_request.call
    rescue Errors::RequestError
      response = error_response
    rescue Errors::CacheHit
      JSONAPIonify.logger.info "Cache Hit: #{@cache_options[:key]}"
      response = self.class.cache_store.read @cache_options[:key]
    rescue Exception => exception
      response = rescued_response exception, @__context, do_respond
    ensure
      self.class.cache_store.delete @cache_options[:key] unless response[0] < 300
    end

    def response_definition
      action.responses.find { |response| response.accept_with_matcher? @__context } ||
        action.responses.find { |response| response.accept_with_header? @__context } ||
        error_now(:not_acceptable)
    end

    private

    def __commit
      instance_exec(@__context, &action.block)
      fail Errors::RequestError if errors.present?
    end

    def __commit_and_respond
      do_respond = proc { __respond }
      do_commit  = proc { __commit }
      fail Errors::RequestError if errors.present?
      action.name && @callbacks ? run_callbacks("commit_#{action.name}", @__context, &do_commit) : do_commit.call
      @callbacks ? run_callbacks(:response, @__context, &do_respond) : do_respond.call
    end

    def __request
      do_commit_and_respond = proc { __commit_and_respond }
      action.name && @callbacks ? run_callbacks(action.name, @__context, &do_commit_and_respond) : do_commit_and_respond.call
    end

    def __respond(**options)
      raise Errors::DoubleRespondError if @response_called
      @response_called = true
      response_definition.call(self, @__context, **options).tap do |status, headers, body|
        raise Errors::RequestError if errors.present?
        if response_definition.cacheable && @cache_options.present?
          JSONAPIonify.logger.info "Cache Miss: #{@cache_options[:key]}"
          self.class.cache_store.write(
            @cache_options[:key],
            [status, headers, body.body],
            **@cache_options.except(:key)
          )
        end
      end
    end
  end
end
