module JSONAPIonify::Api
  module Resource::DefaultActions
    extend ActiveSupport::Concern
    included do
      index do
        error_now :not_found
      end

      create do
        error_now :not_found
      end

      read do
        error_now :not_found
      end

      update do
        error_now :not_found
      end

      delete do
        error_now :not_found
      end
    end
  end
end