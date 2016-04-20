require 'spec_helper'
module JSONAPIonify::Api
  MockObject = Class.new OpenStruct

  describe Response do
    extend ApiHelper
    include JSONAPIonify::Api::TestHelper

    context 'default response' do
      simple_object_api(:sample_resources).create_model.create_api do |model|
        scope { model }
        collection { |scope| scope.all }
        list
      end

      context 'when accept is */*' do
        it 'should return the jsonapi response' do
          header 'accept', '*/*'
          get '/sample_resources'
          expect(last_response.status).to eq 200
          expect(last_response_json).to have_key 'data'
        end
      end

      context 'when accept is application/vnd.api+json' do
        it 'should return the jsonapi response' do
          header 'accept', 'application/vnd.api+json'
          get '/sample_resources'
          expect(last_response.status).to eq 200
          expect(last_response_json).to have_key 'data'
        end
      end

      context 'when accept is neither application/vnd.api+json or */*' do
        it 'should return a 406' do
          header 'accept', 'image/jpeg'
          get '/sample_resources'
          expect(last_response.status).to eq 406
          expect(last_response_json).to_not have_key 'data'
        end
      end

      context 'when extension is present' do
        it 'should return a 406' do
          get '/sample_resources.json'
          expect(last_response.status).to eq 406
          expect(last_response_json).to_not have_key 'data'
        end
      end
    end

    context 'custom default response' do
      simple_object_api(:sample_resources).create_model.create_api do |model|
        scope { model }
        collection { |scope| scope.all }
        list.response do
          MockObject.new.check
        end
      end

      context 'when accept is */*' do
        it 'should call the correct response' do
          header 'accept', '*/*'
          expect_any_instance_of(MockObject).to receive(:check)
          get '/sample_resources'
          expect(last_response.status).to eq 200
        end
      end

      context 'when accept is application/vnd.api+json' do
        it 'should call the correct response' do
          header 'accept', 'application/vnd.api+json'
          expect_any_instance_of(MockObject).to receive(:check)
          get '/sample_resources'
          expect(last_response.status).to eq 200
        end
      end

      context 'when accept is neither application/vnd.api+json or */*' do
        it 'should return a 406' do
          header 'accept', 'image/jpeg'
          expect_any_instance_of(MockObject).to_not receive(:check)
          get '/sample_resources'
          expect(last_response.status).to eq 406
        end
      end

      context 'when extension is present' do
        it 'should return a 406' do
          expect_any_instance_of(MockObject).to_not receive(:check)
          get '/sample_resources.json'
          expect(last_response.status).to eq 406
        end
      end
    end

    context 'matches accept header' do
      simple_object_api(:sample_resources).create_model.create_api do |model|
        scope { model }
        collection { |scope| scope.all }
        list.response(accept: 'application/json') do
          MockObject.new.check
        end
      end

      simple_object_api(:sample_resources).create_model.create_api do |model|
        scope { model }
        collection { |scope| scope.all }
        list.response accept: 'image/jpeg' do
          MockObject.new.check
        end
      end

      context 'when accept is */*' do
        it 'should return the jsonapi response' do
          header 'accept', '*/*'
          expect_any_instance_of(MockObject).to_not receive(:check)
          get '/sample_resources'
          expect(last_response.status).to eq 200
          expect(last_response_json).to have_key 'data'
        end
      end

      context 'when accept is image/jpeg' do
        it 'should call the correct response' do
          header 'accept', 'image/jpeg'
          expect_any_instance_of(MockObject).to receive(:check)
          get '/sample_resources'
          expect(last_response.status).to eq 200
        end
      end

      context 'when accept is application/vnd.api+json' do
        it 'should call the correct response' do
          header 'accept', 'application/vnd.api+json'
          expect_any_instance_of(MockObject).to_not receive(:check)
          get '/sample_resources'
          expect(last_response.status).to eq 200
        end
      end

      context 'when accept is neither image/jpeg or */*' do
        it 'should return a 406' do
          header 'accept', 'application/json'
          expect_any_instance_of(MockObject).to_not receive(:check)
          get '/sample_resources'
          expect(last_response.status).to eq 406
        end
      end

      context 'when extension is present' do
        it 'should return a 406' do
          expect_any_instance_of(MockObject).to_not receive(:check)
          get '/sample_resources.json'
          expect(last_response.status).to eq 406
        end
      end
    end

    context 'matches path/extension' do
      simple_object_api(:sample_resources).create_model.create_api do |model|
        scope { model }
        collection { |scope| scope.all }
        list.response(accept: 'application/json') do
          MockObject.new.check
        end
      end

      context 'with no extension' do
        it 'should the return jsonapi response' do
          expect_any_instance_of(MockObject).to_not receive(:check)
          get '/sample_resources'
          expect(last_response.status).to eq 200
          expect(last_response_json).to have_key 'data'
        end
      end

      context 'with a matching extension' do
        it 'should call the correct response' do
          expect_any_instance_of(MockObject).to receive(:check)
          get '/sample_resources.json'
          expect(last_response.status).to eq 200
        end
      end

      context 'with a non matching extension' do
        it 'should return a 406' do
          expect_any_instance_of(MockObject).to_not receive(:check)
          get '/sample_resources.jpg'
          expect(last_response.status).to eq 406
        end
      end
    end

    context 'matches matcher' do
      simple_object_api(:sample_resources).create_model.create_api do |model|
        scope { model }
        collection { |scope| scope.all }
        list.response(content_type: 'application/x-octet-stream', match: ->(context) { File.extname(context.request.path_info) == '.custom' }) do
          MockObject.new.check
        end
      end

      context "when the matcher passes" do
        it 'should call the correct response' do
          expect_any_instance_of(MockObject).to receive(:check)
          get '/sample_resources.custom'
          expect(last_response.status).to eq 200
        end
      end

      context "when the matcher does not match" do
        it 'should return a 406' do
          expect_any_instance_of(MockObject).to_not receive(:check)
          get '/sample_resources.js'
          expect(last_response.status).to eq 406
        end
      end
    end
  end
end
