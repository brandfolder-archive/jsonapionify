module JSONAPIonify::Api
  module Resource::Definitions::Helpers

    def helper(name, &block)
      define_method(name, &block)
    end

    def authentication(&block)
      context :authentication, readonly: true, persisted: true do |context|
        OpenStruct.new.tap do |authentication_object|
          if instance_exec(context.request, authentication_object, &block) == false
            error_now :forbidden
          end
        end
      end

      before do |context|
        context.authentication
      end
    end

    def on_exception(&block)
      before_exception &block
    end

  end
end
