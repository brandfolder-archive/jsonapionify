module JSONAPIonify::Api
  module Resource::DefaultHelpers
    extend ActiveSupport::Concern
    included do

      helper :attributes do
        input.fetch(:data) {
          error_now :missing_data
        }.fetch(:attributes) {
          error_now :missing_attributes
        }
      end

      helper :resources do
        should_error = false
        data         = input.fetch(:data) {
          error_now :missing_data
        }
        instances    = data.map.each_with_index do |item, index|
          unless (resource = api.resource item[:type])
            should_error = true
            error :invalid_resource,
                  pointer: "data/#{index}",
                  detail: "could not find resource: `#{item[:type]}`"
          end
          unless (instance = resource.find_instance item[:id])
            should_error = true
            error :invalid_resource,
                  pointer: "data/#{index}",
                  detail: "could not find resource: `#{item[:type]}` with id: #{item[:id]}"
          end
          instance
        end
        raise error_exception if should_error
        instances
      end

      helper :resource do
        should_error = false
        item         = input.fetch(:data) {
          error_now :missing_data
        }
        unless (resource = api.resource item[:type])
          should_error = true
          error :invalid_resource,
                pointer: "data/#{index}",
                message: "could not find resource: `#{item[:type]}`"
        end
        unless (instance = resource.find_instance item[:id])
          should_error = true
          error :invalid_resource,
                pointer: "data/#{index}",
                detail: "could not find resource: `#{item[:type]}` with id: #{item[:id]}"
        end
        raise error_exception if should_error
        instance
      end
    end
  end
end