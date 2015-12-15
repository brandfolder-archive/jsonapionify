module JSONAPIonify::Api
  module Base::DocHelper
    def title(title)
      @title = title
    end

    def description(description)
      @description = description
    end

    def documentation_output(request)
      @documentation_output ||= JSONAPIonify::Documentation.new(documentation_object(request)).result
    end

    def resources_in_order
      indexes = @documentation_order || []
      resources.sort_by { |resource| indexes.index(resource.name) || indexes.length }
    end

    def documentation_object(request)
      base_url = URI.parse(request.url).tap do |uri|
        uri.query = nil
        uri.path.chomp! request.path_info
        uri.path.chomp! '/docs'
      end.to_s
      OpenStruct.new(
        title:       @title || self.name,
        base_url:    base_url,
        description: JSONAPIonify::Documentation.render_markdown(@description || ''),
        resources:   resources_in_order.map { |r| r.documentation_object base_url }
      )
    end
  end
end
