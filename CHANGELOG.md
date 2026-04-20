# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.5.0] - 2026-04-19

### Added
- `#to_binary_string(width: nil)` — returns the field as a `"0"`/`"1"` string, MSB-first, padded to the declared flag count by default; accepts an explicit `width:`

## [0.4.0] - 2026-04-15

### Added
- `count_set` to return the number of flags currently set
- `count_clear` to return the number of flags currently clear

## [0.3.0] - 2026-04-14

### Added
- `group_any_set?(group)` to check if any flag in a named group is set
- `group_none_set?(group)` to check if no flags in a named group are set
- `added_flags(other)` to return flags set in self but not in other
- `removed_flags(other)` to return flags set in other but not in self
- `.strict(*flags)` constructor that raises on unknown flag names
- `flag_clear?(flag)` convenience negation of `flag_set?`

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
