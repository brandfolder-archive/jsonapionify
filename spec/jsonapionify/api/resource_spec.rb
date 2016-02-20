require 'spec_helper'

module JSONAPIonify
  describe Api::Resource do
    include Api::TestHelper
    extend ApiHelper

    describe "crud" do
      active_record_api(:things).create_table do |t|
        t.string :name
        t.string :color
      end.seed(count: 20) do |instance|
        instance.name  = Faker::Commerce.product_name
        instance.color = Faker::Commerce.color
      end.create_api do |model|
        scope { model }
        collection { model.all }
        instance { |scope, id| scope.find id }
        new_instance { |scope, context| scope.new id: context.request_id, **context.request_attributes }
        attribute :name, types.String, ''
        attribute :color, types.String, ''

        list

        create do |context|
          context.instance.save!
        end

        read do
          # Default
        end

        update do |context|
          context.instance.update_attributes! context.request_attributes
        end

        delete do |context|
          context.instance.destroy!
        end
      end

      describe 'GET /:resource' do
        it 'should return the list of resource instances' do
          get '/things'
          expect(last_response_json['data'].count).to eq model.count
          expect(last_response.status).to eq 200
        end
      end

      describe 'POST /:resource' do
        it 'should add a resource instance' do
          body = json(data: { type: 'things', attributes: { name: 'Card', color: 'blue' } })
          content_type 'application/vnd.api+json'
          expect { post '/things', body }.to change { model.count }.by 1
          expect(model.last.id.to_s).to eq last_response_json['data']['id']
          expect(model.last.name).to eq 'Card'
          expect(last_response.status).to eq 201
        end

        context 'with a custom id' do
          it 'should add a resource instance with a custom id' do
            body = json(data: { id: '999999', type: 'things', attributes: { name: 'Card', color: 'blue' } })
            content_type 'application/vnd.api+json'
            expect { post '/things', body }.to change { model.count }.by 1
            expect { model.find(999999) }.to_not raise_error
            expect(model.last.id.to_s).to eq last_response_json['data']['id']
            expect(model.last.name).to eq 'Card'
            expect(last_response.status).to eq 201
          end
        end
      end

      describe 'GET /:resource/:id' do
        it 'should fetch a resource instance' do
          get "/things/#{Thing.first.id}"
          expect(last_response_json['data']['attributes']['name']).to eq(model.first.name)
          expect(last_response.status).to eq 200
        end
      end

      describe 'PATCH /:resource/:id' do
        it 'should change a resource instance' do
          body = json(data: { id: Thing.first.id.to_s, type: 'things', attributes: { name: 'New Name' } })
          content_type 'application/vnd.api+json'
          expect { patch "/things/#{Thing.first.id}", body }.to change { model.first.name }.to 'New Name'
          expect(last_response.status).to eq 200
        end
      end

      describe 'DELETE /:resource/:id' do
        it 'should delete a resource instance' do
          expect { delete "/things/#{Thing.first.id}" }.to change { model.count }.by -1
          expect(last_response.status).to eq 204
          expect(last_response.body).to be_blank
        end
      end
    end
  end
end
