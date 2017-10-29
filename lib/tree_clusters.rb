require "abort_if"
require "Newick"
require "tree_clusters/version"

include AbortIf
include AbortIf::Assert

class NewickTree
  # returns array of arrays representing the tree clades
  def clade_nodes
    clades = []
    @root.descendants.each do |clade|
      clades.push(clade) if (!clade.children.empty?)
    end
    return clades
  end
end

module TreeClusters
  def all_clades tree
    tree.clade_nodes.reverse.map do |node|
      Clade.new node, tree
    end
  end

  class Attrs < Hash
    def attrs leaves, attr
      leaves.map { |leaf| self[leaf][attr] }
    end
  end

  class Array < Object::Array
    def union
      self.reduce(&:union)
    end

    def intersection
      self.reduce(&:intersection)
    end
  end

  class Clade
    attr_accessor :name,
                  :all_leaves,
                  :left_leaves,
                  :right_leaves,
                  :sibling_leaves,
                  :parent_leaves,
                  :other_leaves

    def initialize node, tree
      @name = node.name
      @all_leaves = descendant_leaves node

      children = node.children
      assert children.count == 2,
             "Not a bifurcating tree (See: #{node.name})"
      lchild, rchild = node.children

      @left_leaves = descendant_leaves lchild

      @right_leaves = descendant_leaves rchild

      siblings = node.siblings
      assert siblings.count == 1,
             "Node #{node.name} has more than one sibling."
      @sibling_leaves = descendant_leaves siblings.first

      parent = node.parent
      assert parent,
             "Noge #{node.name} has no parent. Is it the root?"
      @parent_leaves = descendant_leaves parent

      @other_leaves = Set.new(tree.taxa) - Set.new(all_leaves)
    end

    def == clade
      (
        self.name == clade.name &&
        self.all_leaves == clade.all_leaves &&
        self.left_leaves == clade.left_leaves &&
        self.right_leaves == clade.right_leaves &&
        self.sibling_leaves == clade.sibling_leaves &&
        self.parent_leaves == clade.parent_leaves &&
        self.other_leaves == clade.other_leaves
      )
    end

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
