module JSONAPIonify::Api
  module Base::Documentation
    extend ActiveSupport::Concern
    Link = Struct.new(:title, :href)

    module ClassMethods
      def cattr_nil *attrs
        attrs.each { |attr| define_singleton_method(attr){ nil } }
      end

      def documentation_order(resources_in_order)
        @documentation_order = resources_in_order
      end

      def link(title, href)
        links << Link.new(title, href)
      end

      def title(title)
        define_singleton_method :get_title do
          title
        end
      end

      def get_title
        self.name
      end

      def get_version
        '1.0'
      end

      def description(description)
        define_singleton_method :get_description do
          description
        end
      end

      def terms_of_service(terms_of_service)
        define_singleton_method :get_terms_of_service do
          terms_of_service
        end
      end

      def contact(name: nil, url: nil, email: nil)
        contact = Hash.new.tap do |h|
          name && h[:name] = name
          url && h[:url] = url
          email && h[:email] = email
        end
        define_singleton_method :get_contact do
          contact
        end if contact.present
      end

      def license(name:, url:)
        define_singleton_method :get_license do
          { name: name, url: url }
        end
      end

      def documentation_output(request)
        cache_store.fetch(cache_key documentation: true) do
          JSONAPIonify::Documentation.new(documentation_object(request)).result
        end
      end

      def resources_in_order
        indexes = @documentation_order || []
        resources.sort_by(&:name).sort_by do |resource|
          indexes.map(&:to_s).index(resource.type) || indexes.length
        end
      end

      def documentation_object(request)
        base_url = URI.parse(request.url).tap do |uri|
          uri.query = nil
          uri.path.chomp! request.path_info
          uri.path.chomp! '/docs'
        end.to_s
        OpenStruct.new(
          links:       links,
          title:       @title || self.name,
          base_url:    base_url,
          description: JSONAPIonify::Documentation.render_markdown(@description || ''),
          resources:   resources_in_order.map { |r| r.documentation_object base_url }
        )
      end
    end

    included do
      extend JSONAPIonify::InheritedAttributes
      inherited_array_attribute :links
      cattr_nil :get_description, :get_terms_of_service, :get_contact, :get_license
    end
  end
end
