module JSONAPIonify::Api
  module Resource::DefaultActions
    extend ActiveSupport::Concern
    included do
      index
      create
      read
      update
      delete
    end
  end
end