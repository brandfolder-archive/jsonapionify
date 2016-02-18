require 'spec_helper'
module JSONAPIonify::Api::Resource::Definitions
  describe RequestHeaders do
    include JSONAPIonify::Api::TestHelper
    extend ApiHelper

    active_record_api(:parties).create_table do |t|
      t.string :name
    end.seed(count: 5) do |instance|
      instance.name = Faker::Commerce.product_name + ' party'
    end.create_api do |model|
      scope { model }
      collection { model.all }
      instance { |scope, id| scope.find id }
      attribute :name, types.String, ''

      request_header 'required-header', required: true, actions: :list

      list
      read
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
