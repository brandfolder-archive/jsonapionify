module JSONAPIonify::Structure
  module Objects
    class Jsonapi < Base
      may_contain! :version
    end
  end
end
