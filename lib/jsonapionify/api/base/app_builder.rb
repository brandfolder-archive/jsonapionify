module JSONAPIonify::Api
  module Base::AppBuilder

    def call(env)
      app.call(env)
    end

    private

    def app
      api = self
      Rack::Builder.new do
        use Rack::ShowExceptions
        map "/docs" do
          run ->(env) {
            request    = JSONAPIonify::Api::Server::Request.new env
            if request.path_info.present?
              puts request.path
              return [301, { 'location' => request.path.chomp(request.path_info) }, []]
            end
            response   = Rack::Response.new
            doc_object = api.documentation_object(request)
            response.write JSONAPIonify::Documentation.new(doc_object).result
            response.finish
          }
        end
        map "/" do
          run JSONAPIonify::Api::Server.new(api)
        end
      end
    end
  end
end