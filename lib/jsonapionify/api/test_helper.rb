require 'rack/test'
require 'active_support/concern'

module JSONAPIonify
  module Api::TestHelper
    extend ActiveSupport::Concern
    include Rack::Test::Methods

    included do
      around(:each) do |example|
        if example.run && last_response && (last_response_json rescue false)
          aggregate_failures do
            "response failures"
            last_response_error_messages.each do |message|
              expect(message).to be_empty, message
            end
          end
        end
      end
    end

    module ClassMethods
      def set_api(api)
        define_method(:app) do
          api
        end
      end
    end

    def last_response_error_messages
      last_response_errors&.map do |error|
        {
          id:        error['id'],
          code:      error['code'],
          status:    error['status'],
          title:     error['title'],
          detail:    error['detail'],
          links:     error['links'],
          source:    error['source']&.each_with_object([]) { |(k, v), a|
            a << "\n  #{k}: #{v}" if v
          }&.join,
          meta:      error['meta']&.except('backtrace')&.each_with_object([]) { |(k, v), a|
            a << "\n  #{k}: #{v}" if v
          }&.join,
          ': ':       ':',
          backtrace: ["\n", *(error.dig('meta', 'backtrace') || [])].join("\n")
        }.each_with_object([]) { |(k, v), a|
          a << "#{k}: #{v}" if v&.strip
        }.join("\n")
      end
    end

    def last_response_errors
      last_response_json['errors']
    rescue
      []
    end

    def set_headers
      @set_headers ||= Rack::Utils::HeaderHash.new
    end

    def json(hash)
      Oj.dump hash.deep_stringify_keys
    end

    def last_response_json
      Oj.load last_response.body
    end

    def header(name, value)
      set_headers[name] = value
      super
    end

    def content_type(value)
      header('content-type', value)
    end

    def accept(*values)
      header('accept', values.join(','))
    end

    def delete(*args, &block)
      header('content-type', set_headers['content-type'].to_s)
      super
    end

    def authorization(type, value)
      header 'Authorization', [type, value].join(' ')
    end

  end
end
