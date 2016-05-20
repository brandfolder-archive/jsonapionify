module JSONAPIonify::Api
  module Base::Documentation
    Link = Struct.new(:title, :href)

    def self.extended(klass)
      klass.class_eval do
        extend JSONAPIonify::InheritedAttributes
        inherited_array_attribute :links
      end
    end

    def documentation_order(resources_in_order)
      @documentation_order = resources_in_order
    end

    def link(title, href)
      links << Link.new(title, href)
    end

    def title(title)
      @title = title
    end

    def description(description)
      @description = description
    end

    def documentation_output(request)
      cache_store.fetch(resource_signature) do
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
end
