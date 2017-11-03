require "abort_if"
require "Newick"
require "set"
require "parse_fasta"
require "shannon"
require "tree_clusters/attrs"
require "tree_clusters/attr_array"
require "tree_clusters/clade"
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

  def unquoted_taxa
    self.taxa.map { |str| str.tr %q{"'}, "" }
  end
end

# Top level namespace of the Gem.
module TreeClusters

  # Given an ary of strings, find the most common string in the ary.
  #
  # @param bases [Array<String>] an array of strings
  #
  # @return most_common_str [String] the most common string in the ary.
  #
  # @example Upper case and lower case count as the same.
  #   TreeClusters::consensus %w[a A C T] #=> "A"
  # @example Ties take the one closest to the end
  #   TreeClusters::consensus %w[a c T t C t g] #=> "T"
  #
  # @note Each string is upcase'd before frequencies are calculated.
  def consensus bases
    bases.
      map(&:upcase).
      group_by(&:itself).
      sort_by { |_, bases| bases.count }.
      reverse.
      first.
      first
  end

  def read_alignment aln_fname
    leaf2attrs = TreeClusters::Attrs.new
    aln_len = nil
    ParseFasta::SeqFile.open(aln_fname).each_record do |rec|
      leaf2attrs[rec.id] = { aln: rec.seq.chars }

      aln_len ||= rec.seq.length

      abort_unless aln_len == rec.seq.length,
                   "Aln len mismatch for #{rec.id}"
    end

    leaf2attrs
  end

  def low_ent_cols leaves, leaf2attrs, entropy_cutoff
    low_ent_cols = []
    alns = leaf2attrs.attrs leaves, :aln
    aln_cols = alns.transpose

    aln_cols.each_with_index do |aln_col, aln_col_idx|
      has_gaps = aln_col.any? { |aa| aa == "-" }
      low_entropy =
        Shannon::entropy(aln_col.join.upcase) <= entropy_cutoff

      if !has_gaps && low_entropy
        low_ent_cols << (aln_col_idx + 1)
      end
    end

    Set.new low_ent_cols
  end

  # @note If there are quoted names in the tree file, they are
  #   unquoted first.
  def check_ids tree, mapping, aln
    tree_ids = Set.new(NewickTree.fromFile(tree).unquoted_taxa)

    mapping_ids = Set.new
    File.open(mapping, "rt").each_line.with_index do |line, idx|
      unless idx.zero?
        id, *rest = line.chomp.split

        mapping_ids << id
      end
    end

    aln_ids = Set.new
    ParseFasta::SeqFile.open(aln).each_record do |rec|
      aln_ids << rec.id
    end

    if !(tree_ids == mapping_ids && mapping_ids == aln_ids)
      AbortIf::logger.error { "Seq IDs did not match in all input files" }

      tree_ids = tree_ids.to_a.sort
      mapping_ids = mapping_ids.to_a.sort
      aln_ids = aln_ids.to_a.sort

      AbortIf::logger.debug { ["tree_ids", tree_ids].join "\t" }
      AbortIf::logger.debug { ["mapping_ids", mapping_ids].join "\t" }
      AbortIf::logger.debug { ["aln_ids", aln_ids].join "\t" }

      raise AbortIf::Exit
    else
      true
    end
  end


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
        non_clade_leaves = tree.unquoted_taxa - clade.all_leaves

        non_clade_leaves_with_this_md_tag = non_clade_leaves.map do |leaf|
          [leaf, leaf2mdtag[leaf]]
        end.select { |ary| ary.last == md_tag }

        if non_clade_leaves_with_this_md_tag.count.zero?
          if snazzy_clades.has_key? clade
            snazzy_clades[clade][md_cat] = md_tag
          else
            snazzy_clades[clade] = { md_cat => md_tag }
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

  def read_attrs_file fname

    attr_names = Set.new
    File.open(fname, "rt").each_line.with_index do |line, idx|
      unless idx.zero?
        _, attr_name, _ = line.chomp.split "\t"

        attr_names << attr_name
      end
    end

    attr_names = attr_names.to_a.sort

    attrs = TreeClusters::Attrs.new

    File.open(fname, "rt").each_line.with_index do |line, idx|
      unless idx.zero?
        leaf, attr_name, attr_val = line.chomp.split "\t"

        if attrs.has_key? leaf
          if attrs[leaf].has_key? attr_name
            attrs[leaf][attr_name] << attr_val
          else
            attrs[leaf][attr_name] = Set.new([attr_val])
          end
        else
          attrs[leaf] = {}

          attr_names.each do |name|
            attrs[leaf][name] = Set.new
          end
          attrs[leaf][attr_name] << attr_val
        end
      end
    end

      [attr_names, attrs]
  end
end
