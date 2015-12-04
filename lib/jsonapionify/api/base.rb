require 'active_support/core_ext/module/delegation'

module JSONAPIonify::Api
  class Base
    class << self
      delegate :context, :header, :helper, :rescue_from, :error, to: :resource_class

      def inherited(_)
        super
        file     = caller[0].split(/\:\d/)[0]
        dir      = File.expand_path File.dirname(file)
        basename = File.basename(file, File.extname(file))
        Dir.glob(File.join(dir, basename, '**/*.rb')).each do |file|
          require file
        end
      end

      def call(env)
        server.call(env)
      end

      def server
        @server ||= Server.new(self)
      end

      def description(string)
      end

      def defined_resources
        @defined_resources ||= {}
      end

      def resource_classes
        @resource_classes ||= {}
      end

      def resource_class
        @resource_class ||= Class.new(Resource).set_api(self)
      end

      def resource(name)
        resource_classes[name] ||= Class.new(resource_class, &defined_resources[name])
      end

      def resources
        defined_resources.each_with_object({}) do |(name, _), hash|
          hash[name] = resource(name)
        end
      end

      def define_resource(name, &block)
        defined_resources[name.to_sym] = block
      end

      def headers
        resource_class.new.headers
      end

    end

  end
end
