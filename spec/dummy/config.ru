require_relative 'config/environment'

JSONAPIonify.disable_validation true

app = Rack::Builder.new do
  map "/v2" do
    run MyApi
  end
end

run app
