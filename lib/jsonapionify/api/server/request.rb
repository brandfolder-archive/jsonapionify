require 'rack/request'
require 'rack/utils'
require 'rack/mock'

module JSONAPIonify::Api
  class Server::Request < Rack::Request
    def self.env_for(url, method, options = {})
      options[:method] = method
      new Rack::MockRequest.env_for(url, options)
    end

    def headers
      Rack::Utils::HeaderHash.new(
        env.select do |name, _|
          name.start_with?('HTTP_') && !%w{HTTP_VERSION}.include?(name)
        end.each_with_object({}) do |(name, value), hash|
          hash[name[5..-1].gsub('_', '-')] = value
        end
      )
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

    def accept
      accepts = (headers['accept'] || '*/*').split(',')
      accepts.to_a.sort_by! do |accept|
        _, *media_type_params = accept.split(';')
        rqf                   = media_type_params.find { |mtp| mtp.start_with? 'q=' }
        -(rqf ? rqf[2..-1].to_f : 1.0)
      end.map do |accept|
        mime, *media_type_params = accept.split(';')
        media_type_params.reject! { |mtp| mtp.start_with? 'q=' }
        [mime, *media_type_params].join(';')
      end
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
