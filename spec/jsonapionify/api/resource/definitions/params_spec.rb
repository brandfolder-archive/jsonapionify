require 'spec_helper'
module JSONAPIonify::Api::Resource::Definitions
  describe Params do
    extend ApiHelper
    include JSONAPIonify::Api::TestHelper

    active_record_api(:things).create_table do |t|
      t.string :name
      t.string :color
    end.seed(count: 5) do |instance|
      instance.name = Faker::Commerce.product_name
      instance.color = Faker::Commerce.color
    end.create_api do |model|
      scope { model }
      collection { model.all }
      attribute :name, types.String, ''
      attribute :color, types.String, ''

      list
    end

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

    describe 'invalid parameter' do
      it 'should error' do
        get "/things?badparam=1"
        expect(last_response.status).to eq 400
      end
    end

    describe 'invalid deep parameter' do
      it 'should error' do
        get "/things?badparam[foo]=1"
        expect(last_response.status).to eq 400
      end
    end

    describe 'required parameters' do
      active_record_api(:places).create_table do |t|
        t.string :name
      end.seed(count: 5) do |instance|
        instance.name = Faker::Commerce.product_name
      end.create_api do |model|
        scope { model }
        collection { model.all }
        instance { |scope, id| scope.find id }
        attribute :name, types.String, ''

        param :'the-foo', required: true, actions: :list

        list
        read
      end

      it 'should error when missing' do
        get "/places"
        expect(last_response.status).to eq 400
      end

      it 'should not error when not missing' do
        get "/places?the-foo=1"
        expect(last_response.status).to eq 200
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
    end
  end
end
