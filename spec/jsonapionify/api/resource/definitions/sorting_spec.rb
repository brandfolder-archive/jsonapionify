require 'spec_helper'
module JSONAPIonify::Api::Resource::Definitions
  describe Sorting do
    extend ApiHelper
    include JSONAPIonify::Api::TestHelper

    describe 'enumberable sorting' do
      using JSONAPIonify::DeepSortCollection

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

        attribute :name, types.String, ''
        attribute :color, types.String, ''
        attribute :weight, types.Integer, ''

        list
        enable_pagination per: 5
      end

      it 'should list results in order' do
        get '/sample_resources?sort=-color,weight,-name'
        actual_ids   = last_response_json['data'].map { |i| i['id'] }
        expected_ids = model.to_a.deep_sort(color: :desc, weight: :asc, name: :desc).first(5).map(&:id).map(&:to_s)
        expect(actual_ids).to be_present
        expect(actual_ids).to eq expected_ids
      end
    end

    describe 'active record sorting' do
      active_record_api(:sample_resources).create_table do |t|
        t.string :name
        t.string :color
        t.integer :weight
      end.seed(count: 20) do |instance|
        instance.name   = Faker::Commerce.product_name
        instance.color  = Faker::Commerce.color
        instance.weight = rand(0..100)
      end.create_api do |model|
        scope { model }
        collection { |scope| scope.all }

        attribute :name, types.String, ''
        attribute :color, types.String, ''
        attribute :weight, types.Integer, ''

        list
        enable_pagination per: 5
      end

      it 'should list results in order' do
        get '/sample_resources?sort=-color,weight,-name'
        actual_ids   = last_response_json['data'].map { |i| i['id'] }
        expected_ids = model.order(color: :desc, weight: :asc, name: :desc).first(5).map(&:id).map(&:to_s)
        expect(actual_ids).to be_present
        expect(actual_ids).to eq expected_ids
      end
    end
  end
end
