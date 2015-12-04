module JSONAPIonify::Api::Actions
  module Create
    extend ActiveSupport::Concern
    included do
      context :input do |request|
        JSONAPIonify::Stucture::Objects::Resource.from_json request.body
      end

    end
  end
end