module JSONAPIonify::Api
  module Resource::Builders
    class CursorBuilder < BaseBuilder

      attr_reader :context, :instance
      delegate :type, to: :resource, prefix: true
      delegate :sort_fields_from_sort_string, to: :resource
      delegate :request, :params, to: :context

      def initialize(resource, instance:, context:)
        super(resource)
        @instance = instance
        @context  = context
      end

      def build
        sort_string        = params['sort']
        sort_fields        = sort_fields_from_sort_string(sort_string)
        attrs_with_values  = sort_fields.each_with_object({}) do |field, hash|
          hash[field.name] = instance.send(field.name)
        end
        Base64.urlsafe_encode64(JSON.dump(
          {
            t: resource_type,
            s: sort_string,
            a: attrs_with_values
          }
        ))
      end

    end
  end
end
