require 'delegate'
require 'active_support/core_ext/object/blank'

module JSONAPIonify::Api
  class Server
    extend JSONAPIonify::Autoload
    autoload_all

    attr_reader :api

    def initialize(api)
      @api = api
    end

    def call(env)
      puts 'req'
      Processor.new(env, api).response
    end

    class Processor
      attr_reader :request, :id, :more, :api

      def initialize(env, api)
        @api     = api
        @request = Request.new(env)
        request.path_info.split('/').tap(&:shift).tap do |parts|
          @resource, @id, @relationship, @relationship_name, *@more = parts
        end
      end

      def response
        request.env['jsonapionify.resource_name'] = @resource if @resource
        request.env['jsonapionify.resource']      = resource if @resource
        request.env['jsonapionify.id']            = @id if @id
        @resource ? resource.process(request) : api_index
      rescue Errors::ResourceNotFound
        resource = @resource
        api.http_error(:not_found, request) do
          detail "Resource not found: #{resource}"
        end
      end

      private

      def api_index
        api.process_index(request)
      end

      def resource
        api.resource(@resource)
      end
    end
  end
end
