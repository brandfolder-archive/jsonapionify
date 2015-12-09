module JSONAPIonify::Api
  module Resource::DefaultContexts
    extend ActiveSupport::Concern

    class MetaDelegate
      attr_reader :object

      def initialize(object)
        @object = object
      end

      def []=(k, v)
        object[:meta]    ||= {}
        object[:meta][k] = v
      end

      def [](k)
        object[:meta] && object[:meta][k]
      end
    end

    included do
      context(:id, readonly: true) do |request|
        request.env['jsonapionify.id']
      end

      context(:output_object, readonly: true) do |request|
        JSONAPIonify.parse(
          links: {
            self: request.url
          }
        )
      end

      context(:links, readonly: true) do |_, context|
        context.output_object[:links]
      end

      context(:meta, readonly: true) do |_, context|
        MetaDelegate.new context.output_object
      end

      context(:request, readonly: true) do |request|
        request
      end

      context(:input, readonly: true) do |request|
        JSONAPIonify.parse(request.body.read).tap do |input|
          error_now :input_errors unless input.validate
        end
      end

      context(:input_attributes, readonly: true) do |request, context|
        context.input_resource.fetch(:attributes) { error_now :missing_attributes }.tap do |attributes|
          writable_attributes = self.class.attributes.select(:write?)
          required_attributes = writable_attributes.select(&:required?)
          optional_attributes = writable_attributes.select(&:optional?)
          attributes.must_contain!(required_attributes.map(&:name))
          attributes.may_contain!(optional_attributes.map(&:name))
          input.validate
          error_now :input_error if input.errors.present?
        end
      end

      context(:input_resources, readonly: true) do
        should_error = false
        data         = input.fetch(:data) {
          error_now :missing_data
        }
        instances    = data.map.each_with_index do |item, index|
          begin
            find_resource item, pointer: "data/#{index}"
          rescue error_exception
            should_error =true
          end
        end
        raise error_exception if should_error
        instances
      end

      context(:input_resource, readonly: true) do |_, context|
        item = context.input.fetch(:data) {
          error_now :missing_data
        }
        find_resource item, pointer: 'data'
      end

      context(:params, readonly: true) do |request|
        request.params
      end

      context(:errors, readonly: true) do |_, context|
        ErrorsObject.new(context)
      end

      id :id
      collection { [] }
      instance { nil }
      new_instance { nil }

    end

    private def find_resource(item, pointer:)
      should_error = false
      unless (resource = api.resource item[:type])
        should_error = true
        error :invalid_resource,
              pointer: pointer,
              message: "could not find resource: `#{item[:type]}`"
      end
      unless (instance = resource.find_instance item[:id])
        should_error = true
        error :invalid_resource,
              pointer: pointer,
              detail:  "could not find resource: `#{item[:type]}` with id: #{item[:id]}"
      end
      raise error_exception if should_error
      instance
    end
  end
end