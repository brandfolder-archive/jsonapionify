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
        instance.name = Faker::Commerce.product_name
        instance.color = Faker::Commerce.color
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
    end

    describe 'active record sorting' do
      active_record_api(:sample_resources).create_table do |t|
        t.string :name
        t.string :color
        t.integer :weight
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

        list
        enable_pagination per: 5
      end
    end
  end
end
