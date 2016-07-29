module JSONAPIonify::Api
  module Resource::Builders
    class AttributeBuilder < BaseBuilder

      UnsupportedError = Class.new(StandardError)

      attr_reader :attribute, :write, :context, :instance, :example_id
      delegate :action_name, to: :context

      def initialize(resource, example_id:, instance:, attribute:, context:, write: false)
        super(resource)
        @instance   = instance
        @context    = context
        @attribute  = attribute
        @write      = write
        @example_id = example_id
      end

      def build
        write ? build_writable : build_readable
      end

      private

      def build_writable
        raise UnsupportedError unless attribute&.supports_write_for_action?(action_name, context)
        attribute.resolve(instance, context, example_id: example_id)
      end

      def build_readable
        raise UnsupportedError unless attribute&.supports_read_for_action?(action_name, context)
        attribute.resolve(instance, context, example_id: example_id)
      end

    end
  end
end
