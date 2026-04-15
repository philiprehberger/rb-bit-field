# philiprehberger-bit_field

[![Tests](https://github.com/philiprehberger/rb-bit-field/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-bit-field/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-bit_field.svg)](https://rubygems.org/gems/philiprehberger-bit_field)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-bit-field)](https://github.com/philiprehberger/rb-bit-field/commits/main)

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

### Group Queries

```ruby
perms = Permissions.new(:read)
perms.group_any_set?(:read_write)   # => true  (read is set)
perms.group_none_set?(:read_write)  # => false

perms = Permissions.new(:execute)
perms.group_any_set?(:read_write)   # => false (neither read nor write)
perms.group_none_set?(:read_write)  # => true
```

### Counting Flags

```ruby
perms = Permissions.new(:read, :write)
perms.count_set   # => 2
perms.count_clear # => 1

perms.set(:execute)
perms.count_set   # => 3
perms.count_clear # => 0
```

### Flag Diff

```ruby
before = Permissions.new(:read, :write)
after  = Permissions.new(:write, :execute)

after.added_flags(before)    # => [:execute]
after.removed_flags(before)  # => [:read]
```

### Strict Mode

```ruby
Permissions.strict(:read, :write)   # => works normally
Permissions.strict(:read, :admin)   # => raises Philiprehberger::BitField::Error
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
| `.strict(*flags)` | Create an instance, raising on unknown flags |
| `#flag_set?(flag)` | Check if a flag is set |
| `#flag_clear?(flag)` | Check if a flag is not set |
| `#count_set` | Return the number of flags currently set |
| `#count_clear` | Return the number of flags currently clear |
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
| `#group_any_set?(name)` | Check if any flag in a group is set |
| `#group_none_set?(name)` | Check if no flags in a group are set |
| `#added_flags(other)` | Return flags set in self but not in other |
| `#removed_flags(other)` | Return flags set in other but not in self |
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

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/rb-bit-field)

🐛 [Report issues](https://github.com/philiprehberger/rb-bit-field/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/rb-bit-field/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)
