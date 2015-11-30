# TopLevelObject
# ========
#
# A JSON object **MUST** be at the root of every JSON API request and response
# containing data. This object defines a document's "top level".
module JSONAPIObjects
  class TopLevelObject < BaseObject
    attr_reader :origin

    default(:jsonapi) { JSONAPIObject.new version: '1.0' }

    # A document **MUST** contain at least one of:
    must_contain_one_of!(
      # **data:** The document's "primary data"
      :data,
      # **errors:** An array of errors
      :errors,
      # **meta:** a meta object that contains non-standard meta-information.
      :meta
    )

    collects :errors, as: ErrorsCollection
    implements :meta, as: MetaObject

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

    implements :links, as: TopLevelLinksObject
    collects :included, as: IncludedResourcesCollection
    implements :jsonapi, as: JSONAPIObject
    is_resource_identifier = ->(obj) { obj.keys.sort == %i{id type}.sort }
    collects_or_implements(
      :data,
      collects:   ResourcesCollection,
      implements: ResourceObject,
      if:         ->(obj) {
        obj.is_a?(ResourceObject) || (obj.is_a?(Hash) && !is_resource_identifier[obj])
      })
    collects_or_implements(
      :data,
      collects:   ResourceIdentifiersCollection,
      implements: ResourceIdentifierObject,
      if:         ->(obj) {
        obj.is_a?(ResourceIdentifierObject) || (obj.is_a?(Hash) && is_resource_identifier[obj])
      })

    # If a document does not contain a top-level `data` key, the `included` member
    # **MUST NOT** be present either.
    may_not_exist! :included, without: :data

    # The document's "primary data" is a representation of the resource or collection
    # of resources targeted by a request.
    # Primary data **MUST** be either:
    type_of! :data, must_be: [
                               # A single **ResourceObject**
                               ResourceObject,
                               # A single **ResourceIdentifierObject**
                               ResourceIdentifierObject,
                               # Null
                               Null,
                               # A collection of **ResourceObjects**
                               ResourcesCollection,
                               # A collection of **[ResourceIdentifierObjects](resource_identifier_object.html)**
                               ResourceIdentifiersCollection
                             ]

    def as(origin)
      copy.tap do |obj|
        obj.instance_variable_set :@origin, origin
      end
    end

    set_callback :initialize, :after do
      @origin = :server
    end
  end
end
