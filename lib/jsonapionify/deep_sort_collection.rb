module JSONAPIonify
  module DeepSortCollection
    refine Array do
      def deep_sort(hash)
        keys   = hash.to_a
        sorter = lambda do |iterator, depth = 0|
          key_name, order = keys[depth]
          if key_name
            sorted = iterator.sort_by(&key_name)
            sorted.reverse! if order == :desc
            sorted.group_by(&key_name).values.map do |value|
              sorter.call(value, depth + 1)
            end.reduce(:+) || []
          else
            iterator
          end
        end
        sorter.call(self)
      end
    end
  end
end
