require 'spec_helper'
module JSONAPIonify::Api::Resource::Definitions
  describe Pagination do
    extend ApiHelper
    include JSONAPIonify::Api::TestHelper

    describe ".attribute" do
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

        attribute :name, types.String, ''
        attribute :color, types.String, ''
        attribute :weight, types.Integer, ''
        attribute :custom_value, types.String, '' do
          "CUSTOM VALUE"
        end

        list
      end

      context 'custom resolution' do
        it 'should return the resolved value' do
          get '/sample_resources'
          expect(last_response_json['data']).to be_present
          last_response_json['data'].each do |instance|
            expect(instance.fetch('attributes', {})['custom_value']).to eq 'CUSTOM VALUE'
          end
        end
      end
    end
  end
end
