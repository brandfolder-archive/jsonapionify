require 'spec_helper'

module JSONAPIonify
  describe Api::Base do
    include JSONAPIonify::Api::TestHelper

    set_api(MyApi)

    before do
      ActiveRecord::Base.descendants.each(&:delete_all)
      users = 5.times.map do
        User.new(
          first_name: Faker::Name.first_name,
          last_name:  Faker::Name.last_name,
          email:      Faker::Internet.email,
          password:   Faker::Internet.password
        )
      end
      User.import users
      things = User.all.each_with_object([]) do |user, ary|
        new_things = 3.times.map do
          user.things.new(
            name:  Faker::Commerce.product_name,
            color: Faker::Commerce.color,
          )
        end
        ary.concat new_things
      end
      Thing.import things
    end

    describe 'GET /docs' do
      it 'should not error' do
        get '/docs'
        expect(last_response).to be_ok
      end
    end

    describe 'GET /' do
      it 'should not error' do
        get '/'
        expect(last_response).to be_ok
      end

      it 'should list all the resources' do
        get '/'
        expect(last_response_json['meta']['resources'].keys).to eq app.resources.map { |r| r.type.to_s }
      end
    end

    describe 'GET /:resource' do
      it 'should return the list of resource instances' do
        get '/things'
        expect(last_response_json['data'].count).to eq Thing.count
        expect(last_response.status).to eq 200
      end
    end

    describe 'POST /:resource' do
      it 'should add a resource instance' do
        body = json(data: { type: 'things', attributes: { name: 'Card', color: 'blue' } })
        content_type 'application/vnd.api+json'
        expect { post '/things', body }.to change { Thing.count }.by 1
        expect(last_response.status).to eq 201
      end
    end

    describe 'GET /:resource/:id' do
      it 'should fetch a resource instance' do
        get "/things/#{Thing.first.id}"
        expect(last_response_json['data']['attributes']['name']).to eq(Thing.first.name)
        expect(last_response.status).to eq 200
      end
    end

    describe 'PATCH /:resource/:id' do
      it 'should change a resource instance' do
        body = json(data: { id: Thing.first.id.to_s, type: 'things', attributes: { name: 'New Name' } })
        content_type 'application/vnd.api+json'
        expect { patch "/things/#{Thing.first.id}", body }.to change { Thing.first.name }.to 'New Name'
        expect(last_response.status).to eq 200
      end
    end

    describe 'DELETE /:resource/:id' do
      it 'should delete a resource instance' do
        expect { delete "/things/#{Thing.first.id}" }.to change { Thing.count }.by -1
        expect(last_response.status).to eq 204
        expect(last_response.body).to be_blank
      end
    end

    describe '.relates_to_one' do
      describe 'GET /:resource/:id/:name' do
        it 'should fetch the related object' do
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

    describe '.relates_to_many' do
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
      end

      describe 'POST /:resource/:id/relationships/:name' do
        it 'should add new relationships' do
          body = json(data: [{ id: Thing.last.id.to_s, type: 'things' }])
          content_type 'application/vnd.api+json'
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

    describe 'Errors' do
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

    describe 'Parameters' do
      describe 'sort params' do
        it 'should not raise an error' do
          get "/things?sort=name"
          expect(last_response.status).to eq 200
        end
      end

      describe 'sparce field params' do
        it 'should not raise an error' do
          get "/things?fields[things]=name"
          expect(last_response.status).to eq 200
        end
      end

      describe 'include' do
        it 'should not raise an error' do
          get "/things?include=user"
          expect(last_response.status).to eq 200
        end
      end

      describe 'invalid parameter' do
        it 'should error' do
          get "/things?badparam=1"
          expect(last_response.status).to eq 400
        end
      end

      describe 'require parameters' do
        it 'should error when missing' do
          get "/places"
          expect(last_response.status).to eq 400
        end

        it 'should not error when not missing' do
          get "/places?the-foo=1"
          expect(last_response.status).to eq 200
        end
      end

      describe 'action based parameters' do
        context 'when on an action with the param' do
          it 'should error' do
            get "/places"
            expect(last_response.status).to eq 400
          end
        end

        context 'when on an action without the param' do
          it 'should not error' do
            get "/places/1"
            expect(last_response.status).to eq 200
          end
        end
      end

      describe 'require headers' do
        it 'should error when missing' do
          get "/parties"
          expect(last_response.status).to eq 400
        end

        it 'should not error when not missing' do
          header('required-header', '1')
          get "/parties"
          expect(last_response.status).to eq 200
        end
      end

      describe 'action based headers' do
        context 'when on an action with the header' do
          it 'should error' do
            get "/parties"
            expect(last_response.status).to eq 400
          end
        end

        context 'when on an action without the header' do
          it 'should not error' do
            get "/parties/1"
            expect(last_response.status).to eq 200
          end
        end
      end

    end
  end
end
