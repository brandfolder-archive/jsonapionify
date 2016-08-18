module JSONAPIonify::Api
  module Resource::Caller
    using JSONAPIonify::DestructuredProc

    def call
      if action
        __call
      elsif relationship
        relationship.call
      elsif request_method_actions.present?
        error_now :unsupported_media_type
      elsif path_actions.present?
        error_now :forbidden
      else
        error_now :not_found
      end
    rescue Errors::RequestError => e
      raise e unless errors.present?
      error_response
    rescue Exception => exception
      do_respond = proc { __respond }
      rescued_response exception, @__context, do_respond
    end

    def response_definition
      extension = @__context.request.extension
      responses = action.responses
      response = nil
      @__context.request.accept.each do |accept|
        response = responses.find { |r| r.accept_with_matcher? @__context } ||
          responses.find { |r| r.accept_with_header? accept: accept, extension: extension }
        break if response
      end
      response || error_now(:not_acceptable)
    end

    private

    def __call
      do_request = proc { __request }
      callbacks ? run_callbacks(:request, &do_request) : do_request.call
    end

    def __commit
      instance_exec(@__context, &action.block.destructure)
    end

    def __commit_and_respond
      do_respond = proc { __respond }
      do_commit  = proc { __commit }
      halt if errors.present?
      action.name && callbacks ? run_callbacks("commit_#{action.name}", &do_commit) : do_commit.call
      callbacks ? run_callbacks(:response, &do_respond) : do_respond.call
    end

    def __request
      do_commit_and_respond = proc { __commit_and_respond }
      action.name && callbacks ? run_callbacks(action.name, &do_commit_and_respond) : do_commit_and_respond.call
    end

    def __respond(**options)
      raise Errors::DoubleRespondError if @response_called
      @response_called = true
      response_definition.call(self, @__context, **options).tap do |status, headers, body|
        halt if errors.present?
      end
    end
  end
end
