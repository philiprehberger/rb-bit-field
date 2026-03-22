# frozen_string_literal: true

require 'spec_helper'

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
      a = permissions_class.new(:read)           # 1
      b = permissions_class.new(:read, :write)    # 3
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
  end
end
