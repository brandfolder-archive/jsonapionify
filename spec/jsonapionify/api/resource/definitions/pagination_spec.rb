require 'spec_helper'
module JSONAPIonify::Api::Resource::Definitions
  describe Pagination do
    include JSONAPIonify::Api::TestHelper

    let(:resource_scope) {
      nil
    }

    # Create Dummy App with Dummy Resource
    let(:app) {
      spec = self
      Class.new(JSONAPIonify::Api::Base).tap do |api|
        api.define_resource :sample_resources do
          scope { spec.resource_scope }
          collection { |scope| scope.is_a?(Array) ? scope.to_a : scope.all }
          list
          enable_pagination
        end
      end
    }

    describe "enumerable pagination" do
      # Create a dummy Array Collection
      let (:resource_scope) do
        100.times.map do |i|
          OpenStruct.new(
            id:     i + 1,
            name:   Faker::Commerce.product_name,
            color:  Faker::Commerce.color,
            weight: rand(0..100)
          )
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
          expect(last_response_json['data'].length).to_not eq resource_scope.count
        end

        it "should start with the first result" do
          expect(last_response_json['data'].first['id']).to eq resource_scope.first.id.to_s
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
          expect(last_response_json['data'].length).to_not eq resource_scope.count
        end

        it "should start with the first result" do
          expect(last_response_json['data'].first['id']).to eq resource_scope.first.id.to_s
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
          expect(last_response_json['data'].length).to_not eq resource_scope.count
        end

        it "should end with the last result" do
          expect(last_response_json['data'].last['id']).to eq resource_scope.last.id.to_s
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
          expect(last_response_json['data'].length).to_not eq resource_scope.count
        end

        it "should not start with the first result" do
          expect(last_response_json['data'].first['id']).to_not eq resource_scope.last.id.to_s
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
          expect(last_response_json['data'].length).to_not eq resource_scope.count
        end

        it "should not start with the first result" do
          expect(last_response_json['data'].first['id']).to_not eq resource_scope.last.id.to_s
        end

        it "should properly navigate to the next page" do
          get last_response_json['links']['next']
          expect(last_response_json['data']).to eq @first_response_json['data']
        end
      end

      describe "random after cursor" do
        before do
          get '/sample_resources'
          @cursor = last_response_json['data'][11]['meta']['cursor']
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
          @cursor = last_response_json['data'][11]['meta']['cursor']
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
          expect(last_response_json['data'].map { |i| i['id'] }).to eq resource_scope.first(5).map(&:id).map(&:to_s)
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
          expect(last_response_json['data'].map { |i| i['id'] }).to eq resource_scope.last(5).map(&:id).map(&:to_s)
        end
      end
    end

    describe "active record pagination" do
      # Set the table name
      let(:table_name) { 'sample_resources' }

      # Create a Dummy Resource Class
      let(:resource_scope) do
        spec = self
        Class.new(ActiveRecord::Base) do
          self.table_name = spec.table_name
        end
      end

      # Migrate inline
      before do
        spec = self
        Class.new(ActiveRecord::Migration) do
          suppress_messages do
            drop_table spec.table_name rescue nil
            create_table spec.table_name do |t|
              t.string :name
              t.string :color
              t.integer :weight
            end

            100.times do
              spec.resource_scope.create(
                name:   Faker::Commerce.product_name,
                color:  Faker::Commerce.color,
                weight: rand(0..100)
              )
            end
          end
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
          expect(last_response_json['data'].length).to_not eq resource_scope.count
        end

        it "should start with the first result" do
          expect(last_response_json['data'].first['id']).to eq resource_scope.first.id.to_s
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
          expect(last_response_json['data'].length).to_not eq resource_scope.count
        end

        it "should start with the first result" do
          expect(last_response_json['data'].first['id']).to eq resource_scope.first.id.to_s
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
          expect(last_response_json['data'].length).to_not eq resource_scope.count
        end

        it "should end with the last result" do
          expect(last_response_json['data'].last['id']).to eq resource_scope.last.id.to_s
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
          expect(last_response_json['data'].length).to_not eq resource_scope.count
        end

        it "should not start with the first result" do
          expect(last_response_json['data'].first['id']).to_not eq resource_scope.last.id.to_s
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
          expect(last_response_json['data'].length).to_not eq resource_scope.count
        end

        it "should not start with the first result" do
          expect(last_response_json['data'].first['id']).to_not eq resource_scope.last.id.to_s
        end

        it "should properly navigate to the next page" do
          get last_response_json['links']['next']
          expect(last_response_json['data']).to eq @first_response_json['data']
        end
      end

      describe "random after cursor" do
        before do
          get '/sample_resources'
          @cursor = last_response_json['data'][11]['meta']['cursor']
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
          @cursor = last_response_json['data'][11]['meta']['cursor']
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
          expect(last_response_json['data'].map { |i| i['id'] }).to eq resource_scope.first(5).map(&:id).map(&:to_s)
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
          expect(last_response_json['data'].map { |i| i['id'] }).to eq resource_scope.last(5).map(&:id).map(&:to_s)
        end
      end

    end
  end
end
