require 'active_support/core_ext/array/wrap'

module JSONAPIonify::Api
  module Resource::ActionDefinitions
    include JSONAPIonify::EnumerableObserver

    UNSUPPORTED_MEDIA_TYPE = proc do
      error_now :unsupported_media_type
    end

    NOT_FOUND = proc do
      error_now :not_found
    end

    NOT_ACCEPTABLE = proc do
      error_now :not_acceptable
    end

    def self.extended(klass)
      klass.class_eval do
        extend JSONAPIonify::InheritedHashAttributes
        inherited_hash_attribute :action_definitions, :response_definitions
      end
    end

    def index(**options, &block)
      action(:index, **options, &block)
      response :index, status: 200 do
        json        = JSONAPIonify.new_object
        json[:data] = collection.map do |instance|
          Hash.new.tap do |obj|
            obj[:id] = instance.send(self.class.id_attribute).to_s
            obj[:type] = self.class.type
            obj[:attributes] = attributes.select(&:read?).each_with_object({}) do |member, attributes|
              attributes[member.name] = instance.public_send(member.name)
            end
          end
        end

        unless json.validate
          error_now(:output_error, set: json.errors.as_collection)
        end
        json.to_json
      end unless response_exists? :index
    end

    def create(**options, &block)
      action(:create, **options, &block)
      response :create, status: 201 do
        JSONAPIonify.new_object.tap do |json|
          json[:data] = attributes.select(&:read?).each_with_object({}) do |field, attributes|
            attributes[field] = instance.public_send(value)
          end
        end.to_json
      end unless response_exists? :create
    end

    def read(**options, &block)
      action(:read, includes: Actions::Read, **options, &block)
      response status: 200 do
        JSONAPIonify.new_object.tap do |json|
          json[:data] = attributes.select(&:read?).each_with_object({}) do |field, attributes|
            attributes[field] = instance.public_send(value)
          end
        end
      end unless response_exists? :index
    end

    def update(**options, &block)
      action(:update, includes: Actions::Update, **options, &block)
    end

    def delete(**options, &block)
      action(:delete, includes: Actions::Delete, **options, &block)
    end

    def process(action, request)
      action_proc   = get_action(action, content_type: request.content_type, has_body: request.has_body?)
      response_proc = get_response(action, accept: request.accept)

      if action_proc && response_proc
        new(request).process(action_proc, response_proc)
      elsif get_action(action)
        new(request).process(UNSUPPORTED_MEDIA_TYPE)
      elsif get_response(action)
        new(request).process(NOT_ACCEPTABLE)
      else
        new(request).process(NOT_FOUND)
      end
    end

    private

    def get_action(action, has_body: true, content_type: nil)
      content_type, media_type_parameters      = content_type && content_type.split(';')
      (*), (allow_media_type_parameters, proc) = action_definitions.find do |(a, type), *|
        a == action && (content_type == type || (content_type.nil? && !has_body))
      end
      if media_type_parameters && !allow_media_type_parameters
        UNSUPPORTED_MEDIA_TYPE
      else
        proc
      end
    end

    def action_exists(*args)
      !!get_action(*args)
    end

    def get_response(action, accept: '*/*')
      accept_type, media_type_parameters       = Array.wrap(accept).find do |accept_type|
        accept_type = accept_type.split(';')[0]
        response_definitions.keys.any? do |a, type|
          a == action && (accept_type == type || accept_type == '*/*')
        end
      end
      (*), (allow_media_type_parameters, proc) = response_definitions.find do |(a, type), *|
        a == action && (accept_type == type || accept_type == '*/*')
      end
      if media_type_parameters && !allow_media_type_parameters
        NOT_ACCEPTABLE
      else
        proc
      end
    end

    def response_exists?(*args)
      !!get_response(*args)
    end

    def action(name, includes: nil, content_type: 'application/vnd.api+json', allow_media_type_parameters: true, &block)
      allow_media_type_parameters =
        content_type == 'application/vnd.api+json' ? false : allow_media_type_parameters
      klass                       = Class.new(self)
      Array.wrap(includes).compact.each do |mod|
        klass.include mod
      end
      action_definitions[[name, content_type]] = [allow_media_type_parameters, block]
    end

    def response(action, status: 200, accept: 'application/vnd.api+json', allow_media_type_parameters: true, &block)
      allow_media_type_parameters            =
        accept == 'application/vnd.api+json' ? false : allow_media_type_parameters
      response_block                         = proc do
        Rack::Response.new.tap do |response|
          response.status = status
          headers.each { |k, v| response[k] = v }
          response['content-type'] = accept
          response.write instance_eval(&block)
        end.finish
      end
      response_definitions[[action, accept]] = [allow_media_type_parameters, response_block]
    end
  end

end