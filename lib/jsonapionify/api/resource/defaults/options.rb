module JSONAPIonify::Api
  module Resource::Defaults::Options
    extend ActiveSupport::Concern
    included do
      id :id
      scope { raise NotImplementedError, 'scope not implemented' }
      collection { raise NotImplementedError, 'collection not implemented' }
      instance { raise NotImplementedError, 'instance not implemented' }
      new_instance { raise NotImplementedError, 'new instance not implemented' }

      context :scope_defined? do |context|
        begin
          !!context.scope
        rescue NotImplementedError
          false
        end
      end

      context :collection_defined? do |context|
        begin
          !!context.collection
        rescue NotImplementedError
          false
        end
      end

      context :instance_defined? do |context|
        begin
          !!context.instance
        rescue NotImplementedError
          false
        end
      end

      context :new_instance_defined? do |context|
        begin
          !!context.new_instance
        rescue NotImplementedError
          false
        end
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
