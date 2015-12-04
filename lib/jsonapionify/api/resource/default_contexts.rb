module JSONAPIonify::Api
  module Resource::DefaultContexts
    extend ActiveSupport::Concern
    included do
      context(:id) do |request|
        request.env['jsonapionify.id']
      end

      context(:input) do |request|
        JSONAPIonify.parse request.body
      end

      context(:params) do |request|
        request.params
      end

      context(:errors) do |_, context|
        ErrorsObject.new(context)
      end
    end
  end
end