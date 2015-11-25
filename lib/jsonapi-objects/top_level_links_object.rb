module JSONAPIObjects
  class TopLevelLinksObject < LinksObject
    # The TopLevelLinksObject **MAY** contain the following members:
    may_contain! :self, # the link that generated the current response document.
                 :related, # a related resource link when the primary data represents a resource relationship.
                 *PaginationLinks # pagination links for the primary data.
  end
end
