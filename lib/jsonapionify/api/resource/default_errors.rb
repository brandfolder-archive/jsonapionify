module JSONAPIonify::Api
  module Resource::DefaultErrors
    extend ActiveSupport::Concern
    included do
      rescue_from JSONAPIonify::Structure::ValidationError, error: :jsonapi_validation_error

      Rack::Utils::SYMBOL_TO_STATUS_CODE.each do |symbol, code|
        message = Rack::Utils::HTTP_STATUS_CODES[code]
        error symbol do
          title message
          status code.to_s
        end
      end

      error :missing_data do
        pointer ''
        title 'Missing Member'
        detail 'missing data member'
      end

      error :invalid_field_param do |type, field|
        parameter "fields[#{type}]"
        title 'Invalid Field'
        detail "type: `#{type}`, does not have field: `#{field}`"
        status '400'
      end

      error :missing_attributes do
        title 'Missing Member'
        detail 'missing attributes member'
      end

      error :invalid_request_object do |context|
        context.errors.set context.request_object.errors.as_collection
      end

      error :invalid_resource do
        title 'Invalid Resource'
        status '404'
      end
    end
  end
end