module JSONAPIonify::Structure
  module Objects
    class Error < Base
      may_contain! :id, :links, :status, :code, :title, :detail, :source, :meta

      implements :links, as: Maps::ErrorLinks
      implements :source, as: Source
      implements :meta, as: Meta

      type_of! :id, must_be: String
      type_of! :status, must_be: String
      type_of! :code, must_be: String
      type_of! :title, must_be: String
    end
  end
end
