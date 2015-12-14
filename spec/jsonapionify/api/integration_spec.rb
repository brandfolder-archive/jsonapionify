require 'spec_helper'

module JSONAPIonify
  describe Api::Base do
    include JSONAPIonify::Api::TestHelper

    set_api(MyApi)

    before do
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

    describe 'GET /:resource' do
      it 'should return the list of resource instances' do
        get '/things'
        expect(last_response_json['data'].count).to eq Thing.count
      end
    end

    describe 'POST /:resource' do
      it 'should add a resource instance' do
        body = json(data: { type: 'things', attributes: { name: 'Card', color: 'blue' } })
        header 'content-type', 'application/vnd.api+json'
        expect { post '/things', body }.to change { Thing.count }.by 1
      end
    end

    describe 'GET /:resource/:id' do
      it 'should fetch a resource instance' do
        get "/things/#{Thing.first.id}"
        expect(last_response_json['data']['attributes']['name']).to eq(Thing.first.name)
      end
    end

    describe 'PATCH /:resource/:id' do
      it 'should change a resource instance' do
        body = json(data: { id: Thing.first.id.to_s, type: 'things', attributes: { name: 'New Name' } })
        header 'content-type', 'application/vnd.api+json'
        expect { patch "/things/#{Thing.first.id}", body }.to change { Thing.first.name }.to 'New Name'
      end
    end

    describe 'DELETE /:resource/:id' do
      it 'should delete a resource instance' do
        expect { delete "/things/#{Thing.first.id}" }.to change { Thing.count }.by -1
      end
    end

    describe '.relates_to_one' do
      describe 'GET /:resource/:id/:name' do
        it 'should fetch the related object' do
          get "/things/#{Thing.first.id}/user"
          expect(last_response_json['data']['attributes']['first_name']).to eq Thing.first.user.first_name
        end
      end

      describe 'GET /:resource/:id/relationships/:name' do

      end

      describe 'PATCH /:resource/:id/relationships/:name' do

      end
    end

    describe '.relates_to_many' do
      describe 'GET /:resource/:id/:name' do
      end

      describe 'POST /:resource/:id/:name' do
      end

      describe 'GET /:resource/:id/relationships/:name' do

      end

      describe 'POST /:resource/:id/relationships/:name' do

      end

      describe 'PATCH /:resource/:id/relationships/:name' do

      end
    end

  end
end
