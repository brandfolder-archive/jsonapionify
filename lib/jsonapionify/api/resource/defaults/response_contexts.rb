module JSONAPIonify::Api
  module Resource::Defaults::ResponseContexts
    extend ActiveSupport::Concern

    included do
      context(:invalidate_cache?, readonly: true, persisted: true) do |includes:|
        includes.present?
      end

      # Response Objects
      context(:links, readonly: true, persisted: true) do |response_object:|
        response_object[:links]
      end

      context(:meta, readonly: true, persisted: true) do |response_object:|
        JSONAPIonify::Structure::Helpers::MetaDelegate.new response_object
      end

      context(:response_object, readonly: true, persisted: true) do |request:|
        JSONAPIonify.parse(links: { self: request.url })
      end

      context(:response_collection, readonly: true) do |collection:, nested_request: false, paginated_collection: nil, sorted_collection: nil|
        nested_request ? collection : paginated_collection || sorted_collection || collection
      end

    end
  end
end
