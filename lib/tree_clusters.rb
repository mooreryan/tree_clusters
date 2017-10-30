require "abort_if"
require "Newick"
require "set"
require "tree_clusters/version"

include AbortIf
include AbortIf::Assert

# Monkey patch of the NewickTree class
class NewickTree
  # Like NewickTree.clades but returns NewickNodes instead of taxa
  # names.
  #
  # @return [Array<NewickNode>] array of NewickNodes representing the
  #   tree clades
  def clade_nodes
    clades = []
    @root.descendants.each do |clade|
      clades.push(clade) if (!clade.children.empty?)
    end
    return clades
  end
end

# Top level namespace of the Gem.
module TreeClusters

  # Given a NewickTree, return an array of all Clades in that tree.
  #
  # @param tree [NewickTree] a NewickTree object
  #
  # @yieldparam clade [Clade] a clade of the tree
  #
  # @return [Enumerator<Clade>] enumerator of Clade objects
  def all_clades tree
    return enum_for(:all_clades, tree) unless block_given?

    tree.clade_nodes.reverse.each do |node|
      yield Clade.new node, tree
    end
  end

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

  # Represents a clade in a NewickTree
  class Clade
    attr_accessor :name,
                  :all_leaves,
                  :left_leaves,
                  :right_leaves,
                  :all_sibling_leaves,
                  :each_sibling_leaf_set,
                  :parent_leaves,
                  :non_parent_leaves,
                  :other_leaves

    # @param node [NewickNode] a NewickNode from a NewickTree
    # @param tree [NewickTree] a NewickTree
    def initialize node, tree
      @name = node.name
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
                               map { |node| descendant_leaves node }

      @all_sibling_leaves = @each_sibling_leaf_set.flatten.uniq

      parent = node.parent
      assert parent,
             "Noge #{node.name} has no parent. Is it the root?"
      @parent_leaves = descendant_leaves parent

      @other_leaves =
        Object::Set.new(tree.taxa) - Object::Set.new(all_leaves)

      @non_parent_leaves =
        Object::Set.new(tree.taxa) - Object::Set.new(parent_leaves)
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
        self.other_leaves == clade.other_leaves
      )
    end

    # Alias for ==
    def eql? clade
      self == clade
    end

    private

    def descendant_leaves node
      if node.leaf?
        [node.name]
      else
        node.
          descendants.
          flatten.
          uniq.
          select { |node| node.leaf? }.map(&:name)
      end
    end
  end
end
