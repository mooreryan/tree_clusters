require "spec_helper"
require "fileutils"

def read_actual outdir, basename, which
  File.read(File.join(outdir, "#{basename}.tree_clusters.#{which}.txt"))
end

RSpec.describe "key_cols program" do
  let(:program) do
    File.join TreeClusters::PROJ_ROOT, "exe", "key_cols"
  end
  let(:cmd) do
    "#{program} --tree #{intre} --aln #{inaln} --outdir #{outdir} --base #{basename}"
  end

  let(:test_file_dir) do
    File.join TreeClusters::PROJ_ROOT, "test_files"
  end

  let(:expected_outdir_base) do
    File.join test_file_dir, "key_cols", "expected_output"
  end

  let(:expected_annotated_tree) do
    File.join exp_dir, "#{exp_base}.tree_clusters.annotated_tree.txt"
  end
  let(:expected_clade_members) do
    File.join exp_dir, "#{exp_base}.tree_clusters.clade_members.txt"
  end
  let(:expected_key_cols) do
    File.join exp_dir, "#{exp_base}.tree_clusters.key_cols.txt"
  end

  context "With small2.aln" do
    # Expected opts

    let(:exp_dir) do
      File.join expected_outdir_base, "small2"
    end
    let(:exp_base) { "ARST" }
    let(:actual) do

    end

    # Program opts
    let(:intre) do
      # small.tre is tree for both small.aln and small2.aln
      File.join test_file_dir, "small.tre"
    end
    let(:inaln) do
      File.join test_file_dir, "small2.aln"
    end
    let(:outdir) do
      File.join TreeClusters::PROJ_ROOT,
                "test_files/key_cols/output"
    end
    let(:basename) { "ARST" }

    before :each do
      FileUtils.rm_r(outdir) if Dir.exist?(outdir)

      puts `#{cmd}`
    end

    after :each do
      FileUtils.rm_r(outdir) if Dir.exist?(outdir)
    end

    it "gives the correct tree" do
      which = "annotated_tree"
      actual = read_actual outdir, basename, which
      expected = File.read expected_annotated_tree

      expect(actual).to eq expected
    end

    it "gives the correct clade members" do
      which = "clade_members"
      actual = read_actual outdir, basename, which
      expected = File.read expected_clade_members

      expect(actual).to eq expected
    end

    it "gives the correct key cols" do
      which = "key_cols"
      actual = read_actual outdir, basename, which
      expected = File.read expected_key_cols

      expect(actual).to eq expected
    end
  end
end