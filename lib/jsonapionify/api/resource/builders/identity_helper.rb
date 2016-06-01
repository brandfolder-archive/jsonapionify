module JSONAPIonify::Api
  module Resource::Builders
    module IdentityHelper
      def build_url
        URI.parse(request.root_url).tap do |uri|
          uri.path      = File.join uri.path, resource_type, build_id
          sticky_params = resource.sticky_params(context.params)
          uri.query     = sticky_params.to_param if sticky_params.present?
        end.to_s
      end

      def build_id
        IdBuilder.build(resource, instance: instance)
      end
    end
  end
end
