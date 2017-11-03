module TreeClusters
  # Provides convenience methods for working with Arrays of Sets
  class AttrArray < Object::Array
    # Takes the union of all sets in the AttrArray
    #
    # @return [Set]
    def union
      self.reduce(&:union)
    end

    # Takes the intersection of all sets in the AttrArray
    #
    # @return [Set]
    def intersection
      self.reduce(&:intersection)
    end
  end
end
