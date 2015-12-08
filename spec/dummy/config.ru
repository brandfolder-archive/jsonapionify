require 'bundler/setup'
Bundler.require(:default)
require './app/apis/my_api'

app = Rack::Builder.new do
  use Rack::CommonLogger
  use Rack::ShowExceptions
  map "/docs" do
    use Rack::Lint
    run MyApi.doc_server
  end
  map "/" do
    use Rack::Lint
    run MyApi.api_server
  end
end

run app
