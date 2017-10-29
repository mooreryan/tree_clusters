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

  let(:expected_clades) do
    [
      TreeClusters::Clade.new(tree.findNode("cluster19", exact: true), tree),
      TreeClusters::Clade.new(tree.findNode("cluster22", exact: true), tree),
      TreeClusters::Clade.new(tree.findNode("cluster11", exact: true), tree),
      TreeClusters::Clade.new(tree.findNode("cluster14", exact: true), tree),
      TreeClusters::Clade.new(tree.findNode("cluster7",  exact: true), tree),
      TreeClusters::Clade.new(tree.findNode("cluster1",  exact: true), tree),
      TreeClusters::Clade.new(tree.findNode("cluster4",  exact: true), tree),
      TreeClusters::Clade.new(tree.findNode("cluster6",  exact: true), tree),
      TreeClusters::Clade.new(tree.findNode("cluster10", exact: true), tree),
      TreeClusters::Clade.new(tree.findNode("cluster16", exact: true), tree),
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

  let(:expected_sibling_leaves) do
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

  it "has a version number" do
    expect(TreeClusters::VERSION).not_to be nil
  end

  describe "#all_clades" do
    it "returns all the clades" do
      expect(klass.all_clades tree).to eq expected_clades
    end
  end

  describe TreeClusters::Clade do
    describe "::new" do
      it "generates clade with proper name" do
        expect(expected_clades.map(&:name)).to eq expected_names
      end

      it "generates clade with proper all_leaves" do
        expect(expected_clades.map(&:all_leaves)).to eq expected_all_leaves
      end

      it "generates clade with proper left_leaves" do
        expect(expected_clades.map(&:left_leaves)).to eq expected_left_leaves
      end

      it "generates clade with proper right_leaves" do
        expect(expected_clades.map(&:right_leaves)).to eq expected_right_leaves
      end

      it "generates clade with proper sibling_leaves" do
        expect(expected_clades.map(&:sibling_leaves)).to eq expected_sibling_leaves
      end

      it "generates clade with proper parent_leaves" do
        expect(expected_clades.map(&:parent_leaves)).to eq expected_parent_leaves
      end

      it "generates clade with proper other_leaves" do
        expect(expected_clades.map(&:other_leaves)).to eq expected_other_leaves
      end
    end
  end

  describe TreeClusters::Attrs do
    let(:attrs) { TreeClusters::Attrs.new }

    it "inherits from Hash" do
      expect(TreeClusters::Attrs.new).to be_a Hash
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
          to eq [Set.new([1,2,3,4]), Set.new([1,2,4,5])]
      end
    end
  end

  describe TreeClusters::Array do
    it "inherits from Object::Array" do
      expect(TreeClusters::Array.new).to be_a Object::Array
    end

    describe "#union" do
      it "takes the union of all sets in the array" do
        ary = TreeClusters::Array.new [Set.new([1,2,3]), Set.new([2,3,4])]
        expect(ary.union).to eq Set.new([1,2,3,4])
      end
    end

    describe "#intersection" do
      it "takes the intersection of all sets in the array" do
        ary = TreeClusters::Array.new [Set.new([1,2,3]), Set.new([2,3,4])]
        expect(ary.intersection).to eq Set.new([2,3])
      end
    end
  end
end
