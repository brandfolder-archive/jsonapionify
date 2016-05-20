module JSONAPIonify::Api
  module Relationship::Documentation
    def options_json
      {
        name:              name,
        type:              resource.type,
        relationship_type: self.class.name.split(':').last.downcase
      }
    end

    def documentation_object
      OpenStruct.new(
        name:     name,
        resource: resource_class.type
      )
    end
  end
end
