module JSONAPIonify::Api
  module Resource::Builders
    class ResourceIdentifierBuilder < BaseBuilder
      include IdentityHelper

      attr_reader :example_id, :instance
      delegate :type, to: :resource, prefix: true

      def initialize(resource, instance:)
        super(resource)
        @instance = instance
        @example_id = resource.generate_id
      end

      def build
        return nil unless instance
        Objects::ResourceIdentifier.new.tap do |resource|
          resource[:type] = resource_type
          (id = build_id) && resource[:id] = id
        end
      end

    end
  end
end
