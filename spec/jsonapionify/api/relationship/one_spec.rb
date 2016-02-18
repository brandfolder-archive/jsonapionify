require 'spec_helper'
module JSONAPIonify::Api
  describe Relationship::One do
    include JSONAPIonify::Api::TestHelper

    set_api(MyApi)

    describe 'GET /:resource/:id/:name' do
      it 'should fetch the related object' do
        Thing.first.update user: User.first
        get "/things/#{Thing.first.id}/user"
        expect(last_response_json['data']['attributes']['first_name']).to eq Thing.first.user.first_name
        expect(last_response.status).to eq 200
      end
    end

    describe 'GET /:resource/:id/relationships/:name' do
      it 'should fetch the related object ids' do
        get "/things/#{Thing.first.id}/user"
        expect(last_response_json['data']['type']).to eq 'users'
        expect(last_response_json['data']['id']).to eq Thing.first.user.id.to_s
        identifier = JSONAPIonify::Structure::Objects::ResourceIdentifier.new(
          last_response_json['data'].deep_symbolize_keys
        )
        expect { identifier.compile! }.to_not raise_error
        expect(last_response.status).to eq 200
      end
    end

    describe 'PATCH /:resource/:id/relationships/:name' do
      it 'should replace the relationship' do
        content_type 'application/vnd.api+json'
        body = json(data: { type: 'users', id: User.last.id.to_s })
        expect { patch "/things/#{Thing.first.id}/relationships/user", body }.to change { Thing.first.user }
        expect(last_response_json['data']['type']).to eq 'users'
        expect(last_response_json['data']['id']).to eq Thing.first.user.id.to_s
        identifier = JSONAPIonify::Structure::Objects::ResourceIdentifier.new(
          last_response_json['data'].deep_symbolize_keys
        )
        expect { identifier.compile! }.to_not raise_error
        expect(last_response.status).to eq 200
      end
    end
  end
end
