module TreeClusters
  # Represents a clade in a NewickTree
  class Clade
    attr_accessor :node,
                  :name,
                  :all_leaves,
                  :left_leaves,
                  :right_leaves,
                  :all_sibling_leaves,
                  :each_sibling_leaf_set,
                  :parent_leaves,
                  :non_parent_leaves,
                  :other_leaves,
                  :single_tag_info,
                  :all_tags

    # @note If a node name is quoted, then those quotes are removed
    #   first.
    #
    # @param node [NewickNode] a NewickNode from a NewickTree
    # @param tree [NewickTree] a NewickTree
    def initialize node, tree, metadata = nil
      tree_taxa = tree.unquoted_taxa

      @node = node
      @name       = unquote node.name
      @all_leaves = descendant_leaves node

      if (children = node.children).count == 2
        lchild, rchild = node.children

        @left_leaves = descendant_leaves lchild

        @right_leaves = descendant_leaves rchild
      end

      siblings = node.siblings
      # assert siblings.count == 1,
      #        "Node #{node.name} has more than one sibling."

      @each_sibling_leaf_set = siblings.
          map {|node| descendant_leaves node}

      @all_sibling_leaves = @each_sibling_leaf_set.flatten.uniq

      parent = node.parent
      assert parent,
             "Noge #{node.name} has no parent. Is it the root?"
      @parent_leaves = descendant_leaves parent

      @other_leaves =
          Object::Set.new(tree_taxa) - Object::Set.new(all_leaves)

      @non_parent_leaves =
          Object::Set.new(tree_taxa) - Object::Set.new(parent_leaves)

      if metadata
        @metadata        = metadata
        @all_tags        ||= get_all_tags
        @single_tag_info ||= get_single_tag_info
      else
        @single_tag_info = nil
      end
    end

    # Compares two Clades field by field.
    #
    # If all instance variables are == than the two clades are == as
    # well.
    def == clade
      (
      self.name == clade.name &&
          self.all_leaves == clade.all_leaves &&
          self.left_leaves == clade.left_leaves &&
          self.right_leaves == clade.right_leaves &&
          self.all_sibling_leaves == clade.all_sibling_leaves &&
          self.each_sibling_leaf_set == clade.each_sibling_leaf_set &&
          self.parent_leaves == clade.parent_leaves &&
          self.other_leaves == clade.other_leaves &&
          self.single_tag_info == clade.single_tag_info &&
          self.all_tags == clade.all_tags
      )
    end

    # Alias for ==
    def eql? clade
      self == clade
    end

    private

    def get_single_tag_info
      @all_tags.map do |md_cat, set|
        [md_cat, set.count == 1 ? set.to_a.first : nil]
      end.to_h
    end

    def get_all_tags
      # name2tag has leaf names => metadata tag and is an Attrs
      @metadata.map do |md_cat, name2tag|
        tag_info = self.all_leaves.map do |leaf|
          assert name2tag.has_key?(leaf),
                 "leaf #{leaf} is not present in name2tag ht for " +
                     "md_cat #{md_cat}"

          name2tag[leaf]
        end

        [md_cat, Set.new(tag_info)]
      end.to_h
    end

    def descendant_leaves node
      if node.leaf?
        [unquote(node.name)]
      else
        node.
            descendants.
            flatten.
            uniq.
            select {|node| node.leaf?}.
            map {|node| unquote(node.name)}
      end
    end

    def unquote str
      str.tr %q{"'}, ""
    end
  end
end
