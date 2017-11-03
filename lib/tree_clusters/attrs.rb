module TreeClusters
  # A Hash table for genome/leaf/taxa attributes
  class Attrs < Hash

    # Returns the an AttrArray of Sets for the given genomes and
    # attribute.
    #
    # @note If a genome is in the leaves array, but is not in the hash
    #   table, NO error will be raised. Rather that genome will be
    #   skipped. This is for cases in which not all genomes have
    #   attributes.
    #
    # @param leaves [Array<String>] names of the leaves for which you
    #   need attributes
    # @param attr [Symbol] the attribute you are interested in eg,
    #   :genes
    #
    # @return [AttrArray<Set>] an AttrArray of Sets of
    #   attributes
    #
    # @raise [AbortIf::Exit] if they leaf is present but doesn't have
    #   the requested attr
    def attrs leaves, attr
      ary = leaves.map do |leaf|

        if self.has_key? leaf
          abort_unless self[leaf].has_key?(attr),
                       "Missing attr #{attr.inspect} for leaf '#{leaf}'"

          self[leaf][attr]
        else
          nil
        end
      end.compact

      TreeClusters::AttrArray.new ary
    end

    def add leaf, attr, val
      if self.has_key? leaf
        self[leaf][attr] = val
      else
        self[leaf] = { attr => val }
      end
    end
  end
end
