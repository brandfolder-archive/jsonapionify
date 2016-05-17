require 'concurrent'

module JSONAPIonify::Api
  module Resource::Includer
    extend ActiveSupport::Concern

    included do
      before :list, :create, :read, :update do |context|
        supports_includes = context.root_request? && context.includes.present?
        is_active_record  = defined?(ActiveRecord) && context.scope.respond_to?(:<) && context.scope < ActiveRecord::Base
        if supports_includes && is_active_record
          valid_includes = context.includes.select do |k, v|
            context.scope._reflect_on_association(k)
          end.to_h
          context.scope  = context.scope.includes valid_includes
        end
      end

      after :commit_list do |context|
        if context.includes.present?
          included =
            Concurrent::Array.new(context.response_collection).map do |instance|
              fetch_included(context, owner: instance)
            end.reduce(:+)
          append_included(context, included)
        end
      end

      after :commit_create, :commit_read, :commit_update do |context|
        if context.includes.present?
          included = fetch_included(
            context, owner: context.instance
          )
          append_included(context, included)
        end
      end

      context :root_request?, readonly: true do
        true
      end

      context :includes do |context|
        Resource::Includer.includes_to_hashes context.params['include']
      end
    end

    def append_included(context, included)
      if included.present?
        context.response_object[:included] = included
        context.response_object[:included].tap(&:uniq!).reject! do |r|
          Array.wrap(context.response_object[:included]).include?(r) ||
            Array.wrap(context.response_object[:data]).include?(r)
        end
      end
    end

    def fetch_included(context, **overrides)
      collection = JSONAPIonify::Structure::Collections::IncludedResources.new
      context.includes.each_with_object(collection) do |(name, _),|
        res = self.class.relationship(name)
        if res.rel.includable?
          overrides = overrides.merge includes:      context.includes[name],
                                      errors:        context.errors,
                                      root_request?: false
          *, body   =
            case res.rel
            when Relationship::One
              res.call_action(:read, context.request, **overrides)
            when Relationship::Many
              res.call_action(:list, context.request, **overrides)
            end
          collection.concat expand_body(body)
        else
          error :relationship_not_includable, res.rel.name
        end
      end.uniq
    end

    def self.includes_to_hashes(path)
      path.to_s.split(',').each_with_object({}) do |path, obj|
        rel, *sub_path = path.split('.')
        obj[rel]       = includes_to_hashes(sub_path.join('.'))
      end
    end

    def expand_body(body)
      case body
      when Rack::BodyProxy
        json = JSONAPIonify.parse(body.body.join)
        Array.wrap(json[:data]) + (json[:included] || [])
      when Array
        json = JSONAPIonify.parse(body.join)
        Array.wrap(json[:data]) + (json[:included] || [])
      end
    end

  end
end
