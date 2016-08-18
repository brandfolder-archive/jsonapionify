require 'yaml'

module JSONAPIonify::Api
  class SwaggerBuilder < Struct.new(:api, :request)

    def to_yaml
      YAML.dump as_json
    end

    def to_json
      Oj.dump(as_json)
    end

    def as_json
      to_h.deep_stringify_keys
    end

    def to_h
      {
        swagger: '2.0',
        info: InfoObject.new(api),
        host: [request.host, request.port].join(':'),
        basePath: request.path.chomp(request.path_info),
        schemes: [request.scheme],
        consumes: ['application/vnd.api+json'],
        produces: ['application/vnd.api+json'],
        definitions: definitions_object,
        paths: paths_object
      }
    end

    private

    def info_object
      Hash.new.tap do |h|
        (title = api.get_title) && h[:title] = title
        (description = api.get_description) && h[:description] = description
        (terms_of_service = api.get_terms_of_service) && h[:termsOfService] = terms_of_service
        (contact = api.get_contact) && h[:contact] = contact
        (license = api.get_license) && h[:license] = license
        (version = api.get_version) && h[:version] = version
      end
    end

    def paths_object
      api.resources.each_with_object({}) do |resource, h|
        h['/' + resource.type] = resource_paths(resource)
      end
    end

    def resource_paths(resource)
      resource_actions(resource).each_with_object({}) do |action, hash|
        hash[action.request_method.downcase] = action_object(resource, action)
      end
    end

    def resource_actions(resource)
      resource.new(request: request).actions.reject do |a|
        a.path.include? '*}'
      end
    end

    def action_object(resource, action)
      action_title = action.name.to_s.pluralize.titleize
      has_id = %i{list create}.include?(action.name)
      is_many_relationship = resource.respond_to?(:rel) && resource.rel.is_a?(Relationship::Many)
      is_collection = action.name == :list || (is_many_relationship && %i{show add remove replace}.include?(action.name))
      resource_name = is_collection ? resource.type.pluralize : resource.type.singularize
      {
        description: "#{action_title} #{resource_name}" + (has_id ? '.' : ' by its id.'),
        operationId: "#{action.name}#{resource_name.titleize}" + (has_id ? '' : 'ById'),
        produces: action.responses.map(&:accept),
        responses: action_responses(resource, action)
      }
    end

    def action_responses(resource, action)
      is_many_relationship = resource.respond_to?(:rel) && resource.rel.is_a?(Relationship::Many)
      is_collection = action.name == :list || (is_many_relationship && %i{show add remove replace}.include?(action.name))
      action.responses.select { |response| response.content_type == 'application/vnd.api+json' }.each_with_object({}) do |response, hash|
        hash[response.status] = {
          description: "The #{action.name}ed #{is_collection ? resource.type.pluralize : resource.type.singularize}"
        }
        hash[response.status][:schema] = {
          type: is_collection ? 'array' : 'object',
          **resource_read_data_for_action(resource, action)
        } unless action.name == :delete
      end
    end

    def definitions_object
      api.resources.each_with_object({}) do |resource, hash|
        hash[:resourceIdentifier] = {
          type: "object",
          properties: {
            type: { type: "string" },
            id: { type: "string " }
          }
        }
        hash[:relationshipLinks] = {
          type: "object",
          properties: {
            self: { type: "string" },
            related: { type: "string" }
          }
        }
      end
    end

    def resource_read_data_for_action(resource, action)
      hash = {}
      attributes = resource_read_attributes_for_action(resource, action)
      relationships = resource_read_relationships_for_action(resource, action)
      is_many_relationship = resource.respond_to?(:rel) && resource.rel.is_a?(Relationship::Many)
      is_collection = action.name == :list || (is_many_relationship && %i{show add remove replace}.include?(action.name))
      hash[:attributes] = { type: "object", properties: attributes } if attributes.present?
      hash[:relationships] = { type: "object", properties: relationships } if relationships.present?
      rid = { '$ref': '#/definitions/resourceIdentifier' }
      props_hash = hash.present? ? { allOf: [rid, ] } : {}
      # hash.present? ? { allOf: [rid, { type: 'object', hash] } : { (is_collection ? :items : :properties) => rid }
      if is_collection
        { allOf: { [hash, { }] } }
      else
        props_hash
      end
    end

    def resource_read_attributes_for_action(resource, action)
      resource.attributes.each_with_object({}) do |attribute, hash|
        context = resource.new(request: request).exec { |c| c }
        next unless attribute.supports_read_for_action?(action.name, context)
        hash[attribute.name] = {
          type: attribute.type.swagger_name
        }
      end
    end

    def resource_read_relationships_for_action(resource, action)
      resource.relationships.each_with_object({}) do |relationship, hash|
        hash[relationship.name] = {
          type: "object",
          properties: {
            links: { '$ref': '#/definitions/relationshipLinks' },
            data: relationship_data_object(relationship)
          }
        }
      end
    end

    def relationship_data_object(relationship)
      case relationship
      when Relationship::One
        { '$ref': '#/definitions/resourceIdentifier' }
      when Relationship::Many
        { type: 'array', items: { '$ref': '#/definitions/resourceIdentifier' } }
      end
    end

  end
end
