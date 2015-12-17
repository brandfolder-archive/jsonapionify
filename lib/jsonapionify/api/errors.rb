module JSONAPIonify::Api
  module Errors
    ResourceNotFound     = Class.new StandardError
    RelationshipNotFound = Class.new StandardError
    RequestError         = Class.new StandardError
    CacheHit             = Class.new StandardError
  end
end
