require 'rack/utils'

module JSONAPIonify::Api
  class Server::MockResponse
    attr_reader :status, :headers, :body

    def initialize(status, headers, body)
      @status = status
      @body   = body.is_a?(Rack::BodyProxy) ? body.body : body
      @headers = Rack::Utils::HeaderHash.new headers
    end

    def body
      return nil unless @body.present?
      JSON.pretty_generate(Oj.load(@body.join("\n")))
    rescue Oj::ParseError
      @body
    end

    def http_string
      # HTTP/1.1 200 OK
      # Date: Fri, 31 Dec 1999 23:59:59 GMT
      # Content-Type: text/html
      # Content-Length: 1354
      #
      # <body>
      [].tap do |lines|
        lines << "HTTP/1.1 #{status} #{Rack::Utils::HTTP_STATUS_CODES[status]}"
        headers.each do |k, v|
          lines << "#{k.split('-').map(&:capitalize).join('-')}: #{v}"
        end
        lines << ''
        lines << body if body.present?
      end.join("\n")
    end
  end
end
