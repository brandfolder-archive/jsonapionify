module JSONAPIonify::Api
  module Resource::DefaultErrors
    extend ActiveSupport::Concern
    included do
      error :not_found do
        title 'Not Found'
        detail 'The resource could not be found'
        status '404'
      end

      error :method_not_allowed do
        title 'Method Not Allowed'
        detail 'The provided method is not allowed'
        status '405'
      end

      error :unknown_error do
        title 'Unknown Error'
        detail 'An unknown error occurred'
        status '500'
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

      error :invalid_resource do
        title 'invalid resource'
        status '404'
      end
    end
  end
end