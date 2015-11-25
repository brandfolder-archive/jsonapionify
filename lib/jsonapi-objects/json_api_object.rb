module JSONAPIObjects
  class JSONAPIObject < BaseObject
    may_contain! :version
  end
end
