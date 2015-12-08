module JSONAPIonify::Api::Actions
  module Create
    extend ActiveSupport::Concern
    included do
      response :create, status: 201 do

      end

      context :input do |request|
        JSONAPIonify::Stucture::Objects::Resource.from_json request.body
      end
    end
  end
end