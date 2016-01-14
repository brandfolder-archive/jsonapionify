module JSONAPIonify::Api
  module Resource::Definitions::Helpers

    def helper(name, &block)
      define_method(name, &block)
    end

    def authentication(&block)
      before do |context|
        if instance_exec(context.request, context.authentication, &block) == false
          error_now :forbidden
        end
      end
    end

    def on_exception(&block)
      before_exception &block
    end

  end
end
