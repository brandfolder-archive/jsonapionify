require 'spec_helper'

module JSONAPIonify
  describe Api::Errors do
    include Api::TestHelper
    extend ApiHelper

    active_record_api(:things).create_table do |t|
      t.string :name
      t.string :color
    end.seed(count: 5) do |instance|
      instance.name  = Faker::Commerce.product_name
      instance.color = Faker::Commerce.color
    end.create_api do |model|
      scope { model }
      collection { model.all }
      instance { |scope, id| scope.find id }
      attribute :name, types.String, ''
      attribute :color, types.String, ''

      list
      read
      update do |context|
        context.request_attributes
      end
    end

    context 'request object error' do
      it 'error if id is an integer' do
        body = json(data: { id: 1, type: 'things' })
        content_type 'application/vnd.api+json'
        patch "/things/#{Thing.first.id}", body
        expect(last_response.status).to eq 422
      end
    end

    context 'rescued error' do
      it 'error if id is an integer' do
        get "/things/999999"
        expect(last_response.status).to eq 404
      end
    end
  end
end
