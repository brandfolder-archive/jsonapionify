require 'rack/request'
require 'rack/utils'
require 'rack/mock'
require 'mime-types'

module JSONAPIonify::Api
  class Server::Request < Rack::Request
    def self.env_for(url, method, options = {})
      options[:method] = method
      new Rack::MockRequest.env_for(url, options)
    end

    def headers
      env_headers                 = env.select do |name, _|
        name.start_with?('HTTP_') && !%w{HTTP_VERSION}.include?(name)
      end.each_with_object({}) do |(name, value), hash|
        hash[name[5..-1].gsub('_', '-').downcase] = value
      end
      env_headers['content-type'] = content_type if content_type
      Rack::Utils::HeaderHash.new(env_headers)
    end

    def http_string
      # GET /path/file.html HTTP/1.0
      # From: someuser@jmarshall.com
      # User-Agent: HTTPTool/1.0
      # [blank line here]
      [].tap do |lines|
        lines << "#{request_method} #{fullpath} HTTP/1.1"
        headers.each do |k, v|
          lines << "#{k.split('-').map(&:capitalize).join('-')}: #{v}"
        end
        lines << ''
        lines << pretty_body if has_body?
      end.join("\n")
    end

    def pretty_body
      return '' unless has_body?
      value = body.read
      JSON.pretty_generate(Oj.load(value))
    rescue Oj::ParseError
      value
    ensure
      body.rewind
    end

    def extension
      ext = File.extname(path)
      return nil unless ext
      ext[0] == '.' ? ext[1..-1] : ext
    end

    def content_type
      super.try(:split, ';').try(:first)
    end

    def accept_params
      @accept_params ||= begin
        ext_mime = MIME::Types.type_for(path)[0]&.content_type
        accepts = (headers['accept'] || ext_mime || '*/*').split(',')
        types = [ext_mime].compact | accepts
        types.each_with_object({}) do |type, list|
          list[Server::MediaType.type(type)] = Server::MediaType.params(type)
        end
      end
    end

    def jsonapi_params
      accept_params['application/vnd.api+json'] || {}
    end

    def accept
      @accept ||= accept_params.keys
    end

    def authorizations
      parts = headers['authorization'].to_s.split(' ')
      parts.length == 2 ? Rack::Utils::HeaderHash.new([parts].to_h) : {}
    end

    def has_body?
      body.read(1).present?
    ensure
      body.rewind
    end

    def root_url
      URI.parse(url).tap do |uri|
        uri.query = nil
        uri.path.chomp! path_info
      end.to_s
    end
  end
end
