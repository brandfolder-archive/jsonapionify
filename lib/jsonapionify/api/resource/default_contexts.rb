module JSONAPIonify::Api
  module Resource::DefaultContexts
    extend ActiveSupport::Concern

    included do

      # Response Objects
      context(:links, readonly: true) do |context|
        context.response_object[:links]
      end

      context(:meta, readonly: true) do |context|
        JSONAPIonify::Structure::Helpers::MetaDelegate.new context.response_object
      end

      context(:fields, readonly: true) do |context|
        should_error = false
        fields       = (context.request.params['fields'] || {}).each_with_object(self.class.api.fields) do |(type, fields), field_map|
          field_map[type.to_sym] =
            fields.to_s.split(',').map(&:to_sym).each_with_object([]) do |field, field_list|
              attribute = self.class.attributes.find do |attribute|
                attribute.read? && attribute.name == field
              end
              attribute ? field_list << attribute.name : error(:invalid_field_param, type, field) && (should_error = true)
            end
        end
        raise error_exception if should_error
        fields
      end

      context(:request_body, readonly: true) do |context|
        context.request.body.read
      end

      context(:request_object, readonly: true) do |context|
        JSONAPIonify.parse(context.request_body).as(:client).tap do |input|
          error_now(:request_object_invalid, context) unless input.validate
        end
      end

      context(:response_object) do |context|
        JSONAPIonify.parse(links: { self: context.request.url })
      end

      context(:errors, readonly: true) do
        ErrorsObject.new
      end

      # Request Objects
      context(:headers) do |context|
        self.class.header_definitions.each_with_object({}) do |(name, block), headers|
          headers[name.to_s] = instance_exec(context, &block)
        end
      end

      context(:id, readonly: true) do |context|
        context.request.env['jsonapionify.id']
      end

      context(:request_attributes, readonly: true) do |context|
        request_object = context.request_object
        error_now :invalid_type if context.request_resource <= self.class
        request_attributes = context.request_data.fetch(:attributes) do
          error_now :attributes_missing
        end
        request_attributes.tap do |attributes|
          writable_attributes = self.class.attributes.select(&:write?)
          required_attributes = writable_attributes.select(&:required?)
          optional_attributes = writable_attributes.select(&:optional?)
          attributes.must_contain!(required_attributes.map(&:name))
          attributes.may_contain!(optional_attributes.map(&:name))
          request_object.validate!(cache: false)
          error_now(:request_object_invalid, context) if request_object.errors.present?
        end
      end

      context(:request_resources, readonly: true) do |context|
        should_error = false
        data         = context.request_data
        instances    = data.map.each_with_index do |item, index|
          begin
            find_resource item, pointer: "data/#{index}"
          rescue error_exception
            should_error = true
          end
        end
        raise error_exception if should_error
        instances
      end

      context(:request_resource, readonly: true) do |context|
        item = context.request_data
        find_resource_with_context item, context, pointer: 'data'
      end

      context(:request_data) do |_, context|
        context.request_object.fetch(:data) {
          error_now_with_context(:missing_data, context)
        }
      end

      context(:params, readonly: true) do |context|
        context.request.params
      end

      id :id
      scope { raise NotImplementedError, 'scope not implemented' }
      collection { raise NotImplementedError, 'collection not implemented' }
      instance { raise NotImplementedError, 'instance not implemented' }
      new_instance { raise NotImplementedError, 'new instance not implemented' }

    end

    def find_instance(item, pointer:)
      should_error = false
      resource     = find_resource(item, pointer: pointer)
      unless (instance = resource.find_instance item[:id])
        should_error = true
        error :invalid_resource do
          self.pointer pointer
          self.detail "could not find resource: `#{item[:type]}` with id: #{item[:id]}"
        end
      end
      raise error_exception if should_error
      instance
    end

    def find_resource(item, pointer:)
      should_error = false
      unless (resource = self.class.api.resource item[:type])
        should_error = true
        error :invalid_resource do
          self.pointer pointer
          self.detail "could not find resource: `#{item[:type]}`"
        end
      end
      raise error_exception if should_error
      resource
    end

  end
end