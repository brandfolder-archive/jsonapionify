require 'rack/request'
require 'delegate'
require 'active_support/core_ext/object/blank'

module JSONAPIonify::Api
  class Server

    attr_reader :api

    def initialize(api)
      @api = api
    end

    def call(env)
      Processor.new(env, api).response
    end

    class Processor
      attr_reader :request, :resource, :id, :relationship, :relationship_name, :more, :api

      def initialize(env, api)
        @api = api
        @request = Rack::Request.new(env)
        request.path.split('/').tap(&:shift).tap do |parts|
          @resource, @id, @relationship, @relationship_name, *@more = parts
        end
      end

      def response
        resource && more.blank? ? call_resource : call_not_found
      end

      private

      def call_resource
        id ? call_resource_with_id : call_collection
      end

      def call_collection
        if request.get?
          api.resource(resource).process_index(request)
        elsif request.post?
          api.resource(resource).process_create(request)
        else
          call_method_not_allowed
        end
      end

      def call_resource_with_id
        request.env['jsonapionify.id'] = id
        return call_relationship if relationship
        if request.get?
          api.resource(resource).process_read(request)
        elsif request.put?
          api.resource(resource).process_update(request)
        elsif request.delete?
          api.resource(resource).process_delete(request)
        else
          call_method_not_allowed
        end
      end

      def call_relationship
        if relationship == 'relationships'
          call_resource_relationship
        else
          call_resource_related
        end
      end

      def call_resource_relationship
        return not_found unless relationship_name
        relationship = api.resource(resource).relationship(relationship_name)
        if request.get?
          relationship.process_related_ids(request)
        elsif request.put?
          relationship.process_associate(request)
        elsif request.delete?
          relationship.process_deassociate(request)
        else
          call_method_not_allowed
        end
      end

      def call_resource_related
        if request.get?
          api.resource(resource).relationship(relationship_name).process_related(request)
        elsif request.post?
          api.resource(resource).relationship(relationship_name).process_create_and_associate(request)
        elsif request.delete?
          api.resource(resource).relationship(relationship_name).process_deassociate(request)
        else
          call_method_not_allowed
        end
      end

      def call_not_found
        api.resource_class.process_not_found(request)
      end

      def call_method_not_allowed
        api.resource_class.process_method_not_allowed(request)
      end
    end

  end
end