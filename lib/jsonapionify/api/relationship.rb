module JSONAPIonify::Api
  class Relationship
    extend JSONAPIonify::Autoload
    autoload_all

    extend Blocks

    prepend_class do
      remove_action :delete, :update
      class << self
        undef_method :delete, :update
      end
    end

    append_class do

      def self.supports_path?
        false
      end

      def self.relationship(name)
        rel.resource.relationship(name)
      end

      owner_context_proc = Proc.new do |request|
        ContextDelegate.new(request, rel.owner.new, rel.owner.context_definitions)
      end

      context(:owner_context) do |context|
        owner_context_proc.call(context.request)
      end

      context(:owner) do |context|
        context.owner_context.instance
      end

      context(:id) do
        nil
      end

      define_singleton_method :base_path do
        "/#{rel.owner.type}/:id"
      end

      define_singleton_method :path_name do
        rel.name.to_s
      end

      define_singleton_method(:build_links) do |base_url|
        build_url = ->(*paths) {
          URI.parse(base_url).tap do |uri|
            uri.path  = File.join uri.path, *paths
            params    = sticky_params(Rack::Utils.parse_nested_query(uri.query))
            uri.query = params.to_param if params.present?
          end.to_s
        }

        JSONAPIonify::Structure::Maps::RelationshipLinks.new(
          self:    build_url['relationships', rel.name.to_s],
          related: build_url[rel.name.to_s]
        )
      end
    end

    attr_reader :owner, :class_proc, :name, :resolve

    def initialize(owner, name, resource: nil, includable: false, resolve: proc { |name, owner| owner.send(name) }, &block)
      @class_proc = block || proc {}
      @owner      = owner
      @name       = name
      @includable = includable
      @resource   = resource || name
      @resolve    = resolve
    end

    def options_json
      {
        name:              name,
        type:              resource.type,
        relationship_type: self.class.name.split(':').last.downcase
      }
    end

    def documentation_object
      OpenStruct.new(
        name:     name,
        resource: resource_class.type
      )
    end

    def resource_class
      @resource_class ||= begin
        rel = self
        Class.new(resource) do
          define_singleton_method(:rel) do
            rel
          end

          rel.class_prepends.each { |prepend| class_eval &prepend }
          class_eval(&rel.class_proc)
          rel.class_appends.each { |append| class_eval &append }
        end
      end
    end

    def resource
      owner.api.resource(@resource)
    end

    def includable?
      !!@includable
    end

  end
end
