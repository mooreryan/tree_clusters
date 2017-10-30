# Require the library
require "tree_clusters"
require "parse_fasta"
require "abort_if"

include AbortIf
include AbortIf::Assert



def get_char_freqs str
  str_len = str.length.to_f

  str.chars.group_by(&:itself).values.map do |arr|
    arr.count / str_len
  end
end

# Shannon entropy (see http://rosettacode.org/wiki/Entropy#Ruby)
def entropy ary
  char_freqs = get_char_freqs ary.join

  char_freqs.reduce(0) do |entropy, char_freq|
    entropy - char_freq * Math.log2(char_freq)
  end
end

TreeClusters.extend TreeClusters

ENTROPY_CUTOFF = ARGV[0].to_f

clade_size_cutoff = ARGV[1].to_i
tree_fname = ARGV[2]
aln_fname  = ARGV[3]

names = {}
alns  = []
aln_len = nil
id2aln = TreeClusters::Attrs.new
ParseFasta::SeqFile.open(aln_fname).each_record do |rec|
  id2aln[rec.id] = { aln: rec.seq.chars }

  aln_len ||= rec.seq.length

  abort_unless aln_len == rec.seq.length,
               "Aln len mismatch for #{rec.id}"
end

aln_cols = alns.transpose

tree = NewickTree.fromFile(tree_fname).midpointRoot

def get_low_ent_cols leaves, id2aln
  low_ent_cols = []
  alns = id2aln.attrs leaves, :aln
  aln_cols = alns.transpose

  aln_cols.each_with_index do |col, col_idx|
    if col.none? { |aa| aa == "-" } && entropy(col) <= ENTROPY_CUTOFF
      low_ent_cols << (col_idx + 1)
    end
  end

  Set.new low_ent_cols
end

def non_parent_leaves clade, tree
  Set.new(tree.taxa) - Set.new(clade.parent_leaves)
end

f0 = File.open("OUTPUT_0.txt", "w")
f1 = File.open("OUTPUT_1.txt", "w")

# Also would be good to have key_cols of this clade not in any
# sibling, i.e. if col 2 is a key column in the clade and in sibling
# 1, but not in sibling 2, then col2 will be in f2, but a file f2.5
# would be good where col2 would NOT be in the file cos at least one
# sibling has something the same here.
f2 = File.open("OUTPUT_2_key_cols_this_clade_not_in_all_siblings.txt", "w")
f3 = File.open("OUTPUT_3_key_cols_of_siblings_not_in_this_clade.txt", "w")
f4 = File.open("OUTPUT_4_key_cols_of_non_parent_leaves_not_in_parent_leaves.txt", "w")
f5 = File.open("OUTPUT_5_key_cols_in_parent_leaves_not_in_non_parent_leaves.txt", "w")
f6 = File.open("OUTPUT_6.txt", "w")
f7 = File.open("OUTPUT_7_key_cols_of_parent_leaves.txt", "w")
f8 = File.open("OUTPUT_8_key_cols_of_this_clade.txt", "w")

def puts_info fhandle, clade_name, aln_len, key_cols
  fhandle.puts [clade_name,
                aln_len,
                key_cols.count,
                key_cols.to_a.sort,
               ].join "\t"
end

TreeClusters.all_clades(tree).each_with_index do |clade, idx|
  # Use this for a name as not all clades will have good names.
  clade_name = "clade_#{idx + 1}"

  if clade.all_leaves.count >= clade_size_cutoff
    key_cols_all_leaves =
      get_low_ent_cols clade.all_leaves, id2aln
    key_cols_sibling_leaves =
      get_low_ent_cols clade.sibling_leaves, id2aln
    key_cols_non_parent_leaves =
      get_low_ent_cols non_parent_leaves(clade, tree), id2aln
    key_cols_parent_leaves =
      get_low_ent_cols clade.parent_leaves, id2aln

    f0.puts [clade_name,
             clade.all_leaves.count,
             clade.all_leaves,
            ].join "\t"

    # Key cols of this clade NOT in sibling
    puts_info f2, clade_name, aln_len, key_cols_all_leaves - key_cols_sibling_leaves

    # Key cols of sibling NOT in this clade
    puts_info f3, clade_name, aln_len, key_cols_sibling_leaves - key_cols_all_leaves

    # Key cols unique to non parent leaves, i.e. rest of tree
    puts_info f4, clade_name, aln_len, key_cols_non_parent_leaves - key_cols_parent_leaves

    # Key cols unique to parent NOT in rest of tree
    puts_info f5, clade_name, aln_len, key_cols_parent_leaves - key_cols_non_parent_leaves

    # Key cols of parent
    puts_info f7, clade_name, aln_len, key_cols_parent_leaves

    # Key cols of this clade
    puts_info f8, clade_name, aln_len, key_cols_all_leaves
  end
end

f0.close
f1.close
f2.close
f3.close
f4.close
f5.close
f6.close
f7.close
f8.close
