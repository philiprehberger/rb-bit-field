# philiprehberger-bit_field

[![Tests](https://github.com/philiprehberger/rb-bit-field/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-bit-field/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-bit_field.svg)](https://rubygems.org/gems/philiprehberger-bit_field)
[![GitHub release](https://img.shields.io/github/v/release/philiprehberger/rb-bit-field)](https://github.com/philiprehberger/rb-bit-field/releases)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-bit-field)](https://github.com/philiprehberger/rb-bit-field/commits/main)
[![License](https://img.shields.io/github/license/philiprehberger/rb-bit-field)](LICENSE)
[![Bug Reports](https://img.shields.io/github/issues/philiprehberger/rb-bit-field/bug)](https://github.com/philiprehberger/rb-bit-field/issues?q=is%3Aissue+is%3Aopen+label%3Abug)
[![Feature Requests](https://img.shields.io/github/issues/philiprehberger/rb-bit-field/enhancement)](https://github.com/philiprehberger/rb-bit-field/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)
[![Sponsor](https://img.shields.io/badge/sponsor-GitHub%20Sponsors-ec6cb9)](https://github.com/sponsors/philiprehberger)

Named bit flags with symbolic access, set operations, and serialization

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-bit_field"
```

Or install directly:

```bash
gem install philiprehberger-bit_field
```

## Usage

```ruby
require "philiprehberger/bit_field"

class Permissions < Philiprehberger::BitField::Base
  flag :read, 0
  flag :write, 1
  flag :execute, 2
end

perms = Permissions.new(:read, :write)
perms.read?    # => true
perms.execute? # => false
```

### Setting and Clearing Flags

```ruby
perms.set(:execute)
perms.execute? # => true

perms.clear(:write)
perms.write? # => false

perms.toggle(:read)
perms.read? # => false
```

### Bulk Operations

```ruby
perms = Permissions.new
perms.set_all                          # set every flag
perms.clear_all                        # clear every flag
perms.set_flags(:read, :write)         # set specific flags
perms.clear_flags(:read, :write)       # clear specific flags
```

### Flag Groups

```ruby
class Permissions < Philiprehberger::BitField::Base
  flag :read, 0
  flag :write, 1
  flag :execute, 2
  group :read_write, [:read, :write]
end

perms = Permissions.new
perms.set_group(:read_write)
perms.group_set?(:read_write)  # => true
perms.clear_group(:read_write)
perms.group_set?(:read_write)  # => false
```

### Set Operations

```ruby
a = Permissions.new(:read, :write)
b = Permissions.new(:write, :execute)

(a | b).to_a # => [:read, :write, :execute]
(a & b).to_a # => [:write]
(a ^ b).to_a # => [:read, :execute]
```

### Serialization

```ruby
perms = Permissions.new(:read, :execute)
perms.to_i                  # => 5
perms.to_h                  # => { flags: [:read, :execute], value: 5 }
perms.to_json               # => '{"flags":["read","execute"],"value":5}'

Permissions.from_i(7).to_a  # => [:read, :write, :execute]
Permissions.from_json('{"flags":["read"],"value":1}')
Permissions.from_h({ flags: [:read], value: 1 })
```

## API

| Method | Description |
|--------|-------------|
| `flag :name, position` | Define a named flag at a bit position (DSL) |
| `group :name, [:flags]` | Define a named group of flags (DSL) |
| `.from_i(n)` | Create an instance from an integer |
| `.from_json(str)` | Create an instance from a JSON string |
| `.from_h(hash)` | Create an instance from a hash |
| `.flags` | Return all defined flag names |
| `.groups` | Return all defined group definitions |
| `#flag_set?(flag)` | Check if a flag is set |
| `#set(flag)` | Set a flag |
| `#clear(flag)` | Clear a flag |
| `#toggle(flag)` | Toggle a flag |
| `#set_all` | Set every defined flag |
| `#clear_all` | Clear every defined flag |
| `#set_flags(*flags)` | Set multiple specific flags at once |
| `#clear_flags(*flags)` | Clear multiple specific flags at once |
| `#set_group(name)` | Set all flags in a group |
| `#clear_group(name)` | Clear all flags in a group |
| `#group_set?(name)` | Check if all flags in a group are set |
| `#to_i` | Return the integer representation |
| `#to_a` | Return an array of set flag names |
| `#to_h` | Return a hash with flags and value |
| `#to_json` | Return a JSON string with flags and value |
| `#\|`, `#&`, `#^` | Bitwise OR, AND, XOR operations |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Support

If you find this package useful, consider giving it a star on GitHub — it helps motivate continued maintenance and development.

[![LinkedIn](https://img.shields.io/badge/Philip%20Rehberger-LinkedIn-0A66C2?logo=linkedin)](https://www.linkedin.com/in/philiprehberger)
[![More packages](https://img.shields.io/badge/more-open%20source%20packages-blue)](https://philiprehberger.com/open-source-packages)

## License

[MIT](LICENSE)
