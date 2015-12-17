module JSONAPIonify::Api
  class HeaderOptions

    attr_reader :name, :actions, :required

    def initialize(name, actions: nil, required: false)
      @name     = name
      @actions  = Array.wrap(actions)
      @required = required
    end

  end
end
