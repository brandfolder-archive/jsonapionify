module JSONAPIonify::Api
  module Resource::Defaults::Options
    extend ActiveSupport::Concern
    included do
      id :id
      scope { raise NotImplementedError, 'scope not implemented' }
      collection { raise NotImplementedError, 'collection not implemented' }
      instance { raise NotImplementedError, 'instance not implemented' }
      new_instance { raise NotImplementedError, 'new instance not implemented' }

      # Standard HTTP Headers
      # https://en.wikipedia.org/wiki/List_of_HTTP_header_fields#Request_fields
      request_header 'accept', documented: false
      request_header 'accept-charset', documented: false
      request_header 'accept-encoding', documented: false
      request_header 'accept-language', documented: false
      request_header 'accept-datetime', documented: false
      request_header 'authorization', documented: false
      request_header 'cache-control', documented: false
      request_header 'connection', documented: false
      request_header 'cookie', documented: false
      request_header 'content-length', documented: false
      request_header 'content-md5', documented: false
      request_header 'content-type', documented: false
      request_header 'date', documented: false
      request_header 'expect', documented: false
      request_header 'from', documented: false
      request_header 'host', documented: false
      request_header 'if-match', documented: false
      request_header 'if-modified-since', documented: false
      request_header 'if-none-match', documented: false
      request_header 'if-range', documented: false
      request_header 'if-unmodified-since', documented: false
      request_header 'max-forwards', documented: false
      request_header 'origin', documented: false
      request_header 'pragma', documented: false
      request_header 'proxy-authorization', documented: false
      request_header 'range', documented: false
      request_header 'referer', documented: false
      request_header 'te', documented: false
      request_header 'user-agent', documented: false
      request_header 'upgrade', documented: false
      request_header 'via', documented: false
      request_header 'warning', documented: false

      # Non-Standard, but widely used HTTP headers
      request_header 'x-requested-with', documented: false
      request_header 'dnt', documented: false
      request_header 'x-forwarded-for', documented: false
      request_header 'x-forwarded-host', documented: false
      request_header 'x-forwarded-proto', documented: false
      request_header 'front-end-https', documented: false
      request_header 'x-att-device-id', documented: false
      request_header 'x-wap-profile', documented: false
      request_header 'proxy-connection', documented: false
      request_header 'x-uidh', documented: false
      request_header 'upgrade-insecure-requests', documented: false

      # Don't allow method overrides
      # request_header 'x-http-method-override', documented: false

      # Don't allow CSRF tokens, as they should not be used
      # in the api by default
      # request_header 'x-csrf-token', documented: false

      before do |context|
        context.request_headers # pull request_headers so they verify
      end

      before do |context|
        context.params # pull params so they verify
      end


    end
  end
end
