# frozen_string_literal: true

require_relative 'lib/philiprehberger/bit_field/version'

Gem::Specification.new do |spec|
  spec.name          = 'philiprehberger-bit_field'
  spec.version       = Philiprehberger::BitField::VERSION
  spec.authors       = ['Philip Rehberger']
  spec.email         = ['me@philiprehberger.com']

  spec.summary       = 'Named bit flags with symbolic access, set operations, and serialization'
  spec.description   = 'Named bit flags with a DSL for defining flags at bit positions, symbolic read/set/clear/toggle, ' \
                       'flag groups, bulk operations, bitwise OR/AND/XOR, JSON/hash serialization, and Comparable support.'
  spec.homepage      = 'https://github.com/philiprehberger/rb-bit-field'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri']          = spec.homepage
  spec.metadata['source_code_uri']       = spec.homepage
  spec.metadata['changelog_uri']         = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['bug_tracker_uri']       = "#{spec.homepage}/issues"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*.rb', 'LICENSE', 'README.md', 'CHANGELOG.md']
  spec.require_paths = ['lib']
end
