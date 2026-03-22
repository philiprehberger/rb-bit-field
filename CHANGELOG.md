# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-03-22

### Added

- Initial release
- DSL for defining named flags at bit positions via `flag :name, position`
- Predicate methods for each flag (`read?`, `write?`, etc.)
- `set`, `clear`, and `toggle` operations
- Bitwise OR, AND, and XOR between same-type bit fields
- Integer serialization via `to_i` and `from_i`
- Array of set flags via `to_a`
- Comparable support for ordering by integer value
- Inheritance of flag definitions
