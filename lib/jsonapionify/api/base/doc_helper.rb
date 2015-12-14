module JSONAPIonify::Api
  module Base::DocHelper
    def title(title)
      @title = title
    end

    def description(description)
      @description = description
    end

    def documentation_output(request)
      # @documentation_output ||=
      JSONAPIonify::Documentation.new(documentation_object(request)).result
    end

    def resources_in_order
      ordered_names = (@documentation_order || [])
      names         = ordered_names + (resource_definitions.keys - ordered_names)
      names.map do |name|
        resource(name)
      end
    end

    def documentation_object(request)
      title       = @title || self.name
      description = JSONAPIonify::Documentation.render_markdown description(@description || '')
      Class.new(SimpleDelegator) do
        define_method(:base_url) do
          URI.parse(request.url).tap do |uri|
            uri.query = nil
            uri.path.chomp! request.path_info
            uri.path.chomp! '/docs'
          end.to_s
        end

        define_method(:title) do
          title
        end

        define_method(:description) do
          description
        end

        define_method(:resources) do
          resources_in_order.each_with_object({}) do |(name, resource), hash|
            hash[name.to_s] = resource.documentation_object(request)
          end
        end
      end.new(self)
    end
  end
end
