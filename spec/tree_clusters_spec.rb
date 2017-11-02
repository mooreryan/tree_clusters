# coding: utf-8
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

  describe "#consensus" do
    it "returns the most frequent element of the collection" do
      ary = %w[a A a A t t C C]

      expect(klass.consensus ary).to eq "A"
    end

    context "with ties" do
      it "returns the most frequent tied one closest to the end" do
        ary = %w[a c T t C t g]

        expect(klass.consensus ary).to eq "T"
      end
    end
  end

  let(:leaf2attrs) do
    TreeClusters::Attrs[
      "a-1"   => { aln: %w[A A A A] },
      "a-2"   => { aln: %w[A A A T] },
      "b-1"   => { aln: %w[C C C C] },
      "b-2"   => { aln: %w[c c c T] },
      "bb-1"  => { aln: %w[C C T G] },
      "bbb-1" => { aln: %w[C C G g] },
      "bbb-2" => { aln: %w[C G G G] },
    ]
  end

  describe "#read_alignment" do
    it "reads an alignment" do
      aln_fname = File.join test_file_dir, "small.aln"

      expect(klass.read_alignment aln_fname).to eq leaf2attrs
    end

    context "when the alns are not all same length" do
      it "raises an error" do
        aln_fname = File.join test_file_dir, "bad.aln"

        expect { klass.read_alignment aln_fname }.
          to raise_error AbortIf::Exit
      end
    end
  end

  describe "#check_ids" do
    it "checks that all IDs match in the tree, mapping, and aln files" do
      aln = File.join test_file_dir, "small.aln"
      mapping = File.join test_file_dir, "small.mapping"
      tree = File.join test_file_dir, "small.tre"

      expect(klass.check_ids tree, mapping, aln).to be true
    end

    context "when mapping file has wrong ids" do
      it "raises error" do
        aln = File.join test_file_dir, "small.aln"
        mapping = File.join test_file_dir, "small_mapping_bad_ids"
        tree = File.join test_file_dir, "small.tre"

        expect { klass.check_ids tree, mapping, aln }.
          to raise_error AbortIf::Exit
      end
    end

    context "when aln file has wrong ids" do
      it "raises error" do
        aln = File.join test_file_dir, "small_aln_bad_ids"
        mapping = File.join test_file_dir, "small.mapping"
        tree = File.join test_file_dir, "small.tre"

        expect { klass.check_ids tree, mapping, aln }.
          to raise_error AbortIf::Exit
      end
    end

    context "when tree file has wrong ids" do
      it "raises error" do
        aln = File.join test_file_dir, "small.aln"
        mapping = File.join test_file_dir, "small.mapping"
        tree = File.join test_file_dir, "small_tree_bad_ids"

        expect { klass.check_ids tree, mapping, aln }.
          to raise_error AbortIf::Exit
      end
    end
  end

  describe "#low_ent_cols" do
    it "returns low entropy columns given leaves and attrs" do
      entropy_cutoff = 0
      leaves = %w[b-1 b-2]

      expect(klass.low_ent_cols leaves, leaf2attrs, entropy_cutoff).
        to eq Set.new([1, 2, 3])
    end

    it "ignores columns if there is a gap regardless of entropy" do
      leaf2attrs = TreeClusters::Attrs[
        "a" => { aln: %w[A - T] },
        "b" => { aln: %w[a a c] }
      ]
      leaves = %w[a b]
      entropy_cutoff = 1

      expect(klass.low_ent_cols leaves, leaf2attrs, entropy_cutoff).
        to eq Set.new([1, 3])
    end
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

  let(:metadata) do
    {
      "coolness"   => { "a-1"   => "cool",
                        "a-2"   => "cool",
                        "b-1"   => "notcool",
                        "b-2"   => "notcool",
                        "bb-1"  => "notcool",
                        "bbb-1" => "notcool",
                        "bbb-2" => "notcool", },
      "snazzyness" => { "a-1"   => "snazzy",
                        "a-2"   => "snazzy",
                        "b-1"   => "snazzy",
                        "b-2"   => "snazzy",
                        "bb-1"  => "notsnazzy",
                        "bbb-1" => "notsnazzy",
                        "bbb-2" => "notsnazzy", },
      "sillyness"  => { "a-1"   => "1",
                        "a-2"   => "7",
                        "b-1"   => "3",
                        "b-2"   => "4",
                        "bb-1"  => "5",
                        "bbb-1" => "1",
                        "bbb-2" => "7", },
      "jauntiness" => { "a-1"   => "jaunty",
                        "a-2"   => "notjaunty",
                        "b-1"   => "jaunty",
                        "b-2"   => "notjaunty",
                        "bb-1"  => "notjaunty",
                        "bbb-1" => "jaunty",
                        "bbb-2" => "jaunty", },
      "oddness"    => { "a-1"   => "quite odd",
                        "a-2"   => "quite odd",
                        "b-1"   => "not odd",
                        "b-2"   => "not odd",
                        "bb-1"  => "not odd",
                        "bbb-1" => "rather odd",
                        "bbb-2" => "rather odd", },
    }
  end
  let(:small_tree_fname) do
    File.join test_file_dir, "small.tre"
  end
  let(:small_tree) do
    NewickTree.fromFile small_tree_fname
  end
  # The order is B3, B2, B1, B, A
  let(:small_tree_clades) do
    klass.all_clades small_tree, metadata
  end

  # A clade is a single tag clade for a metadata category if all
  # leaves in the clade have the same metadata tag for that metadata
  # category.
  let(:small_tree_single_tag_info) do
    [  # B3
      { "coolness"   => "notcool",
        "snazzyness" => "notsnazzy",
        "sillyness"  => nil,
        "jauntiness" => "jaunty",
        "oddness"    => "rather odd" },
      # B2
      { "coolness"   => "notcool",
        "snazzyness" => "notsnazzy",
        "sillyness"  => nil,
        "jauntiness" => nil,
        "oddness"    => nil },
      # B1
      { "coolness"   => "notcool",
        "snazzyness" => "snazzy",
        "sillyness"  => nil,
        "jauntiness" => nil,
        "oddness"    => "not odd" },
      # B
      { "coolness"   => "notcool",
        "snazzyness" => nil,
        "sillyness"  => nil,
        "jauntiness" => nil,
        "oddness"    => nil },
      # A
      { "coolness"   => "cool",
        "snazzyness" => "snazzy",
        "sillyness"  => nil,
        "jauntiness" => nil,
        "oddness"    => "quite odd" },
    ]
  end
  let(:small_tree_deepest_single_tag_clades) do
    {
      "cluster_B" => { "coolness" => "notcool" },
      "cluster_B1" => { "snazzyness" => "snazzy",
                        "oddness" => "not odd" },
      "cluster_B2" => { "snazzyness" => "notsnazzy" },
      "cluster_B3" => { "jauntiness" => "jaunty",
                        "oddness" => "rather odd" },
      "cluster_A" => { "coolness" => "cool",
                       "snazzyness" => "snazzy",
                       "oddness" => "quite odd" }
    }
  end
  # snazzy_clades only has clades which are snazzy and the tags with
  # which they are snazzy in contrast to all tags for a particular
  # clade
  let(:small_tree_snazzy_clades) do
    { "cluster_B3" =>
      { "oddness"    => "rather odd" },

      "cluster_B2" =>
      { "snazzyness" => "notsnazzy" },

      "cluster_B" =>
      { "coolness"   => "notcool" },

      "cluster_A" =>
      { "coolness"   => "cool",
        "oddness"    => "quite odd" },
    }
  end
  let(:small_tree_all_tags) do
    [  # B3
      { "coolness"   => Set.new(["notcool"]),
        "snazzyness" => Set.new(["notsnazzy"]),
        "sillyness"  => Set.new(["1", "7"]),
        "jauntiness" => Set.new(["jaunty"]),
        "oddness"    => Set.new(["rather odd"])},
      # B2
      { "coolness"   => Set.new(["notcool"]),
        "snazzyness" => Set.new(["notsnazzy"]),
        "sillyness"  => Set.new(["1", "5", "7"]),
        "jauntiness" => Set.new(["jaunty", "notjaunty"]),
        "oddness"    => Set.new(["not odd", "rather odd"])},
      # B1
      { "coolness"   => Set.new(["notcool"]),
        "snazzyness" => Set.new(["snazzy"]),
        "sillyness"  => Set.new(["3", "4"]),
        "jauntiness" => Set.new(["jaunty", "notjaunty"]),
        "oddness"    => Set.new(["not odd"])},
      # B
      { "coolness"   => Set.new(["notcool"]),
        "snazzyness" => Set.new(["snazzy", "notsnazzy"]),
        "sillyness"  => Set.new(["1", "3", "4", "5", "7"]),
        "jauntiness" => Set.new(["jaunty", "notjaunty"]),
        "oddness"    => Set.new(["not odd", "rather odd"])},
      # A
      { "coolness"   => Set.new(["cool"]),
        "snazzyness" => Set.new(["snazzy"]),
        "sillyness"  => Set.new(["1", "7"]),
        "jauntiness" => Set.new(["jaunty", "notjaunty"]),
        "oddness"    => Set.new(["quite odd"])},
    ]
  end
  let(:mapping_file) { File.join test_file_dir, "small.mapping" }

  describe "#read_mapping_file" do
    it "reads the mapping file" do
      expect(klass.read_mapping_file mapping_file).to eq metadata
    end

    it "returns an instance of Attrs" do
      expect(klass.read_mapping_file mapping_file).
        to be_a TreeClusters::Attrs
    end
  end

  let(:small_attrs_file) do
    File.join test_file_dir, "small.attrs"
  end
  let(:small_leaf2attrs) do
    # Note: can handle other chars like ñ
    TreeClusters::Attrs[
      "a-1"   => { "color"  => Set.new(%w[rojo]),
                   "fruta"  => Set.new(%w[manzana pera]),
                   "tamaño" => Set.new },
      "a-2"   => { "color"  => Set.new(%w[azul rojo]),
                   "fruta"  => Set.new(%w[manzana pera]),
                   "tamaño" => Set.new },
      "b-1"   => { "color"  => Set.new(%w[blanco]),
                   "fruta"  => Set.new(%w[pera]),
                   "tamaño" => Set.new },
      "b-2"   => { "color"  => Set.new(%w[blanco]),
                   "fruta"  => Set.new,
                   "tamaño" => Set.new },
      "bb-1"  => { "color"  => Set.new(%w[blanco]),
                   "fruta"  => Set.new,
                   "tamaño" => Set.new },
      "bbb-1" => { "color"  => Set.new(%w[blanco]),
                   "fruta"  => Set.new,
                   "tamaño" => Set.new(%w[pequeña]) },
      "bbb-2" => { "color"  => Set.new(%w[blanco gris]),
                   "fruta"  => Set.new,
                   "tamaño" => Set.new(%w[pequeña]) },
    ]
  end

  describe "#read_attrs_file" do
    it "reads the attributes file" do
      attr_categories = %w[color fruta tamaño]

      expect(klass.read_attrs_file small_attrs_file).
        to eq [attr_categories, small_leaf2attrs]
    end
  end

  # A clade is a snazzy clade if it is a single tag clade and also
  # that tag is not found outside of the clade.
  describe "#snazzy_clades" do
    it "returns the snazzy clade info" do
      # TODO the hash is keyed on a Clade but the test data has
      # clade.name. Cannot key the hash on clade.name because not all
      # clades have it.
      info = klass.snazzy_clades small_tree, metadata
      info_hash = info.
                  map { |clade, snazzy_info| [clade.name, snazzy_info] }.
                  to_h

      expect(info_hash).to eq small_tree_snazzy_clades
    end
  end

  # describe "#deepest_single_tag_clades" do
  #   it "returns the single tag clades, but only those not " +
  #      "contained within another clade single tag clade w.r.t. " +
  #      "to the same tag" do
  #     expect(klass.deepest_single_tag_clades small_tree, metadata).
  #       to eq small_tree_deepest_single_tag_clades
  #   end
  # end

  describe TreeClusters::Clade do
    describe "::new" do
      context "when given metadata" do
        it "sets single_tag_info" do
          expect(small_tree_clades.map(&:single_tag_info)).
            to eq small_tree_single_tag_info
        end

        it "sets all_tags" do
          expect(small_tree_clades.map(&:all_tags)).
            to eq small_tree_all_tags
        end
      end

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
