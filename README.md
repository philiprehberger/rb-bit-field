# philiprehberger-bit_field

[![Tests](https://github.com/philiprehberger/rb-bit-field/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-bit-field/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-bit_field.svg)](https://rubygems.org/gems/philiprehberger-bit_field)
[![License](https://img.shields.io/github/license/philiprehberger/rb-bit-field)](LICENSE)

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
Permissions.from_i(7).to_a  # => [:read, :write, :execute]
```

## API

| Method | Description |
|--------|-------------|
| `flag :name, position` | Define a named flag at a bit position (DSL) |
| `.from_i(n)` | Create an instance from an integer |
| `.flags` | Return all defined flag names |
| `#read?(flag)` | Check if a flag is set |
| `#set(flag)` | Set a flag |
| `#clear(flag)` | Clear a flag |
| `#toggle(flag)` | Toggle a flag |
| `#to_i` | Return the integer representation |
| `#to_a` | Return an array of set flag names |
| `#\|`, `#&`, `#^` | Bitwise OR, AND, XOR operations |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
