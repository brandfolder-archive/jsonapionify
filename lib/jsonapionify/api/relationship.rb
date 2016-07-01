module JSONAPIonify::Api
  class Relationship
    extend JSONAPIonify::Autoload
    autoload_all

    extend Blocks
    include Documentation

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
        rel.owner.new(request: request).exec { |c| c }
      end

      context(:owner_context, readonly: true, persisted: true) do |request:|
        owner_context_proc.call(request)
      end

      context(:owner, readonly: true, persisted: true) do |owner_context:|
        owner_context.instance
      end

      context(:id, readonly: true, persisted: true) do
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

    attr_reader :owner, :class_proc, :name, :resolve, :hidden

    def initialize(owner, name, resource: nil, hidden: :list, resolve: proc { |n, o| o.send(n) }, &block)
      @class_proc = block || proc {}
      @owner      = owner
      @name       = name
      @resource   = resource || name
      @resolve    = resolve
      @hidden     = !!hidden && (hidden == true || Array.wrap(hidden))
    end

    def hidden_for_action?(action_name)
      return false if hidden == false
      Array.wrap(hidden).any? { |h| h == true || h.to_s == action_name.to_s }
    end

    def resource_class
      @resource_class ||= begin
        rel = self
        Class.new(resource) do
          define_singleton_method(:rel) do
            rel
          end

          rel.class_prepends.each { |prepend| class_eval(&prepend) }
          class_eval(&rel.class_proc)
          rel.class_appends.each { |append| class_eval(&append) }
        end
      end
    end

    def resource
      owner.api.resource(@resource)
    end

  end
end
