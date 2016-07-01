module JSONAPIonify::Api
  module Resource::Builders
    class FieldsBuilder < BaseBuilder

      attr_reader :context, :instance, :example_id
      delegate :action_name, :fields, to: :context
      delegate :type, to: :resource, prefix: true

      def initialize(resource, instance:, context:, example_id:)
        super(resource)
        @instance = instance
        @context = context
        @example_id = example_id
      end

      def resource_fields
        fields && fields[resource_type]
      end

      def build
        resource_fields.nil? ? build_default : build_sparce
      end

    end
  end
end
