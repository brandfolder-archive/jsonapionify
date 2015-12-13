require 'active_support/rescuable'
require 'rack/response'
require 'active_support/json'

module JSONAPIonify::Api
  class Resource
    extend JSONAPIonify::Autoload
    autoload_all

    extend ActionDefinitions
    extend AttributeDefinitions
    extend ScopeDefinitions
    extend HelperDefinitions
    extend RelationshipDefinitions
    extend PaginationDefinitions
    extend ClassMethods

    include ErrorHandling
    include DefaultContexts
    include DefaultErrors
    include DefaultHelpers
    include DefaultActions
    include Builders

  end
end
