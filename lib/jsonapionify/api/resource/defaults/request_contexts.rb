module JSONAPIonify::Api
  module Resource::Defaults::RequestContexts
    extend ActiveSupport::Concern

    included do
      context(:request_body, readonly: true) do |context|
        context.request.body.read
      end

      context(:request_object, readonly: true) do |context|
        JSONAPIonify.parse(context.request_body).as(:client).tap do |input|
          error_now(:request_object_invalid, context, input) unless input.validate
        end
      end

      context(:id, readonly: true) do |context|
        context.request.env['jsonapionify.id']
      end

      context(:request_attributes, readonly: true) do |context|
        request_object = context.request_object

        # Validate Request Object
        request_object.validate
        error_now(:request_object_invalid, context, request_object) if request_object.errors.present?

        request_attributes = context.request_data.fetch(:attributes) do
          error_now :attributes_missing
        end
        request_attributes.tap do |attributes|
          # Check Permitted Attributes
          writable_attributes = context.request_resource.attributes.select(&:write?)
          if (extra_attributes = attributes.keys - writable_attributes.map(&:name)).present?
            extra_attributes.each { |attr| error :attribute_not_permitted, attr }
            raise Errors::RequestError
          end
        end.to_hash
      end

      context(:request_instances, readonly: true) do |context|
        should_error = false
        data         = context.request_data
        instances    = data.map.each_with_index do |item, i|
          begin
            find_instance item, pointer: "data/#{i}"
          rescue Errors::RequestError
            should_error = true
          end
        end
        raise Errors::RequestError if should_error
        instances
      end

      context(:request_instance, readonly: true) do |context|
        find_instance(context.request_data, pointer: 'data')
      end

      context(:request_resource, readonly: true) do |context|
        item = context.request_data
        find_resource item, pointer: 'data'
      end

      context(:request_data) do |context|
        context.request_object.fetch(:data) {
          error_now(:data_missing)
        }
      end
    end

    def find_instance(item, pointer:)
      should_error = false
      resource     = find_resource(item, pointer: pointer)
      unless (instance = resource.find_instance item[:id])
        should_error = true
        error :resource_invalid do
          self.pointer pointer
          self.detail "could not find resource: `#{item[:type]}` with id: #{item[:id]}"
        end
      end
      raise Errors::RequestError if should_error
      instance
    end

    def find_resource(item, pointer:)
      should_error = false
      unless (resource = self.class.api.resource item[:type])
        should_error = true
        error :resource_invalid do
          self.pointer pointer
          self.detail "could not find resource: `#{item[:type]}`"
        end
      end
      raise Errors::RequestError if should_error
      resource
    end

  end
end
