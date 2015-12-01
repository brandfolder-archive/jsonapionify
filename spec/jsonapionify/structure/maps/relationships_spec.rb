require 'spec_helper'
module JSONAPIonify::Structure::Maps
  # Relationships
  # =============
  describe Relationships do
    include_context 'fields object'
    # The value of the `relationships` key **MUST** be an object (a "relationships
    # object"). Members of the relationships object ("relationships") represent
    # references from the [resource object][resource objects] in which it's defined to other resource
    # objects.
    #
    # Relationships may be to-one or to-many.
  end
end
