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
        JSONAPIonify::Structure::Maps::RelationshipLinks.new(
          self:    File.join(base_url, 'relationships', rel.name.to_s),
          related: File.join(base_url, rel.name.to_s)
        )
      end
    end

    attr_reader :owner, :class_proc, :name, :associate

    def initialize(owner, name, resource: nil, associate: true, &block)
      @class_proc = block || proc {}
      @owner      = owner
      @name       = name
      @resource   = resource || name
      @associate  = associate.nil? ? true : associate
    end

    def allow
      Array.new.tap do |ary|
        ary << 'read'
        ary << 'write' if @associate
      end
    end

    def documentation_object(base_url)
      OpenStruct.new(
        name: name,
        allow: allow,
        actions: resource_class.actions.map { |a| a.documentation_object resource_class, base_url, name.to_s, false }
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

  end
end
