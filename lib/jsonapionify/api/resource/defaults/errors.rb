require 'oj'

module JSONAPIonify::Api
  module Resource::Defaults::Errors
    extend ActiveSupport::Concern

    included do
      rescue_from JSONAPIonify::Structure::ValidationError, error: :jsonapi_validation_error
      rescue_from Oj::ParseError, error: :json_parse_error

      Rack::Utils::SYMBOL_TO_STATUS_CODE.reject { |_, v| v < 400 }.each do |symbol, code|
        message = Rack::Utils::HTTP_STATUS_CODES[code]
        error symbol do
          title message
          status code.to_s
        end
      end

      error :data_missing do
        pointer ''
        title 'Missing Member'
        detail 'missing data member'
        status '422'
      end

      error :json_parse_error do
        title 'Parse Error'
        detail 'could not parse JSON object'
        status '422'
      end

      error :field_not_permitted do |type, field|
        parameter "fields[#{type}]"
        title 'Invalid Field'
        detail "type: `#{type}`, does not have field: `#{field}`"
        status '400'
      end

      error :attribute_type_error do |attribute|
        pointer "data/attributes/#{attribute}"
        status '500'
        title "Attribute type error"
      end

      error :attribute_required do |attribute|
        pointer "data/attributes/#{attribute}"
        title 'Attribute required'
        detail "attribute required: #{attribute}"
        status '422'
      end

      error :attribute_cannot_be_null do |attribute|
        pointer "data/attributes/#{attribute}"
        title 'Attribute cannot be null'
        status '500'
      end

      error :attribute_not_permitted do |attribute|
        pointer "data/attributes/#{attribute}"
        title 'Attribute not permitted'
        status '422'
        detail "attribute not permitted: #{attribute}"
      end

      error :attributes_missing do
        pointer 'data'
        title 'Missing Member'
        detail 'missing attributes member'
        status '422'
      end

      error :include_parameter_invalid do
        parameter 'sort'
        title 'Include parameter is invalid'
        status '400'
      end

      error :parameters_missing do |parameters|
        title 'Missing required parameters'
        detail "missing: #{parameters.to_sentence}"
        status '400'
      end

      error :parameter_invalid do |param|
        parameter param
        title 'Parameter Invalid'
        detail "parameter invalid: #{param}"
        status '400'
      end

      error :headers_missing do |headers|
        title 'Missing required headers'
        detail "missing: #{headers.to_sentence}"
        status '400'
      end

      error :sort_parameter_invalid do
        parameter 'sort'
        title 'Sort parameter is invalid'
        status '400'
      end

      error :page_parameter_invalid do |*paths|
        parameter ParamOptions.keypath_to_string(*paths)
        title 'Page parameter invalid'
        status '400'
      end

      error :request_object_invalid do |context, request_object|
        context.errors.set request_object.errors.as_collection
      end

      error :resource_invalid do
        title 'Invalid Resource'
        status '404'
      end
    end
  end
end
