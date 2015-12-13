module JSONAPIonify
  module Structure

    ValidationError = Class.new StandardError

    module Collections
      extend JSONAPIonify::Autoload
      autoload_all 'structure/collections'
    end

    module Maps
      extend JSONAPIonify::Autoload
      autoload_all 'structure/maps'
    end

    module Objects
      include Maps
      extend JSONAPIonify::Autoload
      autoload_all 'structure/objects'
    end

    module Helpers
      extend JSONAPIonify::Autoload
      autoload_all 'structure/helpers'
    end
  end
end
