module JSONAPIonify::Api
  module Base::AppBuilder

    def middleware
      @middleware ||= MiddlewareStack.new
    end

    def inherited(subclass)
      super(subclass)
      subclass.instance_exec(self) do |superclass|
        @middleware = superclass.middleware.dup
      end
    end

    def use(*args)
      middleware.use(*args)
    end

    def call(env)
      app.call(env)
    end

    private

    def app
      api = self
      Rack::Builder.new do
        use Rack::ShowExceptions
        use Rack::CommonLogger
        use Base::Reloader unless ENV['RACK_ENV'] == 'production'
        map "/docs" do
          run ->(env) {
            request = JSONAPIonify::Api::Server::Request.new env
            if request.path_info.present?
              return [301, { 'location' => request.path.chomp(request.path_info) }, []]
            end
            response = Rack::Response.new
            response.write api.documentation_output(request)
            response.finish
          }
        end
        map "/" do
          api.middleware.install(binding)
          run JSONAPIonify::Api::Server.new(api)
        end
      end
    end
  end
end
