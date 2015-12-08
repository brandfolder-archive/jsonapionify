module JSONAPIonify::Api
  module Resource::DefaultErrors
    extend ActiveSupport::Concern
    included do
      Rack::Utils::SYMBOL_TO_STATUS_CODE.each do |symbol, code|
        message = Rack::Utils::HTTP_STATUS_CODES[code]
        error symbol do
          title message
          status code.to_s
        end
      end

      error :missing_data do
        source pointer: ""
        title 'Missing Member'
        detail 'missing data member'
      end

      error :missing_attributes do
        title 'Missing Member'
        detail 'missing attributes member'
      end

      error :input_error do
        set input.errors
      end

      error :output_error do
      end

      error :invalid_resource do
        title 'Invalid Resource'
        status '404'
      end
    end
  end
end