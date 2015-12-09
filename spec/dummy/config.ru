require 'bundler/setup'
Bundler.require(:default)
require './app/apis/my_api'

ActiveRecord::Base.logger = Logger.new STDOUT

app = Rack::Builder.new do
  map "/v2" do
    run MyApi
  end
end

run app
