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

    def documentation_object(request)
      title                 = @title || self.name
      description           = JSONAPIonify::Documentation.render_markdown description(@description || '')
      @documentation_object ||= Class.new(SimpleDelegator) do
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
          defined_resources.each_with_object({}) do |(name, _), hash|
            hash[name.to_s] = resource(name).documentation_object(request)
          end
        end
      end.new(self)
    end
  end
end
