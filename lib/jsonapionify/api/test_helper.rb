require 'rack/test'
require 'active_support/concern'

module JSONAPIonify
  module Api::TestHelpers
    extend ActiveSupport::Concern
    include Rack::Test::Methods

    module ClassMethods
      def set_api(api)
        define_method(:app) do
          api
        end
      end
    end

    def json(hash)
      Oj.dump hash
    end

  end
end
