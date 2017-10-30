require "spec_helper"

def read_all_clusters fname
  clusters = []
  File.open(fname, "rt").each_line do |line|
    cluster, count, *members = line.chomp.split "\t"

    clusters << members.sort
  end

  clusters.sort_by { |ary| ary.length }
end

RSpec.describe TreeClusters do
  let(:klass) { Class.extend TreeClusters }

  let(:test_file_dir) do
    File.join File.dirname(__FILE__), "..", "test_files"
  end

  let(:newick_fname) do
    File.join test_file_dir, "test.tre"
  end
  let(:tree) do
    Object::NewickTree.fromFile newick_fname
  end

  let(:non_bifurcating_tree) do
    Object::NewickTree.fromFile(File.join(test_file_dir,
                                          "non_bifurcating.tre"))
  end
  let(:non_bifurcating_clades) do
    [
      TreeClusters::Clade.new(non_bifurcating_tree.findNode("cluster1",
                                                            exact: true),
                              tree),
      TreeClusters::Clade.new(non_bifurcating_tree.findNode("cluster2",
                                                            exact: true),
                              tree),
      TreeClusters::Clade.new(non_bifurcating_tree.findNode("cluster3",
                                                            exact: true),
                              tree),
    ]
  end
  let(:non_bifurcating_all_sibling_leaves) do
    [
      ["g4", "g5", "g6",
       "g1", "g2", "g3",].sort,
      ["g7", "g8", "g9",
       "g1", "g2", "g3",].sort,
      ["g4", "g5", "g6",
       "g7", "g8", "g9",].sort
    ]
  end

  let(:non_bifurcating_each_sibling_leaf_set) do
    [
      [["g4", "g5", "g6"],
       ["g1", "g2", "g3"]].sort,

      [["g7", "g8", "g9"],
       ["g1", "g2", "g3"]].sort,

      [["g4", "g5", "g6"],
       ["g7", "g8", "g9"]].sort,
    ]
  end

  let(:expected_clades) do
    [
      TreeClusters::Clade.new(tree.findNode("cluster19", exact: true),
                              tree),
      TreeClusters::Clade.new(tree.findNode("cluster22", exact: true),
                              tree),
      TreeClusters::Clade.new(tree.findNode("cluster11", exact: true),
                              tree),
      TreeClusters::Clade.new(tree.findNode("cluster14", exact: true),
                              tree),
      TreeClusters::Clade.new(tree.findNode("cluster7",  exact: true),
                              tree),
      TreeClusters::Clade.new(tree.findNode("cluster1",  exact: true),
                              tree),
      TreeClusters::Clade.new(tree.findNode("cluster4",  exact: true),
                              tree),
      TreeClusters::Clade.new(tree.findNode("cluster6",  exact: true),
                              tree),
      TreeClusters::Clade.new(tree.findNode("cluster10", exact: true),
                              tree),
      TreeClusters::Clade.new(tree.findNode("cluster16", exact: true),
                              tree),
    ]
  end

  let(:expected_names) do
    ["cluster19",
     "cluster22",
     "cluster11",
     "cluster14",
     "cluster7",
     "cluster1",
     "cluster4",
     "cluster6",
     "cluster10",
     "cluster16",
    ]
  end

  let(:all_taxa) do
    ["g1", "g2", "g3", "g4a", "g4b", "g5", "g6", "g7", "g8", "g9",
     "g10", "g11"]
  end

  let(:expected_all_leaves) do
    [
      ["g9", "g10"],
      ["g9", "g10", "g11"],
      ["g5", "g6"],
      ["g5", "g6", "g7"],
      ["g4a", "g4b"],
      ["g1", "g2"],
      ["g1", "g2", "g3"],
      ["g1", "g2", "g3", "g4a", "g4b"],
      ["g1", "g2", "g3", "g4a", "g4b", "g5", "g6", "g7"],
      ["g1", "g2", "g3", "g4a", "g4b", "g5", "g6", "g7", "g8"],
    ]
  end

  let(:expected_left_leaves) do
    [
      ["g9"],
      ["g9", "g10"],
      ["g5"],
      ["g5", "g6"],
      ["g4a"],
      ["g1"],
      ["g1", "g2"],
      ["g1", "g2", "g3"],
      ["g1", "g2", "g3", "g4a", "g4b"],
      ["g1", "g2", "g3", "g4a", "g4b", "g5", "g6", "g7"],
    ]
  end

  let(:expected_right_leaves) do
    [
      ["g10"],
      ["g11"],
      ["g6"],
      ["g7"],
      ["g4b"],
      ["g2"],
      ["g3"],
      ["g4a", "g4b"],
      ["g5", "g6", "g7"],
      ["g8"],
    ]
  end

  let(:expected_all_sibling_leaves) do
    [
      ["g11"],
      ["g1", "g2", "g3", "g4a", "g4b", "g5", "g6", "g7", "g8"],
      ["g7"],
      ["g1", "g2", "g3", "g4a", "g4b"],
      ["g1", "g2", "g3"],
      ["g3"],
      ["g4a", "g4b"],
      ["g5", "g6", "g7"],
      ["g8"],
      ["g9", "g10", "g11"],
    ]
  end

  let(:expected_parent_leaves) do
    [
      ["g9", "g10", "g11"],
      ["g1", "g2", "g3", "g4a", "g4b", "g5", "g6", "g7", "g8", "g9", "g10", "g11"],
      ["g5", "g6", "g7"],
      ["g1", "g2", "g3", "g4a", "g4b", "g5", "g6", "g7"],
      ["g1", "g2", "g3", "g4a", "g4b"],
      ["g1", "g2", "g3"],
      ["g1", "g2", "g3", "g4a", "g4b"],
      ["g1", "g2", "g3", "g4a", "g4b", "g5", "g6", "g7"],
      ["g1", "g2", "g3", "g4a", "g4b", "g5", "g6", "g7", "g8"],
      ["g1", "g2", "g3", "g4a", "g4b", "g5", "g6", "g7", "g8", "g9", "g10", "g11"],
    ]
  end

  let(:expected_other_leaves) do
    [
      Set.new(["g1", "g11", "g2", "g3", "g4a", "g4b", "g5", "g6", "g7", "g8"]),
      Set.new(["g1", "g2", "g3", "g4a", "g4b", "g5", "g6", "g7", "g8"]),
      Set.new(["g1", "g10", "g11", "g2", "g3", "g4a", "g4b", "g7", "g8", "g9"]),
      Set.new(["g1", "g10", "g11", "g2", "g3", "g4a", "g4b", "g8", "g9"]),
      Set.new(["g1", "g10", "g11", "g2", "g3", "g5", "g6", "g7", "g8", "g9"]),
      Set.new(["g10", "g11", "g3", "g4a", "g4b", "g5", "g6", "g7", "g8", "g9"]),
      Set.new(["g10", "g11", "g4a", "g4b", "g5", "g6", "g7", "g8", "g9"]),
      Set.new(["g10", "g11", "g5", "g6", "g7", "g8", "g9"]),
      Set.new(["g10", "g11", "g8", "g9"]),
      Set.new(["g10", "g11", "g9"]),
    ]
  end

  let(:expected_non_parent_leaves) do
    expected_parent_leaves.map { |leaves| Set.new(all_taxa - leaves) }
  end

  it "has a version number" do
    expect(TreeClusters::VERSION).not_to be nil
  end

  describe "#all_clades" do
    context "with block given" do
      it "yields all the clades" do
        expect { |b| klass.all_clades(tree, &b) }.
          to yield_successive_args(*expected_clades)
      end
    end

    context "with no block given" do
      it "returns an Enumerator" do
        expect(klass.all_clades tree).to be_an Enumerator
      end

      it "returns an Enumerator with proper yield args" do
        enum = klass.all_clades tree

        expect { |b| enum.each &b  }.
          to yield_successive_args(*expected_clades)
      end
    end
  end

  describe TreeClusters::Clade do
    describe "::new" do
      it "generates clade with proper name" do
        expect(expected_clades.map(&:name)).
          to eq expected_names
      end

      it "generates clade with proper all_leaves" do
        expect(expected_clades.map(&:all_leaves)).
          to eq expected_all_leaves
      end

      it "generates clade with proper left_leaves" do
        expect(expected_clades.map(&:left_leaves)).
          to eq expected_left_leaves
      end

      it "generates clade with proper right_leaves" do
        expect(expected_clades.map(&:right_leaves)).
          to eq expected_right_leaves
      end

      it "generates clade with proper all_sibling_leaves" do
        expect(expected_clades.map(&:all_sibling_leaves)).
          to eq expected_all_sibling_leaves
      end

      it "generates clade with proper parent_leaves" do
        expect(expected_clades.map(&:parent_leaves)).
          to eq expected_parent_leaves
      end

      it "generates clade with proper other_leaves" do
        expect(expected_clades.map(&:other_leaves)).
          to eq expected_other_leaves
      end

      it "generates clade with proper non_parent_leaves" do
        expect(expected_clades.map(&:non_parent_leaves)).
          to eq expected_non_parent_leaves
      end
    end

    context "when tree is non bifurcating" do
      it "doesn't set left_leaves" do
        expect(non_bifurcating_clades.map(&:left_leaves)).
          to all be_nil
      end

      it "doesn't set right_leaves" do
        expect(non_bifurcating_clades.map(&:right_leaves)).
          to all be_nil
      end

      it "gives all the sibling leaves" do
        expect(non_bifurcating_clades.map(&:all_sibling_leaves)).
          to eq non_bifurcating_all_sibling_leaves
      end

      it "gives each set of sibling leaves" do
        expect(non_bifurcating_clades.map(&:each_sibling_leaf_set)).
          to eq non_bifurcating_each_sibling_leaf_set
      end
    end
  end

  describe TreeClusters::Attrs do
    let(:attrs) { TreeClusters::Attrs.new }

    it "inherits from Hash" do
      expect(TreeClusters::Attrs.new).to be_a Hash
    end

    describe "#add" do
      context "leaf is already in the hash" do
        it "adds new info into the hash" do
          attrs.add "g1", :aln, "A-T"
          attrs.add "g1", :genes, Set.new([1,2])
          expected_attrs =
            { "g1" => { aln: "A-T", genes: Set.new([1,2]) } }
          expect(attrs).to eq expected_attrs
        end
      end

      context "leaf is not yet in the hash" do
        it "adds new info to the hash" do
          attrs.add "g1", :aln, "A-T"
          expected_attrs = { "g1" => { aln: "A-T" } }
          expect(attrs).to eq expected_attrs
        end
      end
    end

    describe "#attrs" do
      it "gets attributes for a set of genomes" do
        attrs["g1"] = {
          genes: Set.new([1,2,3,4]),
          location: Set.new(["Delaware", "PA"])
        }

        attrs["g2"] = {
          genes: Set.new([1,2,4,5]),
          location: Set.new(["Delaware", "Maine"])
        }

        expect(attrs.attrs ["g1", "g2"], :genes).
          to eq TreeClusters::AttrArray.new [Set.new([1,2,3,4]),
                                             Set.new([1,2,4,5])]
      end

      it "returns an AttrArray" do
        attrs["g1"] = {
          genes: Set.new([1,2,3,4]),
          location: Set.new(["Delaware", "PA"])
        }

        expect(attrs.attrs ["g1"], :genes).
          to be_a TreeClusters::AttrArray
      end

      context "when a genome is not present in the hash" do
        it "skips it and keeps going" do
          attrs["g1"] = {
            genes: Set.new([1,2,3,4]),
            location: Set.new(["Delaware", "PA"])
          }

          expect(attrs.attrs ["g1", "g2"], :genes).
            to eq TreeClusters::AttrArray.new [Set.new([1,2,3,4])]
        end
      end

      context "when selected attr is not present" do
        it "raises an error" do
          attrs["g1"] = {
            genes: Set.new([1,2,3,4]),
            location: Set.new(["Delaware", "PA"])
          }

          expect { attrs.attrs ["g1"], :apples }.
            to raise_error AbortIf::Exit
        end
      end
    end
  end

  describe TreeClusters::AttrArray do
    it "inherits from Object::Array" do
      expect(TreeClusters::AttrArray.new).to be_a Object::Array
    end

    describe "#union" do
      it "takes the union of all sets in the array" do
        ary = TreeClusters::AttrArray.new [Set.new([1,2,3]),
                                           Set.new([2,3,4])]
        expect(ary.union).to eq Set.new([1,2,3,4])
      end
    end

    describe "#intersection" do
      it "takes the intersection of all sets in the array" do
        ary = TreeClusters::AttrArray.new [Set.new([1,2,3]),
                                           Set.new([2,3,4])]
        expect(ary.intersection).to eq Set.new([2,3])
      end
    end
  end
end
