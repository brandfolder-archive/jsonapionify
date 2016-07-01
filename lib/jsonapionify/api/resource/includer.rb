require 'concurrent'

module JSONAPIonify::Api
  module Resource::Includer
    include JSONAPIonify::Structure
    extend ActiveSupport::Concern

    included do
      after :commit_list do |context|
        if context.includes.present?
          included =
            context.response_collection.map do |instance|
              fetch_included(context, owner: instance)
            end.reduce(:|)
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

      context :includes do |context|
        Resource::Includer.includes_to_hashes context.params['include']
      end
    end

    def append_included(context, included)
      if included.present?
        context.response_object[:included] |= included
      end
    end

    def fetch_included(context, **overrides)
      context.includes.reduce(Collections::IncludedResources.new) do |lv, (name, _)|
        if self.class.include_definitions.keys.include?(name.to_sym)
          response_object = JSONAPIonify.new_object
          res = self.class.relationship(name)
          overrides = overrides.merge includes:         context.includes[name],
                                      errors:           context.errors,
                                      root_request?:    false,
                                      action_name:      context.action_name,
                                      response_object:  response_object
          action_name = res.rel.is_a?(Relationship::One) ? :read : :list
          res.call_action(action_name, context.request, context_overrides: overrides)
          lv | (Array.wrap(response_object[:data]).compact + response_object[:included])
        else
          error :relationship_not_includable, res.rel.name
          lv
        end
      end
    end

    def self.includes_to_hashes(path)
      path.to_s.split(',').each_with_object({}) do |p, obj|
        rel, *sub_path = p.split('.')
        obj[rel]       = includes_to_hashes(sub_path.join('.'))
      end
    end

  end
end
