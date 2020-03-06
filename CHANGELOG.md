# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.1] - 2026-03-31

### Changed
- Standardize README badges, support section, and license format

## [0.2.0] - 2026-03-29

### Added
- Flag groups via class-level `group` DSL with `set_group`, `clear_group`, and `group_set?` instance methods
- JSON serialization with `to_json` and `ClassName.from_json(str)` class method
- Hash serialization with `to_h` and `ClassName.from_h(hash)` class method
- Bulk operations: `set_all`, `clear_all`, `set_flags(*flags)`, `clear_flags(*flags)`

## [0.1.1] - 2026-03-22

### Changed
- Expand test coverage from 25 to 42 examples

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
