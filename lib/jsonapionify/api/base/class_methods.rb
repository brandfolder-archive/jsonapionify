require 'active_support/core_ext/class/attribute'

module JSONAPIonify::Api
  module Base::ClassMethods

    def self.extended(klass)
      klass.class_attribute :load_path, :load_file
    end

    def resource_files
      files = Dir.glob(File.join(load_path, '**/*.rb'))
      files.concat(superclass < JSONAPIonify::Api::Base ? superclass.resource_files : []).sort
    end

    def resource_signature
      Digest::SHA2.hexdigest [*resource_files, load_file].map { |file| File.read file }.join
    end

    def signature
      [name, resource_signature].join('@')
    end

    def load_resources
      return if !load_path || resources_loaded?
      superclass.load_resources if superclass.respond_to? :load_resources
      @documentation_output = nil
      @last_signature       = resource_signature
      $".delete_if { |s| s.start_with? load_path }
      resource_files.each do |file|
        require file
      end
    end

    def resources_loaded?
      @last_signature == resource_signature
    end

    def http_error(action, request)
      Action.error(action).call(resource_class, request)
    end

    def root_url(request)
      URI.parse(request.root_url).tap do |uri|
        sticky_params = sticky_params(request.params)
        uri.query     = sticky_params.to_param if sticky_params.present?
      end.to_s
    end

    def process_index(request)
      headers                    = ContextDelegate.new(request, resource_class.new, resource_class.context_definitions).response_headers
      obj                        = JSONAPIonify.new_object
      obj[:meta]                 = { resources: {} }
      obj[:links]                = { self: request.url }
      obj[:meta][:documentation] = File.join(request.root_url, 'docs')
      obj[:meta][:resources]     = resources.each_with_object({}) do |resource, hash|
        if resource.actions.any? { |action| action.name == :list }
          hash[resource.type] = resource.get_url(root_url(request))
        end
      end
      Rack::Response.new.tap do |response|
        response.status = 200
        headers.each { |k, v| response[k] = v }
        response['content-type'] = 'application/vnd.api+json'
        response.write obj.to_json
      end.finish
    end

    def fields
      resources.each_with_object({}) do |resource, fields|
        fields[resource.type.to_sym] = resource.fields
      end
    end

    def cache(store, *args)
      self.cache_store = ActiveSupport::Cache.lookup_store(store, *args)
    end

    def cache_store=(store)
      @cache_store = store
    end

    def eager_load
      resources.each(&:eager_load)
    end

    def cache_store
      @cache_store ||= JSONAPIonify.cache_store
    end
  end
end
