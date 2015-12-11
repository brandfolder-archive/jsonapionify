require 'active_support/core_ext/class/attribute'

module JSONAPIonify::Api
  module Base::ClassMethods

    def self.extended(klass)
      klass.class_attribute :load_path
    end

    def inherited(subclass)
      super
      file           = caller[0].split(/\:\d/)[0]
      dir            = File.expand_path File.dirname(file)
      basename       = File.basename(file, File.extname(file))
      self.load_path = File.join(dir, basename)
      subclass.const_set(:ResourceBase, Class.new(Resource).set_api(subclass))
      load_resources
    end

    def resource_files
      Dir.glob File.join(load_path, '**/*.rb')
    end

    def resource_file_digest
      Digest::SHA2.hexdigest resource_files.map { |file| File.read file }.join
    end

    def load_resources
      return unless load_path
      if @last_digest != resource_file_digest
        @documentation_output = nil
        @last_digest          = resource_file_digest
        $".delete_if { |s| s.start_with? load_path }
        resource_files.each do |file|
          require file
        end
      end
    end

    def resource_class
      const_get(:ResourceBase, false)
    end

    def documentation_order(resources)
      @documentation_order = resources
    end

    def process_index(request)
      headers                    = ContextDelegate.new(request, resource_class.new, resource_class.context_definitions).headers
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

    def fields
      resources.each_with_object({}) do |(type, klass), fields|
        fields[type] = klass.attributes.select(&:read?).map(&:name)
      end
    end

    def cache(store, *args)
      self.cache_store = ActiveSupport::Cache.lookup_store(store, *args)
    end

    def cache_store=(store)
      @cache_store = store
    end

    def cache_store
      @cache_store ||= JSONAPIonify.cache_store
    end
  end
end
