module JSONAPIonify::Api
  class Base::Reloader < Struct.new :app

    def call(env)
      Base.descendants.map(&:load_resources)
      app.call(env)
    end

  end
end
