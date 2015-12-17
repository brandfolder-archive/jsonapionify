module JSONAPIonify::Api
  class HeaderOptions

    attr_reader :name, :actions, :required, :documented

    def initialize(name, actions: nil, required: false, documented: true)
      @name       = name
      @actions    = Array.wrap(actions)
      @required   = required
      @documented = documented
    end

  end
end
