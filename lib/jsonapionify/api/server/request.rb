require 'rack/request'
require 'rack/utils'

module JSONAPIonify::Api
  class Server::Request < Rack::Request
    def headers
      Rack::Utils::HeaderHash.new(
        env.select do |name, _|
          name.start_with? 'HTTP'
        end.each_with_object({}) do |(name, value), hash|
          hash[name[5..-1]] = value
        end
      )
    end

    def accept
      accepts = headers['accept'] && headers['accept'].split(',')
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
    end

    def root_url
      URI.parse(url).tap do |uri|
        uri.query = nil
        uri.path.chomp! path_info
      end.to_s
    end
  end
end
