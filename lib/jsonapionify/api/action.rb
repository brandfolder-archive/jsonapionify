require 'unstrict_proc'

module JSONAPIonify::Api
  class Action
    extend JSONAPIonify::Autoload
    autoload_all
    extend Dummy
    include Documentation

    attr_reader :name, :block, :content_type, :responses, :prepend,
                :path, :request_method, :only_associated, :cacheable,
                :callbacks

    def initialize(name, request_method, path = nil,
                   example_input: nil,
                   content_type: nil,
                   prepend: nil,
                   only_associated: false,
                   cacheable: false,
                   callbacks: true,
                   &block)
      @request_method  = request_method
      @path            = path || ''
      @prepend         = prepend
      @only_associated = only_associated
      @name            = name
      @example_input   = example_input
      @content_type    = content_type || 'application/vnd.api+json'
      @block           = block || proc {}
      @responses       = []
      @cacheable       = cacheable
      @callbacks       = callbacks
    end

    def initialize_copy(new_instance)
      super
      %i{@responses}.each do |ivar|
        value = instance_variable_get(ivar)
        new_instance.instance_variable_set(
          ivar, value.frozen? ? value : value.dup
        )
      end
    end

    def build_path(base, name, include_path)
      File.join(*[base].tap do |parts|
        parts << prepend if prepend
        parts << name
        parts << path if path.present? && include_path
      end)
    end

    def path_regex(base, name, include_path)
      raw_reqexp =
        build_path(
          base, name, include_path
        ).gsub(
          ':id', '(?<id>[^\/]+)'
        ).gsub(
          '/*', '/?[^\/]*'
        )
      Regexp.new('^' + raw_reqexp + '(\.[A-Za-z_-]+)?$')
    end

    def ==(other)
      self.class == other.class &&
        %i{@request_method @path @content_type @prepend}.all? do |ivar|
          instance_variable_get(ivar) == other.instance_variable_get(ivar)
        end
    end

    def supports_path?(request, base, name, include_path)
      request.path_info.match(path_regex(base, name, include_path))
    end

    def supports_content_type?(request)
      @content_type == request.content_type || !request.has_body?
    end

    def supports_request_method?(request)
      request.request_method == @request_method
    end

    def supports?(request, base, name, include_path)
      supports_path?(request, base, name, include_path) &&
        supports_request_method?(request) &&
        supports_content_type?(request)
    end

    def response(**options, &block)
      new_response = Response.new(self, **options, &block)
      @responses.delete new_response
      @responses.push new_response
      self
    end

    def call(resource, request, callbacks: self.callbacks, **opts)
      resource.new(
        request:   request,
        callbacks: callbacks,
        cacheable: cacheable,
        action:    self,
        **opts
      ).call
    end
  end
end
