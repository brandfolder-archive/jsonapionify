module JSONAPIonify::Api
  class Relationship
    Dir.glob("#{__dir__}/relationship/*.rb").each do |file|
      basename = File.basename file, File.extname(file)
      fullpath = File.expand_path file
      autoload basename.camelize.to_sym, fullpath
    end

    extend Blocks

    attr_reader :owner, :class_proc, :name, :associate

    def initialize(owner, name, resource: nil, associate: true, &block)
      @class_proc = block || proc {}
      @owner      = owner
      @name       = name
      @resource   = resource || name
      @associate  = associate.nil? ? true : associate
    end

    append_class do
      remove_action :delete, :update

      define_singleton_method(:build_links) do |base_url|
        JSONAPIonify::Structure::Maps::RelationshipLinks.new(
          self:    File.join(base_url, 'relationships', rel.name.to_s),
          related: File.join(base_url, rel.name.to_s)
        )
      end

      define_singleton_method(:allow) do
        Array.new.tap do |ary|
          ary << 'read'
          ary << 'write' if rel.associate
        end
      end
    end


    def build_class
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

    def resource
      owner.api.resource(@resource)
    end

  end
end