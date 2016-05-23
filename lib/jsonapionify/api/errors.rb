module JSONAPIonify::Api
  module Errors
    JSONAPIonifyError    = Class.new StandardError
    ResourceNotFound     = Class.new JSONAPIonifyError
    RelationshipNotFound = Class.new JSONAPIonifyError
    RequestError         = Class.new JSONAPIonifyError
    CacheHit             = Class.new JSONAPIonifyError
    DoubleCacheError     = Class.new JSONAPIonifyError
    DoubleRespondError   = Class.new JSONAPIonifyError
    InvalidCursor        = Class.new JSONAPIonifyError
    MissingContentType   = Class.new JSONAPIonifyError
    ReservedContextName  = Class.new JSONAPIonifyError
  end
end
