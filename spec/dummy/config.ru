require_relative 'config/environment'

app = Rack::Builder.new do
  map "/v2" do
    run MyApi
  end
end

run app
