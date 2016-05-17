require 'spec_helper'
module JSONAPIonify::Api::Resource::Definitions
  describe Contexts do
    extend ApiHelper
    include JSONAPIonify::Api::TestHelper
    MOCKA = OpenStruct.new foo: "hello"
    MOCKB = OpenStruct.new bar: "hello again"

    describe ".attribute" do
      username = Faker::Internet.user_name
      let(:username) { username }
      simple_object_api(:sample_resources).create_api do |model|
        scope { model }
        collection { |scope| scope.all }

        context :test_context do
          MOCKA.foo
        end

        context :test_context do |_, supercontext|
          supercontext.call
          MOCKB.bar
        end

        list do |context|
          context.test_context
        end
      end

      context 'redefinition' do
        it 'should call the supercontext' do
          expect(MOCKB).to receive :bar
          expect(MOCKA).to receive :foo
          get '/sample_resources'
        end
      end
    end
  end
end
