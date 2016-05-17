module JSONAPIonify::Api
  module Resource::Defaults::Hooks
    extend ActiveSupport::Concern

    included do
      before :commit_create, :commit_update do |context|
        # Assign the attributes
        context.request_attributes.each do |key, value|
          context.instance.send "#{key}=", value
        end

        # Assign the relationships
        context.request_relationships.each do |key, value|
          context.instance.send "#{key}=", value
        end

      end

      after :commit_create, :commit_update do |context|
        try_commit(context.instance)
      end

      after :commit_delete do |context|
        if defined?(ActiveRecord) && context.instance.is_a?(ActiveRecord::Base)
          context.instance.destroy
        end
      end

      before :commit_add do |context|
        context.scope.concat context.request_instances
      end

      before :commit_remove do |context|
        context.request_instances.each { |instance| context.scope.delete(instance) }
      end

      before :commit_replace do |context|
        case self.class.rel
        when Relationship::One
          context.owner.send "#{self.class.rel.name}=", context.request_instance
          try_commit(context.owner)
        when Relationship::Many
          instances_to_add    = context.request_instances - context.scope
          instances_to_delete = context.scope - context.request_instances
          instances_to_delete.each { |instance| context.scope.delete(instance) }
          context.scope.append instances_to_add
        end
      end
    end

    def try_commit(instance)
      if defined?(ActiveRecord) && instance.is_a?(ActiveRecord::Base)
        commit_active_record(instance)
      end
    end

    def commit_active_record(instance)
      instance.save
      if instance.errors.present?
        instance.errors.messages.each do |attr, messages|
          messages.each do |message|
            error :invalid_attribute, attr, message
          end
        end
      end
    end
  end
end
