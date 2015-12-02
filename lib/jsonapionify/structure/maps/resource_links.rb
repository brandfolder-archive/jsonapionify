module JSONAPIonify::Structure
  module Maps
    class ResourceLinks < Links
      may_contain! :self
    end
  end
end
