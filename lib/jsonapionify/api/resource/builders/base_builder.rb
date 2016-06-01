module JSONAPIonify::Api
  module Resource::Builders
    class BaseBuilder
      include JSONAPIonify::Structure

      def self.build(*args, &block)
        new(*args, &block).build
      end

      attr_reader :resource

      def initialize(resource)
        @resource = resource
      end
    end
  end
end
