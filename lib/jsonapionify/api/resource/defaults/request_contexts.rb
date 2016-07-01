module JSONAPIonify::Api
  module Resource::Defaults::RequestContexts
    extend ActiveSupport::Concern

    included do
      context(:request_body, readonly: true, persisted: true) do |request:|
        request.body.read
      end

      context(:request_object, readonly: true, persisted: true) do |context, request_body:|
        JSONAPIonify.parse(request_body).as(:client).tap do |input|
          error_now(:request_object_invalid, context, input) unless input.validate
        end
      end

      context(:id, readonly: true, persisted: true) do |request:|
        request.env['jsonapionify.id']
      end

      context(:request_id, readonly: true, persisted: true) do |request_data:|
        request_data[:id]
      end

      context(:request_attributes, readonly: true, persisted: true) do |context, request:, action_name:, id:, request_data:|
        should_error = false

        request_attributes = request_data.fetch(:attributes) do
          error_now :attributes_missing
        end

        # Check for required attributes
        self.attributes.each do |attr|
          next unless attr.required_for_action?(action_name, context)
          if attr.read? || id
            example_id = self.build_id(instance: context.instance)
            next unless attr.resolve(
              context.instance, context, example_id: example_id
            ).nil?
          end
          unless request_attributes.has_key?(attr.name)
            error :attribute_required, attr.name
            should_error = true
          end
        end

        request_attributes.each_with_object({}) do |(attr, v), attributes|
          resource_attribute = self.attributes.find { |a| a.name == attr }
          is_actionable      = !!resource_attribute&.supports_write_for_action?(action_name, context)
          unless is_actionable
            error :attribute_not_permitted, attr
            should_error = true
          end

          begin
            attributes[attr] = resource_attribute.type.load(v)
          rescue JSONAPIonify::Types::LoadError
            error :attribute_type_error, attr
            should_error = true
          end
        end.tap do
          halt if should_error
        end
      end

      context(:request_relationships, readonly: true, persisted: true) do |request_data:|
        if request_data[:relationships]
          request_data[:relationships].each_with_object({}) do |(name, rel), obj|
            pointer = "data/relationships/#{name}/data"
            case rel[:data]
            when JSONAPIonify::Structure::Collections::Base
              obj[name] = find_instances(rel[:data], pointer: pointer)
            when JSONAPIonify::Structure::Objects::Base
              obj[name] = find_instance(rel[:data], pointer: pointer)
            end
          end
        else
          {}
        end
      end

      context(:request_instances, readonly: true, persisted: true) do |request_data:|
        (request_data ? find_instances(request_data, pointer: '/data') : [])
      end

      context(:request_instance, readonly: true, persisted: true) do |request_data:|
        find_instance(request_data, pointer: 'data')
      end

      context(:request_resource, readonly: true, persisted: true) do |request_data:|
        find_resource request_data, pointer: 'data'
      end

      context(:request_data, readonly: true, persisted: true) do |request_object:|
        request_object.fetch(:data) {
          error_now(:data_missing)
        }
      end

      context(:authentication, readonly: true, persisted: true) do
        OpenStruct.new
      end
    end

    def find_instances(items, pointer:)
      should_error = false
      instances    = items.map.each_with_index do |item, i|
        begin
          find_instance item, pointer: "#{pointer}/#{i}"
        rescue Errors::RequestError
          should_error = true
        end
      end
      halt if should_error
      instances
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
      halt if should_error
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
      halt if should_error
      resource
    end

  end
end
