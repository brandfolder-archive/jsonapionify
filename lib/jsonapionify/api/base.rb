require 'redcarpet'
require 'active_support/core_ext/module/delegation'

module JSONAPIonify::Api
  class Base
    class << self
      delegate :context, :header, :helper, :rescue_from, :error, to: :resource_class

      ResourceNotDefined = Class.new StandardError

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

      def title(title)
        @title = title
      end

      def description(description)
        @description = description
      end

      def api_server
        @server ||= Server.new(self)
      end

      def doc_server(template: nil)
        ->(env) {
          request  = Server::Request.new env
          response = Rack::Response.new
          response.write JSONAPIonify::Documentation.new(documentation_object(request), template: template).result
          response.finish
        }
      end

      def documentation_object(request)
        title = @title || self.name
        description = @description || ''
        @documentation_object ||= Class.new(SimpleDelegator) do
          define_method(:base_url) do
            request.host
          end

          define_method(:title) do
            title
          end

          define_method(:description) do
            description
          end

          define_method(:resources) do
            defined_resources.each_with_object({}) do |(name, _), hash|
              hash[name.to_s] = resource(name).documentation_object(request)
            end
          end
        end.new(self)
      end

      def defined_resources
        @defined_resources ||= {}
      end

      def resource(type)
        type       = type.to_sym
        const_name = type.to_s.camelcase
        return const_get(const_name) if const_defined? const_name
        raise ResourceNotDefined, "Resource not defined: #{type}" unless resource_defined?(type)
        const_set const_name, Class.new(const_get(:ResourceBase), &defined_resources[type]).set_type(type)
      end

      def resource_defined?(name)
        !!defined_resources[name]
      end

      def resources
        defined_resources.each_with_object({}) do |(name, _), hash|
          hash[name] = resource(name)
        end
      end

      def define_resource(name, &block)
        const_name = name.to_s.camelcase
        remove_const(const_name) if const_defined? const_name
        defined_resources[name.to_sym] = block
      end

      def headers
        resource_class.new.headers
      end

    end

  end
end
