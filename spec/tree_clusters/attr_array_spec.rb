require "spec_helper"

RSpec.describe TreeClusters::AttrArray do
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
