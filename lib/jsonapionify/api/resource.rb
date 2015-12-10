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

    delegate :cache, to: JSONAPIonify

    extend ClassMethods
    extend ActionDefinitions
    extend AttributeDefinitions
    extend ScopeDefinitions
    extend HelperDefinitions
    extend RelationshipDefinitions
    extend PaginationDefinitions

    include ErrorHandling
    include DefaultContexts
    include DefaultErrors
    include DefaultHelpers
    include DefaultActions
    include Builders

    def initialize(req)
      @context = Context.new(req, self.class.context_definitions)
      self.class.header_definitions.each do |name, block|
        headers[name.to_s] = block.call(context)
      end
    end

    def headers
      @headers ||= {}
    end

  end
end
