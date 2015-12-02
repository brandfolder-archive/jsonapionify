module JSONAPIonify::Structure
  module Collections
    class IncludedResources < Resources
      value_is Objects::IncludedResource

      def self.referenceable?(referenced, not_referenced)
        not_referenced.any? do |unreferenced_item|
          referenced.any? do |referenced_item|
            referenced_item.relates_to? unreferenced_item
          end
        end
      end

      def referenced
        return [] unless parent
        top_level_referenced.tap do |referenced|
          not_referenced = reduce([]) { |a, i| a << i }

          while self.class.referenceable?(referenced, not_referenced)
            not_referenced.each do |resource|
              if referenced.any? { |referenced_item| referenced_item.relates_to? resource }
                referenced << not_referenced.delete(resource)
              end
            end
          end
        end
      end

      private

      def top_level_referenced
        return [] unless parent
        reduce([]) { |a, i| a << i }.select do |resource|
          Array.wrap(parent[:data]).any? { |tlr| tlr.relates_to? resource }
        end
      end
    end
  end
end
