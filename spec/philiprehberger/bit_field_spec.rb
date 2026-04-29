# frozen_string_literal: true

require 'spec_helper'
require 'json'

RSpec.describe Philiprehberger::BitField do
  it 'has a version number' do
    expect(described_class::VERSION).not_to be_nil
  end
end

RSpec.describe Philiprehberger::BitField::Base do
  let(:permissions_class) do
    Class.new(described_class) do
      flag :read, 0
      flag :write, 1
      flag :execute, 2
    end
  end

  let(:grouped_class) do
    Class.new(described_class) do
      flag :read, 0
      flag :write, 1
      flag :execute, 2
      group :read_write, %i[read write]
      group :all_access, %i[read write execute]
    end
  end

  describe '.flag' do
    it 'defines a predicate method' do
      perms = permissions_class.new(:read)
      expect(perms.read?).to be true
      expect(perms.write?).to be false
    end

    it 'raises for duplicate flag names' do
      expect do
        Class.new(described_class) do
          flag :read, 0
          flag :read, 1
        end
      end.to raise_error(Philiprehberger::BitField::Error)
    end

    it 'raises for duplicate positions' do
      expect do
        Class.new(described_class) do
          flag :read, 0
          flag :write, 0
        end
      end.to raise_error(Philiprehberger::BitField::Error)
    end
  end

  describe '.flags' do
    it 'returns all defined flag names' do
      expect(permissions_class.flags).to eq(%i[read write execute])
    end
  end

  describe '.from_i' do
    it 'creates an instance from an integer' do
      perms = permissions_class.from_i(5) # 101 = read + execute
      expect(perms.read?).to be true
      expect(perms.write?).to be false
      expect(perms.execute?).to be true
    end

    it 'raises for negative values' do
      expect { permissions_class.from_i(-1) }.to raise_error(Philiprehberger::BitField::Error)
    end
  end

  describe '#initialize' do
    it 'sets the given flags' do
      perms = permissions_class.new(:read, :write)
      expect(perms.read?).to be true
      expect(perms.write?).to be true
      expect(perms.execute?).to be false
    end

    it 'starts with no flags when none given' do
      perms = permissions_class.new
      expect(perms.to_i).to eq(0)
    end
  end

  describe '#set' do
    it 'sets a flag' do
      perms = permissions_class.new
      perms.set(:write)
      expect(perms.write?).to be true
    end

    it 'raises for unknown flags' do
      perms = permissions_class.new
      expect { perms.set(:admin) }.to raise_error(Philiprehberger::BitField::Error)
    end
  end

  describe '#clear' do
    it 'clears a flag' do
      perms = permissions_class.new(:read, :write)
      perms.clear(:write)
      expect(perms.write?).to be false
      expect(perms.read?).to be true
    end
  end

  describe '#toggle' do
    it 'toggles a flag on' do
      perms = permissions_class.new
      perms.toggle(:read)
      expect(perms.read?).to be true
    end

    it 'toggles a flag off' do
      perms = permissions_class.new(:read)
      perms.toggle(:read)
      expect(perms.read?).to be false
    end
  end

  describe '#to_i' do
    it 'returns the integer representation' do
      perms = permissions_class.new(:read, :execute)
      expect(perms.to_i).to eq(5) # 101
    end
  end

  describe '#to_binary_string' do
    it 'returns a string of zeros equal to the flag count when no flags are set' do
      perms = permissions_class.new
      expect(perms.to_binary_string).to eq('000')
    end

    it 'returns a string of ones equal to the flag count when all flags are set' do
      perms = permissions_class.new(:read, :write, :execute)
      expect(perms.to_binary_string).to eq('111')
    end

    it 'defaults to a width equal to the declared flag count' do
      perms = permissions_class.new(:read)
      expect(perms.to_binary_string.length).to eq(permissions_class.flags.size)
    end

    it 'pads the output to a given width when larger than natural length' do
      perms = permissions_class.new(:read, :execute)
      expect(perms.to_binary_string(width: 8)).to eq('00000101')
    end

    it 'does not truncate when width is smaller than natural length' do
      perms = permissions_class.new(:read, :write, :execute)
      expect(perms.to_binary_string(width: 1)).to eq('111')
    end

    it 'represents set flags MSB-first' do
      perms = permissions_class.new(:read, :execute)
      expect(perms.to_binary_string).to eq('101')
    end
  end

  describe '#to_a' do
    it 'returns set flag names' do
      perms = permissions_class.new(:read, :execute)
      expect(perms.to_a).to eq(%i[read execute])
    end
  end

  describe '#flags' do
    it 'returns all defined flag names' do
      perms = permissions_class.new
      expect(perms.flags).to eq(%i[read write execute])
    end
  end

  describe 'bitwise operations' do
    it 'performs OR' do
      a = permissions_class.new(:read)
      b = permissions_class.new(:write)
      result = a | b
      expect(result.to_a).to eq(%i[read write])
    end

    it 'performs AND' do
      a = permissions_class.new(:read, :write)
      b = permissions_class.new(:write, :execute)
      result = a & b
      expect(result.to_a).to eq([:write])
    end

    it 'performs XOR' do
      a = permissions_class.new(:read, :write)
      b = permissions_class.new(:write, :execute)
      result = a ^ b
      expect(result.to_a).to eq(%i[read execute])
    end

    it 'raises for different types' do
      other_class = Class.new(described_class) { flag :x, 0 }
      a = permissions_class.new(:read)
      b = other_class.new(:x)
      expect { a | b }.to raise_error(Philiprehberger::BitField::Error)
    end
  end

  describe 'Comparable' do
    it 'compares by integer value' do
      a = permissions_class.new(:read) # 1
      b = permissions_class.new(:read, :write) # 3
      expect(a).to be < b
    end

    it 'considers equal values equal' do
      a = permissions_class.new(:read, :write)
      b = permissions_class.new(:read, :write)
      expect(a).to eq(b)
    end
  end

  describe 'inheritance' do
    it 'inherits flags from parent class' do
      child_class = Class.new(permissions_class) do
        flag :admin, 3
      end
      child = child_class.new(:read, :admin)
      expect(child.read?).to be true
      expect(child.admin?).to be true
      expect(child.to_i).to eq(9) # 1001
    end

    it 'does not affect parent class' do
      Class.new(permissions_class) { flag :admin, 3 }
      expect(permissions_class.flags).to eq(%i[read write execute])
    end

    it 'inherits groups from parent class' do
      child_class = Class.new(grouped_class) do
        flag :admin, 3
      end
      expect(child_class.groups).to include(:read_write)
    end

    it 'does not affect parent groups' do
      child_class = Class.new(grouped_class) do
        flag :admin, 3
        group :admin_group, [:admin]
      end
      expect(child_class.groups).to have_key(:admin_group)
      expect(grouped_class.groups).not_to have_key(:admin_group)
    end
  end

  describe 'toggle specific bits' do
    it 'toggles multiple bits in sequence' do
      perms = permissions_class.new
      perms.toggle(:read).toggle(:write).toggle(:read)
      expect(perms.read?).to be false
      expect(perms.write?).to be true
    end
  end

  describe 'count set bits' do
    it 'counts zero flags when none set' do
      perms = permissions_class.new
      expect(perms.to_a.length).to eq(0)
    end

    it 'counts all flags when all set' do
      perms = permissions_class.new(:read, :write, :execute)
      expect(perms.to_a.length).to eq(3)
    end
  end

  describe 'all bits set/cleared' do
    it 'has all bits set' do
      perms = permissions_class.new(:read, :write, :execute)
      expect(perms.to_i).to eq(7) # 111
    end

    it 'has all bits cleared' do
      perms = permissions_class.new
      expect(perms.to_i).to eq(0)
    end
  end

  describe 'boundary bits' do
    it 'handles bit 0 correctly' do
      bf_class = Class.new(described_class) { flag :zero, 0 }
      bf = bf_class.new(:zero)
      expect(bf.to_i).to eq(1)
      expect(bf.zero?).to be true
    end

    it 'handles high bit positions' do
      bf_class = Class.new(described_class) { flag :high, 31 }
      bf = bf_class.new(:high)
      expect(bf.to_i).to eq(2**31)
      expect(bf.high?).to be true
    end

    it 'raises for negative position' do
      expect do
        Class.new(described_class) { flag :neg, -1 }
      end.to raise_error(Philiprehberger::BitField::Error)
    end
  end

  describe 'to_i/from_i roundtrip' do
    it 'roundtrips through to_i and from_i' do
      perms = permissions_class.new(:read, :execute)
      restored = permissions_class.from_i(perms.to_i)
      expect(restored.to_a).to eq(perms.to_a)
      expect(restored.to_i).to eq(perms.to_i)
    end

    it 'roundtrips zero value' do
      perms = permissions_class.new
      restored = permissions_class.from_i(perms.to_i)
      expect(restored.to_a).to eq([])
    end

    it 'roundtrips all flags set' do
      perms = permissions_class.new(:read, :write, :execute)
      restored = permissions_class.from_i(perms.to_i)
      expect(restored.to_a).to eq(%i[read write execute])
    end
  end

  describe 'equality' do
    it 'considers same flags equal' do
      a = permissions_class.new(:read, :write)
      b = permissions_class.new(:read, :write)
      expect(a == b).to be true
    end

    it 'considers different flags not equal' do
      a = permissions_class.new(:read)
      b = permissions_class.new(:write)
      expect(a == b).to be false
    end

    it 'is not equal to non-BitField objects' do
      perms = permissions_class.new(:read)
      expect(perms == 1).to be false
    end

    it 'works as hash keys' do
      a = permissions_class.new(:read)
      b = permissions_class.new(:read)
      hash = { a => 'found' }
      expect(hash[b]).to eq('found')
    end
  end

  describe 'set is idempotent' do
    it 'does not change value when setting already-set flag' do
      perms = permissions_class.new(:read)
      perms.set(:read)
      expect(perms.to_i).to eq(1)
    end
  end

  describe 'clear is idempotent' do
    it 'does not change value when clearing already-cleared flag' do
      perms = permissions_class.new
      perms.clear(:read)
      expect(perms.to_i).to eq(0)
    end
  end

  # --- Flag Groups ---

  describe '.group' do
    it 'defines a named group of flags' do
      expect(grouped_class.groups).to eq(read_write: %i[read write], all_access: %i[read write execute])
    end

    it 'raises for duplicate group names' do
      expect do
        Class.new(described_class) do
          flag :read, 0
          flag :write, 1
          group :rw, %i[read write]
          group :rw, [:read]
        end
      end.to raise_error(Philiprehberger::BitField::Error, /group rw already defined/)
    end

    it 'raises for unknown flags in group' do
      expect do
        Class.new(described_class) do
          flag :read, 0
          group :bad, %i[read unknown]
        end
      end.to raise_error(Philiprehberger::BitField::Error, /unknown flag unknown/)
    end
  end

  describe '.groups' do
    it 'returns group definitions' do
      expect(grouped_class.groups).to be_a(Hash)
      expect(grouped_class.groups[:read_write]).to eq(%i[read write])
    end

    it 'returns empty hash when no groups defined' do
      expect(permissions_class.groups).to eq({})
    end
  end

  describe '#set_group' do
    it 'sets all flags in the group' do
      perms = grouped_class.new
      perms.set_group(:read_write)
      expect(perms.read?).to be true
      expect(perms.write?).to be true
      expect(perms.execute?).to be false
    end

    it 'raises for unknown group' do
      perms = grouped_class.new
      expect { perms.set_group(:nonexistent) }.to raise_error(Philiprehberger::BitField::Error, /unknown group/)
    end

    it 'returns self for chaining' do
      perms = grouped_class.new
      expect(perms.set_group(:read_write)).to be perms
    end
  end

  describe '#clear_group' do
    it 'clears all flags in the group' do
      perms = grouped_class.new(:read, :write, :execute)
      perms.clear_group(:read_write)
      expect(perms.read?).to be false
      expect(perms.write?).to be false
      expect(perms.execute?).to be true
    end

    it 'raises for unknown group' do
      perms = grouped_class.new
      expect { perms.clear_group(:nonexistent) }.to raise_error(Philiprehberger::BitField::Error, /unknown group/)
    end

    it 'returns self for chaining' do
      perms = grouped_class.new(:read, :write)
      expect(perms.clear_group(:read_write)).to be perms
    end
  end

  describe '#group_set?' do
    it 'returns true when all flags in the group are set' do
      perms = grouped_class.new(:read, :write)
      expect(perms.group_set?(:read_write)).to be true
    end

    it 'returns false when some flags in the group are not set' do
      perms = grouped_class.new(:read)
      expect(perms.group_set?(:read_write)).to be false
    end

    it 'returns false when no flags in the group are set' do
      perms = grouped_class.new
      expect(perms.group_set?(:read_write)).to be false
    end

    it 'raises for unknown group' do
      perms = grouped_class.new
      expect { perms.group_set?(:nonexistent) }.to raise_error(Philiprehberger::BitField::Error, /unknown group/)
    end

    it 'works with all_access group' do
      perms = grouped_class.new(:read, :write, :execute)
      expect(perms.group_set?(:all_access)).to be true
    end
  end

  # --- JSON Serialization ---

  describe '#to_json' do
    it 'returns a JSON string with flags and value' do
      perms = permissions_class.new(:read, :write)
      parsed = JSON.parse(perms.to_json)
      expect(parsed).to eq({ 'flags' => %w[read write], 'value' => 3 })
    end

    it 'returns empty flags array when no flags set' do
      perms = permissions_class.new
      parsed = JSON.parse(perms.to_json)
      expect(parsed).to eq({ 'flags' => [], 'value' => 0 })
    end

    it 'returns all flags when all set' do
      perms = permissions_class.new(:read, :write, :execute)
      parsed = JSON.parse(perms.to_json)
      expect(parsed).to eq({ 'flags' => %w[read write execute], 'value' => 7 })
    end
  end

  describe '#to_h' do
    it 'returns a hash with flags and value' do
      perms = permissions_class.new(:read, :write)
      expect(perms.to_h).to eq({ flags: %i[read write], value: 3 })
    end

    it 'returns empty flags when no flags set' do
      perms = permissions_class.new
      expect(perms.to_h).to eq({ flags: [], value: 0 })
    end
  end

  describe '.from_json' do
    it 'reconstructs a bit field from JSON' do
      json = '{"flags":["read","write"],"value":3}'
      perms = permissions_class.from_json(json)
      expect(perms.read?).to be true
      expect(perms.write?).to be true
      expect(perms.execute?).to be false
      expect(perms.to_i).to eq(3)
    end

    it 'roundtrips through to_json and from_json' do
      original = permissions_class.new(:read, :execute)
      restored = permissions_class.from_json(original.to_json)
      expect(restored.to_i).to eq(original.to_i)
      expect(restored.to_a).to eq(original.to_a)
    end

    it 'raises for invalid JSON' do
      expect { permissions_class.from_json('not json') }.to raise_error(JSON::ParserError)
    end

    it 'raises when value key is missing' do
      expect { permissions_class.from_json('{"flags":["read"]}') }.to raise_error(Philiprehberger::BitField::Error)
    end
  end

  describe '.from_h' do
    it 'reconstructs from a hash with string keys' do
      perms = permissions_class.from_h({ 'flags' => %w[read write], 'value' => 3 })
      expect(perms.to_i).to eq(3)
      expect(perms.read?).to be true
    end

    it 'reconstructs from a hash with symbol keys' do
      perms = permissions_class.from_h({ flags: %i[read write], value: 3 })
      expect(perms.to_i).to eq(3)
    end

    it 'roundtrips through to_h and from_h' do
      original = permissions_class.new(:write, :execute)
      restored = permissions_class.from_h(original.to_h)
      expect(restored.to_i).to eq(original.to_i)
      expect(restored.to_a).to eq(original.to_a)
    end

    it 'raises when value key is missing' do
      expect { permissions_class.from_h({ flags: [:read] }) }.to raise_error(Philiprehberger::BitField::Error)
    end
  end

  # --- Bulk Operations ---

  describe '#set_all' do
    it 'sets every defined flag' do
      perms = permissions_class.new
      perms.set_all
      expect(perms.read?).to be true
      expect(perms.write?).to be true
      expect(perms.execute?).to be true
      expect(perms.to_i).to eq(7)
    end

    it 'is idempotent' do
      perms = permissions_class.new(:read, :write, :execute)
      perms.set_all
      expect(perms.to_i).to eq(7)
    end

    it 'returns self for chaining' do
      perms = permissions_class.new
      expect(perms.set_all).to be perms
    end
  end

  describe '#clear_all' do
    it 'clears every defined flag' do
      perms = permissions_class.new(:read, :write, :execute)
      perms.clear_all
      expect(perms.read?).to be false
      expect(perms.write?).to be false
      expect(perms.execute?).to be false
      expect(perms.to_i).to eq(0)
    end

    it 'is idempotent' do
      perms = permissions_class.new
      perms.clear_all
      expect(perms.to_i).to eq(0)
    end

    it 'returns self for chaining' do
      perms = permissions_class.new(:read)
      expect(perms.clear_all).to be perms
    end
  end

  describe '#set_flags' do
    it 'sets multiple specific flags at once' do
      perms = permissions_class.new
      perms.set_flags(:read, :write, :execute)
      expect(perms.to_a).to eq(%i[read write execute])
    end

    it 'sets a subset of flags' do
      perms = permissions_class.new
      perms.set_flags(:read, :execute)
      expect(perms.read?).to be true
      expect(perms.write?).to be false
      expect(perms.execute?).to be true
    end

    it 'raises for unknown flags' do
      perms = permissions_class.new
      expect { perms.set_flags(:read, :admin) }.to raise_error(Philiprehberger::BitField::Error)
    end

    it 'returns self for chaining' do
      perms = permissions_class.new
      expect(perms.set_flags(:read)).to be perms
    end
  end

  describe '#clear_flags' do
    it 'clears multiple specific flags at once' do
      perms = permissions_class.new(:read, :write, :execute)
      perms.clear_flags(:read, :write)
      expect(perms.read?).to be false
      expect(perms.write?).to be false
      expect(perms.execute?).to be true
    end

    it 'raises for unknown flags' do
      perms = permissions_class.new(:read)
      expect { perms.clear_flags(:admin) }.to raise_error(Philiprehberger::BitField::Error)
    end

    it 'returns self for chaining' do
      perms = permissions_class.new(:read, :write)
      expect(perms.clear_flags(:read)).to be perms
    end
  end

  # --- Group Query Methods ---

  describe '#group_any_set?' do
    it 'returns true when all flags in the group are set' do
      perms = grouped_class.new(:read, :write)
      expect(perms.group_any_set?(:read_write)).to be true
    end

    it 'returns true when some flags in the group are set' do
      perms = grouped_class.new(:read)
      expect(perms.group_any_set?(:read_write)).to be true
    end

    it 'returns false when no flags in the group are set' do
      perms = grouped_class.new(:execute)
      expect(perms.group_any_set?(:read_write)).to be false
    end

    it 'returns false when no flags are set at all' do
      perms = grouped_class.new
      expect(perms.group_any_set?(:read_write)).to be false
    end

    it 'raises for unknown group' do
      perms = grouped_class.new
      expect { perms.group_any_set?(:nonexistent) }.to raise_error(Philiprehberger::BitField::Error, /unknown group/)
    end
  end

  describe '#group_none_set?' do
    it 'returns true when no flags in the group are set' do
      perms = grouped_class.new
      expect(perms.group_none_set?(:read_write)).to be true
    end

    it 'returns true when only flags outside the group are set' do
      perms = grouped_class.new(:execute)
      expect(perms.group_none_set?(:read_write)).to be true
    end

    it 'returns false when some flags in the group are set' do
      perms = grouped_class.new(:read)
      expect(perms.group_none_set?(:read_write)).to be false
    end

    it 'returns false when all flags in the group are set' do
      perms = grouped_class.new(:read, :write)
      expect(perms.group_none_set?(:read_write)).to be false
    end

    it 'raises for unknown group' do
      perms = grouped_class.new
      expect { perms.group_none_set?(:nonexistent) }.to raise_error(Philiprehberger::BitField::Error, /unknown group/)
    end
  end

  # --- Flag Diff ---

  describe '#added_flags' do
    it 'returns flags set in self but not in other' do
      a = permissions_class.new(:read, :write)
      b = permissions_class.new(:write)
      expect(a.added_flags(b)).to eq([:read])
    end

    it 'returns empty array when self has no extra flags' do
      a = permissions_class.new(:write)
      b = permissions_class.new(:read, :write)
      expect(a.added_flags(b)).to eq([])
    end

    it 'returns all flags when other has none' do
      a = permissions_class.new(:read, :write, :execute)
      b = permissions_class.new
      expect(a.added_flags(b)).to eq(%i[read write execute])
    end

    it 'raises for different bit field types' do
      other_class = Class.new(described_class) { flag :x, 0 }
      a = permissions_class.new(:read)
      b = other_class.new(:x)
      expect { a.added_flags(b) }.to raise_error(Philiprehberger::BitField::Error)
    end
  end

  describe '#removed_flags' do
    it 'returns flags set in other but not in self' do
      a = permissions_class.new(:write)
      b = permissions_class.new(:read, :write)
      expect(a.removed_flags(b)).to eq([:read])
    end

    it 'returns empty array when other has no extra flags' do
      a = permissions_class.new(:read, :write)
      b = permissions_class.new(:write)
      expect(a.removed_flags(b)).to eq([])
    end

    it 'returns all flags when self has none' do
      a = permissions_class.new
      b = permissions_class.new(:read, :write, :execute)
      expect(a.removed_flags(b)).to eq(%i[read write execute])
    end

    it 'raises for different bit field types' do
      other_class = Class.new(described_class) { flag :x, 0 }
      a = permissions_class.new(:read)
      b = other_class.new(:x)
      expect { a.removed_flags(b) }.to raise_error(Philiprehberger::BitField::Error)
    end
  end

  describe '#subset_of?' do
    it 'returns true when self is empty' do
      a = permissions_class.new
      b = permissions_class.new(:read, :write)
      expect(a.subset_of?(b)).to be true
    end

    it 'returns true when self is identical to other' do
      a = permissions_class.new(:read, :write)
      b = permissions_class.new(:read, :write)
      expect(a.subset_of?(b)).to be true
    end

    it 'returns true when self is a strict subset of other' do
      a = permissions_class.new(:read)
      b = permissions_class.new(:read, :write)
      expect(a.subset_of?(b)).to be true
    end

    it 'returns false when self is a superset of other' do
      a = permissions_class.new(:read, :write)
      b = permissions_class.new(:read)
      expect(a.subset_of?(b)).to be false
    end

    it 'raises ArgumentError for different bit field types' do
      other_class = Class.new(described_class) { flag :x, 0 }
      a = permissions_class.new(:read)
      b = other_class.new(:x)
      expect { a.subset_of?(b) }.to raise_error(ArgumentError)
    end
  end

  # --- Strict Constructor ---

  describe '.strict' do
    it 'creates an instance with valid flags' do
      perms = permissions_class.strict(:read, :write)
      expect(perms.read?).to be true
      expect(perms.write?).to be true
    end

    it 'raises for unknown flag names' do
      expect { permissions_class.strict(:read, :admin) }.to raise_error(Philiprehberger::BitField::Error, /unknown flag/)
    end

    it 'creates an empty instance with no arguments' do
      perms = permissions_class.strict
      expect(perms.to_i).to eq(0)
    end
  end

  # --- Flag Clear ---

  describe '#flag_clear?' do
    it 'returns true when the flag is not set' do
      perms = permissions_class.new
      expect(perms.flag_clear?(:read)).to be true
    end

    it 'returns false when the flag is set' do
      perms = permissions_class.new(:read)
      expect(perms.flag_clear?(:read)).to be false
    end

    it 'is the negation of flag_set?' do
      perms = permissions_class.new(:read, :execute)
      permissions_class.flags.each do |f|
        expect(perms.flag_clear?(f)).to eq(!perms.flag_set?(f))
      end
    end

    it 'raises for unknown flags' do
      perms = permissions_class.new
      expect { perms.flag_clear?(:admin) }.to raise_error(Philiprehberger::BitField::Error)
    end
  end

  # --- Count Set / Count Clear ---

  describe '#count_set' do
    it 'returns 0 when no flags are set' do
      perms = permissions_class.new
      expect(perms.count_set).to eq(0)
    end

    it 'returns the number of flags set when some are set' do
      perms = permissions_class.new(:read, :execute)
      expect(perms.count_set).to eq(2)
    end

    it 'returns the total number of flags when all are set' do
      perms = permissions_class.new(:read, :write, :execute)
      expect(perms.count_set).to eq(3)
    end
  end

  describe '#count_clear' do
    it 'returns the total number of flags when none are set' do
      perms = permissions_class.new
      expect(perms.count_clear).to eq(3)
    end

    it 'returns the number of clear flags when some are set' do
      perms = permissions_class.new(:read)
      expect(perms.count_clear).to eq(2)
    end

    it 'returns 0 when all flags are set' do
      perms = permissions_class.new(:read, :write, :execute)
      expect(perms.count_clear).to eq(0)
    end

    it 'is consistent with count_set (count_set + count_clear == total)' do
      total = permissions_class.flags.size
      [
        permissions_class.new,
        permissions_class.new(:read),
        permissions_class.new(:read, :write),
        permissions_class.new(:read, :write, :execute)
      ].each do |perms|
        expect(perms.count_set + perms.count_clear).to eq(total)
      end
    end
  end
end
