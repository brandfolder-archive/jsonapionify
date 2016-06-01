require 'spec_helper'
module JSONAPIonify::Api::Resource::Definitions
  describe Attributes do
    extend ApiHelper
    include JSONAPIonify::Api::TestHelper

    describe ".attribute" do
      username = Faker::Internet.user_name
      let(:username) { username }
      simple_object_api(:sample_resources).create_model do
        field :name
        field :color
        field :weight
      end.seed(count: 20) do |instance|
        instance.name   = Faker::Commerce.product_name
        instance.color  = Faker::Commerce.color
        instance.weight = rand(0..100)
      end.create_api do |model|
        scope { model }
        collection { |scope| scope.all }
        instance { |scope, id| scope.find id }

        context :username do
          username
        end

        noop = proc { '' }
        attribute :name, types.String, ''
        attribute :hidden, types.String, '', hidden: true, &noop
        attribute :hidden_list, types.String, '', hidden: :list, &noop
        attribute :hidden_many, types.String, '', hidden: [:list, :update], &noop
        attribute :weight, types.Integer, ''
        attribute :color, types.String, '' do |attr, instance, context|
          "#{context.username} is #{instance.send(attr).upcase}"
        end

        update
        list
      end

      context 'hidden attribute' do
        context 'all actions' do
          it 'should have the proper keys' do
            get "/sample_resources/#{model.first.id}"
            expect(last_response_json['data']['attributes']).to_not have_key 'hidden'
          end
        end

        context 'one action' do
          it 'should have the proper keys' do
            get "/sample_resources"
            expect(last_response_json['data'][0]['attributes']).to_not have_key 'hidden_list'
            get "/sample_resources/#{model.first.id}"
            expect(last_response_json['data']['attributes']).to have_key 'hidden_list'
          end
        end

        context 'multiple actions' do
          it 'should have the proper keys' do
            content_type 'application/vnd.api+json'
            patch "/sample_resources/#{model.first.id}", json(data: { type: 'sample_resources', id: model.first.id, attributes: {} })
            expect(last_response_json['data']['attributes']).to_not have_key 'hidden_many'
            get "/sample_resources"
            expect(last_response_json['data'][0]['attributes']).to_not have_key 'hidden_many'
            get "/sample_resources/#{model.first.id}"
            expect(last_response_json['data']['attributes']).to have_key 'hidden_many'
          end
        end

        context 'field specified' do
          it 'should have the proper keys' do
            get "/sample_resources?fields[sample_resources]=hidden"
            expect(last_response_json['data'][0]['attributes']).to have_key 'hidden'
          end
        end
      end

      context 'custom resolution' do
        it 'should return the resolved value' do
          get '/sample_resources'
          expect(last_response_json['data']).to be_present
          last_response_json['data'].each do |instance|
            color = model.find(instance['id']).color.upcase
            expect(instance.fetch('attributes', {})['color']).to eq "#{username} is #{color}"
          end
        end
      end
    end
  end
end
