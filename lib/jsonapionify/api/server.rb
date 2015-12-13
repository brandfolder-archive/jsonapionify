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
        if resource && more.blank?
          call_resource
        elsif resource.nil?
          call_api_index
        else
          Resource::Http.process(:not_found, request)
        end
      rescue Errors::ResourceNotFound
        Resource::Http.process(:not_found, request)
      end

      private

      def call_resource
        id ? call_resource_with_id : call_collection
      end

      def call_resource_with_id
        request.env['jsonapionify.id'] = id
        return call_relationship if @relationship
        if request.get?
          resource.process(:read, request)
        elsif request.put?
          resource.process(:update, request)
        elsif request.delete?
          resource.process(:delete, request)
        else
          Resource::Http.process(:method_not_allowed, request)
        end
      end

      def call_collection
        if request.get?
          resource.process(:index, request)
        elsif request.post?
          resource.process(:create, request)
        else
          Resource::Http.process(:method_not_allowed, request)
        end
      end

      def call_relationship
        if @relationship == 'relationships'
          call_resource_relationship
        else
          call_resource_related
        end
      end

      def call_resource_relationship
        return call_not_found unless relationship
        if request.get?
          relationship.process(:show_relationship, request)
        elsif request.patch?
          relationship.process(:replace_relationship, request)
        elsif request.put? && relationship.rel.is_a?(Relationship::Many)
          relationship.process(:update_relationship, request)
        elsif request.delete? && relationship.rel.is_a?(Relationship::Many)
          relationship.process(:remove_relationship, request)
        else
          Resource::Http.process(:method_not_allowed, request)
        end
      end

      def call_resource_related
        return call_not_found unless relationship
        if request.get? && relationship.rel.is_a?(Relationship::Many)
          relationship.process(:index, request)
        elsif request.get? && relationship.rel.is_a?(Relationship::One)
          relationship.process(:read, request)
        elsif request.post? && relationship.rel.is_a?(Relationship::Many)
          relationship.process(:create, request)
        else
          Resource::Http.process(:method_not_allowed, request)
        end
      end

      def call_api_index
        api.process_index(request)
      end

      def relationship
        if @relationship== 'relationships'
          resource.relationship(@relationship_name)
        else
          resource.relationship(@relationship)
        end
      end

      def resource
        @resource && api.resource(@resource)
      end
    end
  end
end
