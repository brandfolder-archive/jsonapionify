module JSONAPIonify::Api
  module Resource::Definitions::RequestHeaders

    def self.extended(klass)
      klass.class_eval do
        extend JSONAPIonify::InheritedAttributes
        inherited_hash_attribute :request_header_definitions
      end
    end

    def header(name, **options)
      request_header_definitions[name] = HeaderOptions.new(name, **options)
    end

  end
end
