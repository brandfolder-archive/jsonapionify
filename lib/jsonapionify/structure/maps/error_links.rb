module JSONAPIonify::Structure
  module Maps
    class ErrorLinks < Links
      may_contain! :about
    end
  end
end
