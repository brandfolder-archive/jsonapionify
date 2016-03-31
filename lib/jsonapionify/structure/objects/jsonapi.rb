module JSONAPIonify::Structure
  module Objects
    class Jsonapi < Base
      define_order *%i{version meta}
      may_contain! :version, :meta
    end
  end
end
