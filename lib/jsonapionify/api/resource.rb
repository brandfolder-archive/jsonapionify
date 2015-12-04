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

    extend ClassMethods
    include ActiveSupport::Rescuable
    include DefaultContexts
    include DefaultErrors
    include DefaultActions
    include DefaultHelpers

    def initialize(req)
      @context = Context.new(req, self.class.context_definitions)
      self.class.header_definitions.each do |name, block|
        headers[name.to_s] = block.call(context)
      end
    end

    def headers
      @headers ||= {}
    end

    def process(&block)
      instance_eval(&block) if block_given?
      return error_response if context.errors.present?
      response
    rescue error_exception
      error_response
    end

    def error(name, **options)
      error = self.class.error_definitions[name]
      raise ArgumentError, "Error does not exist: #{error}" unless error
      context.errors.evaluate(**options, &self.class.error_definitions[name])
    end

    def error_now(*args)
      error(*args)
      raise error_exception
    end

    private

    def error_exception
      @error_exception ||= Class.new(StandardError)
    end

    def error_response
      Rack::Response.new.tap do |response|
        error_collection = context.errors.collection
        status_codes     = error_collection.map { |error| error[:status] }.compact.uniq.sort
        response.status  =
          if status_codes.length == 1
            status_codes[0].to_i
          elsif status_codes.blank?
            500
          else
            (status_codes.last[0] + "00").to_i
          end
        headers.each { |k, v| response.headers[k] = v }
        response.write({ errors: error_collection }.to_json)
      end.finish
    end

  end
end