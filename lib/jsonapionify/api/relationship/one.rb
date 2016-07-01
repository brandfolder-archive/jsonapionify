module JSONAPIonify::Api
  class Relationship::One < Relationship
    using JSONAPIonify::DestructuredProc

    DEFAULT_REPLACE_COMMIT = proc { |owner:, request_instance:|
      # Set the association
      owner.send "#{self.class.rel.name}=", request_instance

      # Save the instance
      owner.save if owner.respond_to? :save
    }

    prepend_class do
      rel = self.rel
      remove_action :list, :create

      class << self
        undef_method :list
      end

      define_singleton_method(:show) do |content_type: nil, callbacks: true, &block|
        options = {
          content_type: content_type,
          callbacks:    callbacks,
          cacheable:    true,
          prepend:      'relationships'
        }
        define_action(:show, 'GET', **options, &block).response status: 200 do |response_object:, instance:|
          response_object[:data] = build_resource_identifier(instance: instance)
          response_object.to_json
        end
      end

      define_singleton_method(:replace) do |content_type: nil, callbacks: true, &block|
        block ||= DEFAULT_REPLACE_COMMIT
        options = {
          content_type: content_type,
          callbacks:    callbacks,
          cacheable:    false,
          prepend:      'relationships'
        }
        define_action(:replace, 'PATCH', **options, &block).response status: 200 do |response_object:, instance:|
          response_object[:data] = build_resource_identifier(instance: instance)
          response_object.to_json
        end
      end

      context :instance do |context, owner:|
        instance_exec(rel.name, owner, context, &rel.resolve.destructure)
      end

      after :commit_replace do |owner:|
        if defined?(ActiveRecord) && owner.is_a?(ActiveRecord::Base)
          # Collect Errors
          if owner.errors.present?
            owner.errors.messages.each do |attr, messages|
              messages.each do |message|
                error :invalid_attribute, attr, message
              end
            end
          end
        end
      end

      show
    end
  end
end
