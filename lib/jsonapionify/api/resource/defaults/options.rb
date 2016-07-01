module JSONAPIonify::Api
  module Resource::Defaults::Options
    def self.scope_is_active_record? scope
      return false unless defined?(ActiveRecord)
      scope < ActiveRecord::Base
    rescue NoMethodError, ArgumentError, TypeError
      false
    end

    extend ActiveSupport::Concern
    included do
      id :id
      scope { self.type.classify.constantize }
      collection do |scope, context|
        Resource::Defaults::Options.scope_is_active_record?(scope) ? scope.all : scope
      end

      instance do |scope, key|
        raise NotImplementedError, 'instance not implemented' unless Resource::Defaults::Options.scope_is_active_record?(scope)
        scope.find_by! id_attribute => key
      end

      new_instance do |scope|
        raise NotImplementedError, 'new_instance not implemented' unless scope.respond_to?(:new)
        scope.new
      end

      before do |context|
        context.request_headers # pull request_headers so they verify
      end

      before do |context|
        context.params # pull params so they verify
      end

    end
  end
end
