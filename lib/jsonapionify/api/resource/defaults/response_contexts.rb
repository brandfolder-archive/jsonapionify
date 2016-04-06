module JSONAPIonify::Api
  module Resource::Defaults::ResponseContexts
    extend ActiveSupport::Concern

    included do
      context(:raw_collection?, readonly: true) { false }
      context(:invalidate_cache?, readonly: true) { |c| c.includes.present? }

      # Response Objects
      context(:links, readonly: true) do |context|
        context.response_object[:links]
      end

      context(:meta, readonly: true) do |context|
        JSONAPIonify::Structure::Helpers::MetaDelegate.new context.response_object
      end

      context(:response_object) do |context|
        JSONAPIonify.parse(links: { self: context.request.url })
      end

      context(:response_collection) do |context|
        if context.root_request?
          collections = %i{
            paginated_collection
            sorted_collection
            collection
          }
          context.public_send collections.find { |c| context.respond_to? c }
        else
          context.collection
        end
      end

    end
  end
end
