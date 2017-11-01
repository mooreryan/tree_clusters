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
  def all_clades tree, metadata=nil
    return enum_for(:all_clades, tree, metadata) unless block_given?

    tree.clade_nodes.reverse.each do |node|
      yield Clade.new node, tree, metadata
    end
  end

  def snazzy_clades tree, metadata
    snazzy_clades = {}

    clades = self.
             all_clades(tree, metadata).
             sort_by { |clade| clade.all_leaves.count }.
             reverse

    metadata.each do |md_cat, leaf2mdtag|
      already_checked = Set.new
      single_tag_clades = {}

      clades.each do |clade|
        assert clade.all_leaves.count > 1,
               "A clade cannot also be a leaf"

        unless clade.all_leaves.all? do |leaf|
                 already_checked.include? leaf
               end
          md_tags = clade.all_leaves.map do |leaf|
            assert leaf2mdtag.has_key?(leaf),
                   "leaf #{leaf} is missing from leaf2mdtag ht"

            leaf2mdtag[leaf]
          end

          # this clade is mono-phyletic w.r.t. this metadata category.
          if md_tags.uniq.count == 1
            clade.all_leaves.each do |leaf|
              already_checked << leaf
            end

            assert !single_tag_clades.has_key?(clade),
                   "clade #{clade.name} is repeated in single_tag_clades for #{md_cat}"

            single_tag_clades[clade] = md_tags.first
          end
        end
      end

      single_tag_clades.each do |clade, md_tag|
        non_clade_leaves = tree.taxa - clade.all_leaves

        non_clade_leaves_with_this_md_tag = non_clade_leaves.map do |leaf|
          [leaf, leaf2mdtag[leaf]]
        end.select { |ary| ary.last == md_tag }

        if non_clade_leaves_with_this_md_tag.count.zero?
          if snazzy_clades.has_key? clade.name
            snazzy_clades[clade.name][md_cat] = md_tag
          else
            snazzy_clades[clade.name] = { md_cat => md_tag }
          end
        end
      end
    end

    snazzy_clades
  end

  def read_mapping_file fname
    md_cat_names = nil
    metadata = TreeClusters::Attrs.new

    File.open(fname, "rt").each_line.with_index do |line, idx|
      leaf_name, *metadata_vals = line.chomp.split "\t"

      if idx.zero?
        md_cat_names = metadata_vals
      else
        metadata_vals.each_with_index do |val, val_idx|
          metadata.add md_cat_names[val_idx], leaf_name, val
        end
      end
    end

    metadata
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
                  :other_leaves,
                  :single_tag_info,
                  :all_tags

    # @param node [NewickNode] a NewickNode from a NewickTree
    # @param tree [NewickTree] a NewickTree
    def initialize node, tree, metadata=nil
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

      if metadata
        @metadata = metadata
        @all_tags ||= get_all_tags
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
        self.single_tag_info == clade.single_tag_info
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
