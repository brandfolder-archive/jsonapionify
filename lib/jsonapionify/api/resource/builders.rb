module JSONAPIonify::Api
  module Resource::Builders
    extend ActiveSupport::Concern
    extend JSONAPIonify::Autoload

    autoload_all

    FALSEY_STRINGS = JSONAPIonify::FALSEY_STRINGS
    TRUTHY_STRINGS = JSONAPIonify::TRUTHY_STRINGS

    module ClassMethods
      include JSONAPIonify::Structure

      def build_resource(**options, &block)
        ResourceBuilder.build(self, **options)
      end

      def build_resource_collection(context:, collection:, include_cursors: false, &block)
        collection.each_with_object(
          Collections::Resources.new
        ) do |instance, resources|
          resources << build_resource(context: context, instance: instance, include_cursor: include_cursors, &block)
        end
      end

      def build_resource_identifier(instance:)
        ResourceIdentiferBuilder.build(self, instance: instance)
      end

      def build_resource_identifier_collection(collection:)
        collection.each_with_object(
          Collections::ResourceIdentifiers.new
        ) do |instance, resource_identifiers|
          resource_identifiers << build_resource_identifier(instance: instance)
        end
      end

      def build_cursor(**options)
        CursorBuilder.build(self, **options)
      end

    end

    delegated_methods = ClassMethods.instance_methods - instance_methods
    included do
      delegate(*delegated_methods, to: :class)
    end

  end
end
