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
ParseFasta::SeqFile.open(aln_fname).each_record do |rec|
  names[rec.id] = names.count
  alns << rec.seq.chars

  aln_len ||= rec.seq.length

  abort_unless aln_len == rec.seq.length,
               "Aln len mismatch for #{rec.id}"
end

aln_cols = alns.transpose

tree = NewickTree.fromFile(tree_fname).midpointRoot

TreeClusters.all_clades(tree).each_with_index do |clade, idx|
  if clade.all_leaves.count >= clade_size_cutoff

    low_ent_cols = []
    genome_idxs = clade.all_leaves.map { |genome| names[genome] }

    sub_cols = []
    aln_cols.each_with_index do |col, cidx|
      sub_col = genome_idxs.map do |gidx|
        col[gidx]
      end


      if sub_col.none? { |aa| aa == "-" } && entropy(sub_col) <= ENTROPY_CUTOFF
        sub_cols << [cidx + 1, sub_col.first]
      end
    end

    puts ["clade_#{idx+1}",
          clade.all_leaves.count,
          clade.all_leaves,
         ].join "\t"

    STDERR.puts ["clade_#{idx+1}", aln_len, sub_cols.count, sub_cols.map(&:first)].join "\t"
  end
end
