require 'spec_helper'
module JSONAPIonify::Api::Resource::Definitions
  describe Relationships do
    extend ApiHelper
    include JSONAPIonify::Api::TestHelper

    describe ".attribute" do
      username = Faker::Internet.user_name
      let(:username) { username }
      simple_object_api(:sample_resources).create_model.seed(count: 1).create_api do |model|
        scope { model }
        collection { |scope| scope.all }
        instance { |scope, id| scope.find id }

        noop = proc { OpenStruct.new }
        relates_to_one :shown, resource: :sample_resources, hidden: false, &noop
        relates_to_one :hidden, resource: :sample_resources, hidden: true, &noop
        relates_to_one :hidden_list, resource: :sample_resources, hidden: :list, &noop
        relates_to_one :hidden_many, resource: :sample_resources, hidden: [:list, :update], &noop

        update
        list
      end

      context 'hidden relationships' do
        context 'all actions' do
          it 'should have the proper keys' do
            get "/sample_resources/#{model.first.id}"
            expect(last_response_json['data']['relationships']).to_not have_key 'hidden'
          end
        end

        context 'one action' do
          it 'should have the proper keys' do
            get "/sample_resources"
            expect(last_response_json['data'][0]['relationships']).to_not have_key 'hidden_list'
            get "/sample_resources/#{model.first.id}"
            expect(last_response_json['data']['relationships']).to have_key 'hidden_list'
          end
        end

        context 'multiple actions' do
          it 'should have the proper keys' do
            content_type 'application/vnd.api+json'
            patch "/sample_resources/#{model.first.id}", json(data: { type: 'sample_resources', id: model.first.id, attributes: {} })
            expect(last_response_json['data']['relationships']).to_not have_key 'hidden_many'
            get "/sample_resources"
            expect(last_response_json['data'][0]['relationships']).to_not have_key 'hidden_many'
            get "/sample_resources/#{model.first.id}"
            expect(last_response_json['data']['relationships']).to have_key 'hidden_many'
          end
        end

        context 'field specified' do
          it 'should have the proper keys' do
            get "/sample_resources?fields[sample_resources]=hidden"
            expect(last_response_json['data'][0]['relationships']).to have_key 'hidden'
          end
        end
      end
    end
  end
end
