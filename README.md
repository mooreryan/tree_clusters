# TreeClusters

[![Gem Version](https://badge.fury.io/rb/tree_clusters.svg)](http://badge.fury.io/rb/tree_clusters) [![Build Status](https://travis-ci.org/mooreryan/tree_clusters.svg?branch=master)](https://travis-ci.org/mooreryan/tree_clusters) [![Coverage Status](https://coveralls.io/repos/mooreryan/tree_clusters/badge.svg)](https://coveralls.io/r/mooreryan/tree_clusters)

Wanna do something with every cluster in a Newick tree? So do we!

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tree_clusters'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install tree_clusters

## Documentation

Checkout
[TreeClusters docs](http://rubydoc.info/gems/tree_clusters)
for the full api documentation.

## Usage

Here is a small example.

```ruby
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
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/tree_clusters. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Code of Conduct

Everyone interacting in the TreeClusters project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/tree_clusters/blob/master/CODE_OF_CONDUCT.md).
