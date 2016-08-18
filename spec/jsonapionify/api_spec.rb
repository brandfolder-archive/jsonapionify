require 'spec_helper'
module JSONAPIonify
  describe Api do
    include JSONAPIonify::Api::TestHelper
    extend ApiHelper
    simple_object_api(:tests).create_api do
      list
    end

    # describe 'GET /' do
    #   it 'should not error' do
    #     get '/'
    #     expect(last_response).to be_ok
    #   end
    #
    #   it 'should list all the resources' do
    #     get '/'
    #     expect(last_response_json['meta']['resources'].keys).to eq app.resources.map { |r| r.type.to_s }
    #   end
    # end
  end
end
