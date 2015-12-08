require 'rack/request'
require 'delegate'
require 'active_support/core_ext/object/blank'

module JSONAPIonify::Api
  class Server

    class Request < Rack::Request
      def headers
        Rack::Utils::HeaderHash.new(
          env.select do |name, _|
            name.start_with? 'HTTP'
          end.each_with_object({}) do |(name, value), hash|
            hash[name[5..-1]] = value
          end
        )
      end

      def accept
        accepts = headers['accept'] && headers['accept'].split(',')
        accepts.to_a.sort_by! do |accept|
          _, *media_type_params = accept.split(';')
          rqf                   = media_type_params.find { |mtp| mtp.start_with? 'q=' }
          -(rqf ? rqf[2..-1].to_f : 1.0)
        end.map do |accept|
          mime, *media_type_params = accept.split(';')
          media_type_params.reject! { |mtp| mtp.start_with? 'q=' }
          [mime, *media_type_params].join(';')
        end
      end

      def has_body?
        body.read(1).present?
      end
    end

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
          call_method_not_allowed
        end
      end

      def call_collection
        if request.get?
          resource.process(:index, request)
        elsif request.post?
          resource.process(:create, request)
        else
          call_method_not_allowed
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
          relationship.process(:related_ids, request)
        elsif request.patch? && relationship < Resource::RelationshipToOne
          relationship.process(:update_association, request)
        elsif request.patch? && relationship < Resource::RelationshipToMany
          relationship.process(:update_all_associations, request)
        elsif request.put? && relationship < Resource::RelationshipToMany
          relationship.process(:associate_many, request)
        elsif request.delete? && relationship < Resource::RelationshipToMany
          relationship.process(:disassociate, request)
        else
          call_method_not_allowed
        end
      end

      def call_resource_related
        return call_not_found unless relationship
        if request.get?
          relationship.process(:related, request)
        elsif request.post? && relationship < Resource::RelationshipToMany
          relationship.process(:create, request)
        elsif request.delete? && relationship < Resource::RelationshipToMany
          relationship.process(:delete, request)
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

      def relationship
        if @relationship== 'relationships'
          resource.relationship(@relationship_name)
        else
          resource.relationship(@relationship)
        end
      end

      def resource
        api.resource(@resource)
      end
    end
  end
end