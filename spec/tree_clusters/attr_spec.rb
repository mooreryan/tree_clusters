RSpec.describe TreeClusters::Attrs do
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
