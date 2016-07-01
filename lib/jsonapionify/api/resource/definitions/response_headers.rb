module JSONAPIonify::Api
  module Resource::Definitions::ResponseHeaders
    using JSONAPIonify::DestructuredProc

    def self.extended(klass)
      klass.class_eval do
        extend JSONAPIonify::InheritedAttributes
        inherited_hash_attribute :response_header_definitions

        context(:response_headers, persisted: true) do |context|
          self.class.response_header_definitions.each_with_object({}) do |(name, block), headers|
            headers[name.to_s] = instance_exec(context, &block.destructure)
          end
        end
      end
    end

    def response_header(name, &block)
      self.response_header_definitions[name] = block
    end

  end
end
