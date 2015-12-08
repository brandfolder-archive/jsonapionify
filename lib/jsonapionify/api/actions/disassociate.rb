module JSONAPIonify::Api::Actions
  module Disassociate
    extend ActiveSupport::Concern

    included do
      response status: 201 do
        JSONAPIonify::Structure::Object::TopLevel.new(data: {}).tap do |json|
          json[:data][:attributes] = fields.each_with_object({}) do |field, attributes|
            attributes[field] = instance.public_send(value)
          end
        end
      end
    end

  end
end