require 'spec_helper'
module JSONAPIonify::Api::Resource::Definitions
  describe Pagination do
    extend ApiHelper
    include JSONAPIonify::Api::TestHelper

    describe "sans pagination" do
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
      end

      it 'should not contain cursors' do
        get '/sample_resources'
        expect(last_response_json['data']).to be_present
        last_response_json['data'].each do |instance|
          expect(instance.fetch('meta', {})['cursor']).to be_nil
        end
      end
    end

    describe "enumerable pagination" do
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

      it 'should contain cursors' do
        get '/sample_resources'
        expect(last_response_json['data']).to be_present
        last_response_json['data'].each do |instance|
          expect(instance.fetch('meta', {})['cursor']).to_not be_nil
        end
      end

      ##### SPECS HERE
      describe "default" do
        before do
          get '/sample_resources'
        end
        it "should return a list of results" do
          expect(last_response_json['data']).to be_present
        end

        it "should not return the full list of results" do
          expect(last_response_json['data'].length).to_not eq model.count
        end

        it "should start with the first result" do
          expect(last_response_json['data'].first['id']).to eq model.to_a.deep_sort(id: :asc).first.id.to_s
        end
      end

      describe "first page" do
        before do
          get '/sample_resources'
          get last_response_json['links']['first']
        end

        it "should return a list of results" do
          expect(last_response_json['data']).to be_present
        end

        it "should not return the full list of results" do
          expect(last_response_json['data'].length).to_not eq model.count
        end

        it "should start with the first result" do
          expect(last_response_json['data'].first['id']).to eq model.to_a.deep_sort(id: :asc).first.id.to_s
        end
      end

      describe "last page" do
        before do
          get '/sample_resources'
          get last_response_json['links']['last']
        end

        it "should return a list of results" do
          expect(last_response_json['data']).to be_present
        end

        it "should not return the full list of results" do
          expect(last_response_json['data'].length).to_not eq model.count
        end

        it "should end with the last result" do
          expect(last_response_json['data'].last['id']).to eq model.to_a.deep_sort(id: :asc).last.id.to_s
        end
      end

      describe "next page" do
        before do
          get '/sample_resources'
          @first_response_json = last_response_json
          get last_response_json['links']['next']
        end

        it "should return a list of results" do
          expect(last_response_json['data']).to be_present
        end

        it "should not return the full list of results" do
          expect(last_response_json['data'].length).to_not eq model.count
        end

        it "should not start with the first result" do
          expect(last_response_json['data'].first['id']).to_not eq model.to_a.deep_sort(id: :asc).last.id.to_s
        end

        it "should properly navigate to the previous page" do
          get last_response_json['links']['prev']
          expect(last_response_json['data']).to eq @first_response_json['data']
        end
      end

      describe "previous page" do
        before do
          get '/sample_resources'
          get last_response_json['links']['next']
          get last_response_json['links']['next']
          @first_response_json = last_response_json
          get last_response_json['links']['prev']
        end

        it "should return a list of results" do
          expect(last_response_json['data']).to be_present
        end

        it "should not return the full list of results" do
          expect(last_response_json['data'].length).to_not eq model.count
        end

        it "should not start with the first result" do
          expect(last_response_json['data'].first['id']).to_not eq model.to_a.deep_sort(id: :asc).first.id.to_s
        end

        it "should properly navigate to the next page" do
          get last_response_json['links']['next']
          expect(last_response_json['data']).to eq @first_response_json['data']
        end
      end

      describe "random after cursor" do
        before do
          get '/sample_resources'
          @cursor = last_response_json['data'][3]['meta']['cursor']
          get "/sample_resources?page[after]=#{@cursor}"
        end
        it 'should properly navigate to after the cursor' do
          get last_response_json['links']['prev']
          expect(last_response_json['data'].last['meta']['cursor']).to eq @cursor
        end
      end

      describe "random before cursor" do
        before do
          get '/sample_resources'
          @cursor = last_response_json['data'][3]['meta']['cursor']
          get "/sample_resources?page[before]=#{@cursor}"
        end
        it 'should properly navigate to before the cursor' do
          get last_response_json['links']['next']
          expect(last_response_json['data'].first['meta']['cursor']).to eq @cursor
        end
      end


      describe "given a first param" do
        before do
          get '/sample_resources?page[first]=5'
        end

        it "should return a number of results equal to the first param" do
          expect(last_response_json['data'].length).to eq 5
        end

        it "should return the first x results" do
          expect(last_response_json['data'].map { |i| i['id'] }).to eq model.to_a.deep_sort(id: :asc).first(5).map(&:id).map(&:to_s)
        end
      end

      describe "given a last param" do
        before do
          get '/sample_resources?page[last]=5'
        end

        it "should return a number of results equal to the last param" do
          expect(last_response_json['data'].length).to eq 5
        end

        it "should return the last x results" do
          expect(last_response_json['data'].map { |i| i['id'] }).to eq model.to_a.deep_sort(id: :asc).last(5).map(&:id).map(&:to_s)
        end
      end
    end

    describe "active record pagination" do
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

      ##### SPECS HERE
      describe "default" do
        before do
          get '/sample_resources'
        end
        it "should return a list of results" do
          expect(last_response_json['data']).to be_present
        end

        it "should not return the full list of results" do
          expect(last_response_json['data'].length).to_not eq model.count
        end

        it "should start with the first result" do
          expect(last_response_json['data'].first['id']).to eq model.first.id.to_s
        end
      end

      describe "first page" do
        before do
          get '/sample_resources'
          get last_response_json['links']['first']
        end

        it "should return a list of results" do
          expect(last_response_json['data']).to be_present
        end

        it "should not return the full list of results" do
          expect(last_response_json['data'].length).to_not eq model.count
        end

        it "should start with the first result" do
          expect(last_response_json['data'].first['id']).to eq model.first.id.to_s
        end
      end

      describe "last page" do
        before do
          get '/sample_resources'
          get last_response_json['links']['last']
        end

        it "should return a list of results" do
          expect(last_response_json['data']).to be_present
        end

        it "should not return the full list of results" do
          expect(last_response_json['data'].length).to_not eq model.count
        end

        it "should end with the last result" do
          expect(last_response_json['data'].last['id']).to eq model.last.id.to_s
        end
      end

      describe "next page" do
        before do
          get '/sample_resources'
          @first_response_json = last_response_json
          get last_response_json['links']['next']
        end

        it "should return a list of results" do
          expect(last_response_json['data']).to be_present
        end

        it "should not return the full list of results" do
          expect(last_response_json['data'].length).to_not eq model.count
        end

        it "should not start with the first result" do
          expect(last_response_json['data'].first['id']).to_not eq model.last.id.to_s
        end

        it "should properly navigate to the previous page" do
          get last_response_json['links']['prev']
          expect(last_response_json['data']).to eq @first_response_json['data']
        end
      end

      describe "previous page" do
        before do
          get '/sample_resources'
          get last_response_json['links']['next']
          @first_response_json = last_response_json
          get last_response_json['links']['prev']
        end

        it "should return a list of results" do
          expect(last_response_json['data']).to be_present
        end

        it "should not return the full list of results" do
          expect(last_response_json['data'].length).to_not eq model.count
        end

        it "should not start with the first result" do
          expect(last_response_json['data'].first['id']).to_not eq model.last.id.to_s
        end

        it "should properly navigate to the next page" do
          get last_response_json['links']['next']
          expect(last_response_json['data']).to eq @first_response_json['data']
        end
      end

      describe "random after cursor" do
        before do
          get '/sample_resources'
          @cursor = last_response_json['data'][3]['meta']['cursor']
          get "/sample_resources?page[after]=#{@cursor}"
        end
        it 'should properly navigate to after the cursor' do
          get last_response_json['links']['prev']
          expect(last_response_json['data'].last['meta']['cursor']).to eq @cursor
        end
      end

      describe "random before cursor" do
        before do
          get '/sample_resources'
          @cursor = last_response_json['data'][3]['meta']['cursor']
          get "/sample_resources?page[before]=#{@cursor}"
        end
        it 'should properly navigate to before the cursor' do
          get last_response_json['links']['next']
          expect(last_response_json['data'].first['meta']['cursor']).to eq @cursor
        end
      end


      describe "given a first param" do
        before do
          get '/sample_resources?page[first]=5'
        end

        it "should return a number of results equal to the first param" do
          expect(last_response_json['data'].length).to eq 5
        end

        it "should return the first x results" do
          expect(last_response_json['data'].map { |i| i['id'] }).to eq model.first(5).map(&:id).map(&:to_s)
        end
      end

      describe "given a last param" do
        before do
          get '/sample_resources?page[last]=5'
        end

        it "should return a number of results equal to the last param" do
          expect(last_response_json['data'].length).to eq 5
        end

        it "should return the last x results" do
          expect(last_response_json['data'].map { |i| i['id'] }).to eq model.last(5).map(&:id).map(&:to_s)
        end
      end

    end
  end
end
