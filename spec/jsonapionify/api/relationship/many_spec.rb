require 'spec_helper'
module JSONAPIonify::Api
  describe Relationship::Many do
    include JSONAPIonify::Api::TestHelper

    set_api(MyApi)

    describe 'GET /:resource/:id/:name' do
      it 'should fetch the related objects' do
        get "/users/#{User.first.id}/things"
        last_response_json['data'].each do |item|
          expect(item['attributes']['name']).to eq User.first.things.find(item['id']).name
        end
        expect(last_response.status).to eq 200
      end
    end

    describe 'POST /:resource/:id/:name' do
      it 'should create and associate new resources' do
        body = json(data: { type: 'things', attributes: { name: 'Card', color: 'blue' } })
        content_type 'application/vnd.api+json'
        expect { post "/users/#{User.first.id}/things", body }.to change { User.first.things.count }.by 1
        expect(last_response.status).to eq 201
      end
    end

    describe 'GET /:resource/:id/relationships/:name' do
      it 'should fetch the related object ids' do
        get "/users/#{User.first.id}/things"
        last_response_json['data'].each do |item|
          expect { User.first.things.find(item['id']) }.to_not raise_error
          identifier = JSONAPIonify::Structure::Objects::ResourceIdentifier.new(
            item.deep_symbolize_keys
          )
          expect { identifier.compile! }.to_not raise_error
        end
        expect(last_response.status).to eq 200
      end

      context 'Dynamic Counters' do
        it "should return a proper count" do
          get "/users"
          last_response_json['data'].each do |item|
            expect(item['attributes']['thing_count']).to eq User.find(item['id']).things.count
          end
        end

        it "should return a proper count" do
          get "/users/#{User.first.id}"
          expect(last_response_json['data']['attributes']['thing_count']).to eq User.first.things.count
        end
      end
    end

    describe 'POST /:resource/:id/relationships/:name' do
      it 'should add new relationships' do
        body = json(data: [{ id: Thing.last.id.to_s, type: 'things' }])
        content_type 'application/vnd.api+json'
        User.first.things.delete(Thing.last)
        expect { post "/users/#{User.first.id}/relationships/things", body }.to change { User.first.things.count }.by(1)
        last_response_json['data'].each do |item|
          expect { User.first.things.find(item['id']) }.to_not raise_error
          identifier = JSONAPIonify::Structure::Objects::ResourceIdentifier.new(
            item.deep_symbolize_keys
          )
          expect { identifier.compile! }.to_not raise_error
        end
        expect(last_response.status).to eq 200
      end
    end

    describe 'PATCH /:resource/:id/relationships/:name' do
      it 'should add new relationships' do
        body = json(data: [{ id: Thing.last.id.to_s, type: 'things' }])
        content_type 'application/vnd.api+json'
        User.first.things.delete(Thing.last)
        expect { patch "/users/#{User.first.id}/relationships/things", body }.to change { User.first.things.count }.to(1)
        last_response_json['data'].each do |item|
          expect { User.first.things.find(item['id']) }.to_not raise_error
          identifier = JSONAPIonify::Structure::Objects::ResourceIdentifier.new(
            item.deep_symbolize_keys
          )
          expect { identifier.compile! }.to_not raise_error
        end
        expect(last_response.status).to eq 200
      end
    end

    describe 'DELETE /:resource/:id/relationships/:name' do
      it 'should add new relationships' do
        body = json(data: [{ id: User.first.things.first.id.to_s, type: 'things' }])
        content_type 'application/vnd.api+json'
        expect { delete "/users/#{User.first.id}/relationships/things", body }.to change { User.first.things.count }.by(-1)
        last_response_json['data'].each do |item|
          expect { User.first.things.find(item['id']) }.to_not raise_error
          identifier = JSONAPIonify::Structure::Objects::ResourceIdentifier.new(
            item.deep_symbolize_keys
          )
          expect { identifier.compile! }.to_not raise_error
        end
        expect(last_response.status).to eq 200
      end
    end
  end
end
