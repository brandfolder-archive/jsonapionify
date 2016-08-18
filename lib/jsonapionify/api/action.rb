require 'unstrict_proc'

module JSONAPIonify::Api
  class Action < UnboundAction

    attr_reader :resource, :context
    delegate :include_path, :base_path, to: :resource
    delegate :request, to: :context

    def initialize
      raise 'Cannot be directly invoked, use bind instead'
    end

    def pathname
      resource.class.respond_to?(:rel) ? super.chomp('/{id}') : super
    end

    def path
      @path ||= File.join(resource.class.base_path(prepend: prepend), *pathname).chomp('/')
    end

    def path_regex
      @path_regex ||= begin
        string = path.
          gsub(/\{([\w-]+)\}/, '(?<\\1>[\\w-]+)'). # Sub out named params
          gsub(/(\/)?\{([\w-]+)\*\}/, '\\1(?<\\2>.*)'). # Sub out Named Wildcards
          gsub(/(\/)?\{\*\}/, '\\1(.*)') # Sub out wildcards
        Regexp.new "^#{string}(\\.[\\w-]+)?$"
      end
    end

    def path_matches
      @path_matches ||= request.path_info.match path_regex
    end

    def path_params
      @path_params ||= path_matches&.names&.each_with_object({}) do |name, hash|
        hash[name.to_sym] = path_matches[name]
      end
    end

    def supports_path?
      !!path_matches
    end

    def inspect
    to_s.chomp('>') + " " +
      %i{name request_method path content_type cacheable callbacks only_associated}.map do |method|
        "#{method}=#{send(method).inspect}"
      end.join(', ')
    end

    def supports_content_type?
      @content_type == request.content_type || !request.has_body?
    end

    def supports_request_method?
      request.request_method == @request_method
    end

    def supports?
      supports_path? && supports_request_method? && supports_content_type?
    end

    def response(**options, &block)
      new_response = Response.new(self, **options, &block)
      @responses.delete new_response
      @responses.push new_response
      self
    end
  end
end
