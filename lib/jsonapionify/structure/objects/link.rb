module JSONAPIonify::Structure
  module Objects
    class Link < Base
      define_order *%i{href meta}

      may_contain! :href, :meta

      validate! :href, message: 'must be a valid URL' do |*, value|
        if value.is_a?(String)
          uri = URI.parse(value)
          uri.scheme.present?
        else
          false
        end
      end

    end
  end
end
