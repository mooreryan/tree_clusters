# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "tree_clusters/version"

Gem::Specification.new do |spec|
  spec.name          = "tree_clusters"
  spec.version       = TreeClusters::VERSION
  spec.authors       = ["Ryan Moore"]
  spec.email         = ["moorer@udel.edu"]

  spec.summary       = %q{Snazzy code for working with each cluster in a tree.}
  spec.description   = spec.summary
  spec.homepage      = "https://github.com/mooreryan/tree_clusters"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2"

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "coveralls", "~> 0.8.21"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "yard", "~> 0.9.9"

  spec.add_runtime_dependency "abort_if", "~> 0.2.0"
  spec.add_runtime_dependency "newick-ruby", "~> 1.0", ">= 1.0.4"
  spec.add_runtime_dependency "trollop", "~> 2.1", ">= 2.1.2"
end
