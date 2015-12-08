require 'redcarpet'

module JSONAPIonify::Api
  module Resource::ClassMethods
    using JSONAPIonify::IndentedString
    include JSONAPIonify::EnumerableObserver

    def description(description)
      @description = description.deindent
    end

    def set_api(api)
      self.tap do
        define_singleton_method :api do
          api
        end
      end
    end

    def set_type(type)
      type = type.to_s
      self.tap do
        define_singleton_method :type do
          type
        end
      end
    end

    def api
      nil
    end

    def documentation_object(request)
      description           = @description || ''
      @documentation_object ||= Class.new(SimpleDelegator) do
        define_method(:url) do
          File.join request.host, type
        end

        define_method(:description) do
          markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true)
          markdown.render(description)
        end

        define_method(:resources) do
          defined_resources.each_with_object({}) do |(name, _), hash|
            hash[name.to_s] = resource(name).documentation_object
          end
        end

        define_method(:attributes) do
          super().each_with_object({}) do |attribute, hash|
            hash[attribute.name] = attribute
          end
        end

        define_method(:relationships) do
          relationship_definitions.each_with_object({}) do |(name, (resource, _)), hash|
            hash[name.to_s] = OpenStruct.new(
              resource: resource,
              allow:    relationship(name).allow
            )
          end
        end
      end.new(self)
    end

  end
end