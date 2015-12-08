module JSONAPIonify::Api
  module Resource::DefaultContexts
    extend ActiveSupport::Concern

    included do
      context(:id) do |request|
        request.env['jsonapionify.id']
      end

      context(:input) do |request|
        JSONAPIonify.parse(request.body.read).tap do |input|
          input.validate
          if input.errors.present?
            error_now :input_errors
          end
        end
      end

      context :input_attributes do |request, context|
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

      context :input_resources do
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

      context :input_resource do |request, context|
        item = context.input.fetch(:data) {
          error_now :missing_data
        }
        find_resource item, pointer: 'data'
      end

      context(:params) do |request|
        request.params
      end

      context(:errors) do |_, context|
        ErrorsObject.new(context)
      end

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