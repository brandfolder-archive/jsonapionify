module JSONAPIonify::Api
  module Resource::Builders
    class IdBuilder < BaseBuilder
      attr_reader :instance

      def initialize(resource, instance:)
        super(resource)
        @instance = instance
      end

      def build
        instance.send(resource.id_attribute).to_s
      end
    end
  end
end
