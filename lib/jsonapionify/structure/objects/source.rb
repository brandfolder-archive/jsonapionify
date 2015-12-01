module JSONAPIonify::Structure
  module Objects
    class Source < Base
      may_contain!(
        :pointer, # a JSON Pointer [[RFC6901](https://tools.ietf.org/html/rfc6901)] to the associated entity in the request document
        :parameter # a string indicating which URI query parameter caused the error.
      )
    end
  end
end
