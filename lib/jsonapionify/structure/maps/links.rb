module JSONAPIonify::Structure
  module Maps
    class Links < Base

      value_is Objects::Link

      validate_each! message: 'must be url string or valid link object' do |*, value|
        case value
        when String
          uri = URI.parse(value)
          uri.scheme.present?
        when Objects::Link
          true
        else
          false
        end
      end

    end
  end
end
