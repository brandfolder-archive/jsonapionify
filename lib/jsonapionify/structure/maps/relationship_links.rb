module JSONAPIonify::Structure
  module Maps
    class RelationshipLinks < Links
      # The RelationshipLinksObject **MAY** contain the following members:
      must_contain_one_of! :self, # the link that generated the current response document.
                           :related # a related resource link when the primary data represents a resource relationship.

      may_contain! *Helpers::PaginationLinks
    end
  end
end
