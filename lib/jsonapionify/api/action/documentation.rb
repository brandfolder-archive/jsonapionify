module JSONAPIonify::Api
  module Action::Documentation
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
      context = resource.new(
        request: request,
        context_definitions: sample_context(resource)
      ).exec { |c| c }
      $pry = true if resource.type == 'organizations'
      case @example_input
      when :resource
        {
          'data' => resource.build_resource(
            context: context,
            instance: resource.example_instance_for_action(name, context, true),
            links:    false,
            write:    true
          ).as_json
        }.to_json
      when :resource_identifier
        {
          'data' => build_sample_resource_indentifier(name, resource, context).as_json
        }.to_json
      when Proc
        @example_input.call
      end
    end

    def build_sample_resource_indentifier(name, resource, context)
      rid = resource.build_resource_identifier(instance: resource.example_instance_for_action(name, context, true))
      resource.respond_to?(:rel) && resource.rel.is_a?(JSONAPIonify::Api::Relationship::Many) ? [rid] : rid
    end

    def example_requests(resource, url)
      responses.map do |response|
        opts                 = {}
        opts['CONTENT_TYPE'] = content_type if @example_input
        accept = response.accept || response.example_accept
        opts['HTTP_ACCEPT']   = accept
        if content_type == 'application/vnd.api+json' && @example_input
          opts[:input] = "{ ...request body... }"
        end
        url = "#{url}.#{response.extension}" if response.extension
        request  = Server::Request.env_for(url, request_method, opts)
        OpenStruct.new(
          request:  request.http_string,
        )
      end
    end
  end
end
