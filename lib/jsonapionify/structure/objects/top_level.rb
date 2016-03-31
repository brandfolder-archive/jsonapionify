# TopLevelObject
# ========
#
# A JSON object **MUST** be at the root of every JSON API request and response
# containing data. This object defines a document's "top level".
module JSONAPIonify::Structure
  module Objects
    class TopLevel < Base
      attr_reader :origin

      define_order *%i{jsonapi data included errors meta links}

      default(:jsonapi) { Jsonapi.new version: '1.0' }

      # A document **MUST** contain at least one of:
      must_contain_one_of!(
        # **data:** The document's "primary data"
        :data,
        # **errors:** An array of errors
        :errors,
        # **meta:** a meta object that contains non-standard meta-information.
        :meta
      )

      collects :errors, as: Collections::Errors
      implements :meta, as: Meta

      # The members `data` and `errors` **MUST NOT** coexist in the same document.
      must_not_coexist! :data, :errors

      # A document **MAY** contain any of these top-level members:
      may_contain!(
        # **links:** a links_object related to the primary data.
        :links,
        # **included:** an array of resource objects that are related to the primary.
        :included,
        # **jsonapi:** an object describing the server's implementation.
        :jsonapi
      )

      implements :links, as: Maps::TopLevelLinks
      collects :included, as: Collections::IncludedResources
      implements :jsonapi, as: Jsonapi
      is_resource = ->(obj) { (obj.keys - %i{id type}).present? }
      collects_or_implements(
        :data,
        collects:   Collections::Resources,
        implements: Resource,
        if:         ->(obj) {
          obj.is_a?(Resource) || (obj.is_a?(Hash) && is_resource[obj])
        })
      collects_or_implements(
        :data,
        collects:   Collections::ResourceIdentifiers,
        implements: ResourceIdentifier,
        if:         ->(obj) {
          obj.is_a?(ResourceIdentifier) || (obj.is_a?(Hash) && !is_resource[obj])
        })

      # If a document does not contain a top-level `data` key, the `included` member
      # **MUST NOT** be present either.
      may_not_exist! :included, without: :data

      # The document's "primary data" is a representation of the resource or collection
      # of resources targeted by a request.
      # Primary data **MUST** be either:
      type_of! :data, must_be: [
                                 # A single **ResourceObject**
                                 Resource,
                                 # A single **ResourceIdentifierObject**
                                 ResourceIdentifier,
                                 # Null
                                 NilClass,
                                 # A collection of **ResourceObjects**
                                 Collections::Resources,
                                 # A collection of **[ResourceIdentifierObjects](resource_identifier_object.html)**
                                 Collections::ResourceIdentifiers
                               ]

      def compile(**opts)
        compiled        = super(**opts)
        compiled_errors = compiled['errors'] || []
        all_errors      = compiled_errors | errors.as_collection.compile
        if all_errors.present?
          self.class.new(
            errors: all_errors,
            meta:   {
              invalid_object: to_hash
            }
          ).compile
        else
          compiled
        end
      end

      def as(origin)
        copy.tap do |obj|
          obj.instance_variable_set :@origin, origin
        end
      end

      after_initialize do
        @origin = :server
      end
    end
  end
end
