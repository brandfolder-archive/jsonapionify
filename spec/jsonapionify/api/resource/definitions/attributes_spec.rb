require 'spec_helper'
module JSONAPIonify::Api::Resource::Definitions
  describe Pagination do
    extend ApiHelper
    include JSONAPIonify::Api::TestHelper

    describe ".attribute" do
      username = Faker::Internet.user_name
      let(:username){ username }
      simple_object_api(:sample_resources).create_model do
        field :name
        field :color
        field :weight
      end.seed(count: 20) do |instance|
        instance.name = Faker::Commerce.product_name
        instance.color = Faker::Commerce.color
        instance.weight = rand(0..100)
      end.create_api do |model|
        scope { model }
        collection { |scope| scope.all }

        context :username do
          username
        end

        attribute :name, types.String, ''
        attribute :weight, types.Integer, ''
        attribute :color, types.String, '' do |attr, instance, context|
          "#{context.username} is #{instance.send(attr).upcase}"
        end

        list
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
