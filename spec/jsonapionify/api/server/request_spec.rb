require 'spec_helper'
module JSONAPIonify::Api
  describe Server::Request do
    include TestHelper
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
      instance { |scope, id| scope.find(id) }
      new_instance { |scope| scope.new }
      attribute :name, types.String, ''
      attribute :color, types.String, ''

      list
      create
      read
      update
      delete
    end

    describe 'content-type' do
      context 'with a body' do
        context 'supported content type' do
          it 'should not fail' do
            content_type 'application/vnd.api+json'
            body = { data: { type: "things", attributes: { name: "thing" } } }
            post "/things", json(body)
            expect(last_response.status).to eq 201
          end
        end

        context 'unsupported content type' do
          it 'should fail' do
            content_type 'text/plain'
            body = { data: { type: "things", attributes: { name: "thing" } } }
            post "/things", json(body)
            expect(last_response.status).to eq 415
          end
        end
      end

      context 'without a body' do
        context 'supported content type' do
          it 'should not fail' do
            content_type 'application/vnd.api+json'
            get "/things"
            expect(last_response.status).to eq 200
          end
        end

        context 'unsupported content type' do
          it 'should not fail' do
            content_type 'text/plain'
            get "/things"
            expect(last_response.status).to eq 200
          end
        end
      end
    end
  end
end
