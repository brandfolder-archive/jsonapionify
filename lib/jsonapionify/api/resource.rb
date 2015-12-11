require 'active_support/rescuable'
require 'rack/response'
require 'active_support/json'

module JSONAPIonify::Api
  class Resource
    Dir.glob("#{__dir__}/resource/*.rb").each do |file|
      basename = File.basename file, File.extname(file)
      fullpath = File.expand_path file
      autoload basename.camelize.to_sym, fullpath
    end

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
