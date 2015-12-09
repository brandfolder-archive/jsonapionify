module JSONAPIonify::Api
  module Base::ClassMethods
    def inherited(subclass)
      super
      file     = caller[0].split(/\:\d/)[0]
      dir      = File.expand_path File.dirname(file)
      basename = File.basename(file, File.extname(file))
      Dir.glob(File.join(dir, basename, '**/*.rb')).each do |file|
        require file
      end
      subclass.const_set(:ResourceBase, Class.new(Resource).set_api(subclass))
    end

    def resource_class
      const_get(:ResourceBase, false)
    end

    def process_index(request)
      headers                    = resource_class.new(request).headers
      obj                        = JSONAPIonify.new_object
      obj[:meta]                 = { resources: {} }
      obj[:links]                = { self: request.root_url }
      obj[:meta][:documentation] = File.join(request.root_url, 'docs')
      obj[:meta][:resources]     = defined_resources.each_with_object({}) do |(name, _), hash|
        hash[name] = resource(name).get_url(request.root_url)
      end
      Rack::Response.new.tap do |response|
        response.status = 200
        headers.each { |k, v| response[k] = v }
        response['content-type'] = 'application/vnd.api+json'
        response.write obj.to_json
      end.finish
    end
  end
end