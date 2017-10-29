# Require the library
require "tree_clusters"

# Make the TreeClusters methods available under the namespace
# TreeClusters
TreeClusters.extend TreeClusters

# Read in the Newick formatted tree
tree = NewickTree.fromFile ARGV.first

# Iterate through all the clades
TreeClusters.all_clades(tree).each do |clade|
  # Print out the clade name and the names of all leaves in that clade
  printf "%s\t%s\n", clade.name, clade.all_leaves.join(", ")
end
