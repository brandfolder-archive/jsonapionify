module JSONAPIonify::Api
  module Errors
    ResourceNotFound     = Class.new StandardError
    RelationshipNotFound = Class.new StandardError
    InputError           = Class.new StandardError
  end
end