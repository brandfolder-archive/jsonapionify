module JSONAPIonify::Api
  module Resource::Definitions::Hooks
    def self.extended(klass)
      klass.class_eval do
        define_callbacks(
          :request,
          :exception,
          :response,
          :list,    :commit_list,
          :create,  :commit_create,
          :read,    :commit_read,
          :update,  :commit_update,
          :delete,  :commit_delete,
          :show,    :commit_show,
          :add,     :commit_add,
          :remove,  :commit_remove,
          :replace, :commit_replace
        )
        class << klass
          alias_method :on_exeception, :before_exception
          remove_method :before_exception
          remove_method :after_exception
        end
      end
    end

    %i{before after}.each do |cb|
      define_method(cb) do |*action_names, &block|
        return send(:"#{cb}_request", &block) if action_names.blank?
        action_names.each do |action_name|
          send("#{cb}_#{action_name}", &block)
        end
      end
    end
  end
end
