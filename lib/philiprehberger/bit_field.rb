# frozen_string_literal: true

require 'json'
require_relative 'bit_field/version'

module Philiprehberger
  module BitField
    class Error < StandardError; end

    # Named bit flags with symbolic access, set operations, and serialization
    #
    # @example
    #   class Permissions < Philiprehberger::BitField::Base
    #     flag :read, 0
    #     flag :write, 1
    #     flag :execute, 2
    #     group :read_write, [:read, :write]
    #   end
    #   perms = Permissions.new(:read, :write)
    #   perms.read?    # => true
    #   perms.execute? # => false
    class Base
      include Comparable

      class << self
        # Define a named flag at the given bit position
        #
        # @param name [Symbol] the flag name
        # @param position [Integer] the bit position (0-based)
        # @return [void]
        def flag(name, position)
          raise Error, 'position must be a non-negative integer' unless position.is_a?(Integer) && position >= 0
          raise Error, "flag #{name} already defined" if flags_map.key?(name)
          raise Error, "position #{position} already used" if flags_map.any? { |_, p| p == position }

          flags_map[name] = position

          define_method(:"#{name}?") do
            flag_set?(name)
          end
        end

        # Define a named group of flags
        #
        # @param name [Symbol] the group name
        # @param flag_names [Array<Symbol>] the flags in this group
        # @return [void]
        def group(name, flag_names)
          raise Error, "group #{name} already defined" if groups_map.key?(name)

          flag_names.each do |f|
            raise Error, "unknown flag #{f} in group #{name}" unless flags_map.key?(f)
          end

          groups_map[name] = flag_names.dup.freeze
        end

        # Return all defined flag names
        #
        # @return [Array<Symbol>]
        def flags
          flags_map.keys
        end

        # Return all defined group definitions
        #
        # @return [Hash{Symbol => Array<Symbol>}]
        def groups
          groups_map.dup
        end

        # Create an instance that raises on unknown flag names
        #
        # @param initial_flags [Array<Symbol>] flags to set initially
        # @return [Base]
        # @raise [Error] if any flag name is not defined
        def strict(*initial_flags)
          initial_flags.each do |f|
            raise Error, "unknown flag: #{f}" unless flags_map.key?(f)
          end

          new(*initial_flags)
        end

        # Create an instance from an integer value
        #
        # @param value [Integer] the integer representation
        # @return [Base]
        def from_i(value)
          raise Error, 'value must be a non-negative integer' unless value.is_a?(Integer) && value >= 0

          instance = new
          instance.instance_variable_set(:@value, value)
          instance
        end

        # Create an instance from a JSON string
        #
        # @param json_string [String] JSON with "flags" and "value" keys
        # @return [Base]
        def from_json(json_string)
          data = JSON.parse(json_string)
          from_h(data)
        end

        # Create an instance from a hash
        #
        # @param hash [Hash] hash with :flags/:value or "flags"/"value" keys
        # @return [Base]
        def from_h(hash)
          value = hash[:value] || hash['value']
          raise Error, 'hash must include a value key' if value.nil?

          from_i(value)
        end

        # @api private
        def flags_map
          @flags_map ||= {}
        end

        # @api private
        def groups_map
          @groups_map ||= {}
        end

        # @api private
        def inherited(subclass)
          super
          subclass.instance_variable_set(:@flags_map, flags_map.dup)
          subclass.instance_variable_set(:@groups_map, groups_map.dup)
        end
      end

      # Create a new bit field with the given flags set
      #
      # @param initial_flags [Array<Symbol>] flags to set initially
      # @return [Base]
      def initialize(*initial_flags)
        @value = 0
        initial_flags.each { |f| set(f) }
      end

      # Check if a flag is set
      #
      # @param flag [Symbol] the flag name
      # @return [Boolean]
      def flag_set?(flag)
        pos = position_for(flag)
        @value.anybits?(1 << pos)
      end

      # Check if a flag is clear (not set)
      #
      # @param flag [Symbol] the flag name
      # @return [Boolean]
      def flag_clear?(flag)
        !flag_set?(flag)
      end

      # Return the number of flags currently set
      #
      # @return [Integer]
      def count_set
        self.class.flags.count { |f| flag_set?(f) }
      end

      # Return the number of flags currently clear
      #
      # @return [Integer]
      def count_clear
        self.class.flags.size - count_set
      end

      # Set a flag
      #
      # @param flag [Symbol] the flag name
      # @return [self]
      def set(flag)
        pos = position_for(flag)
        @value |= (1 << pos)
        self
      end

      # Clear a flag
      #
      # @param flag [Symbol] the flag name
      # @return [self]
      def clear(flag)
        pos = position_for(flag)
        @value &= ~(1 << pos)
        self
      end

      # Toggle a flag
      #
      # @param flag [Symbol] the flag name
      # @return [self]
      def toggle(flag)
        pos = position_for(flag)
        @value ^= (1 << pos)
        self
      end

      # Set all defined flags
      #
      # @return [self]
      def set_all
        self.class.flags.each { |f| set(f) }
        self
      end

      # Clear all defined flags
      #
      # @return [self]
      def clear_all
        @value = 0
        self
      end

      # Set multiple specific flags at once
      #
      # @param flag_names [Array<Symbol>] flags to set
      # @return [self]
      def set_flags(*flag_names)
        flag_names.each { |f| set(f) }
        self
      end

      # Clear multiple specific flags at once
      #
      # @param flag_names [Array<Symbol>] flags to clear
      # @return [self]
      def clear_flags(*flag_names)
        flag_names.each { |f| clear(f) }
        self
      end

      # Set all flags in a group
      #
      # @param group_name [Symbol] the group name
      # @return [self]
      def set_group(group_name)
        group_flags(group_name).each { |f| set(f) }
        self
      end

      # Clear all flags in a group
      #
      # @param group_name [Symbol] the group name
      # @return [self]
      def clear_group(group_name)
        group_flags(group_name).each { |f| clear(f) }
        self
      end

      # Check if all flags in a group are set
      #
      # @param group_name [Symbol] the group name
      # @return [Boolean]
      def group_set?(group_name)
        group_flags(group_name).all? { |f| flag_set?(f) }
      end

      # Check if any flag in a group is set
      #
      # @param group_name [Symbol] the group name
      # @return [Boolean]
      def group_any_set?(group_name)
        group_flags(group_name).any? { |f| flag_set?(f) }
      end

      # Check if no flags in a group are set
      #
      # @param group_name [Symbol] the group name
      # @return [Boolean]
      def group_none_set?(group_name)
        group_flags(group_name).none? { |f| flag_set?(f) }
      end

      # Return the integer representation
      #
      # @return [Integer]
      def to_i
        @value
      end

      # Return the field as a binary string (MSB-first)
      #
      # By default the string is padded with leading zeros to the declared
      # flag count. If +width+ is given and larger than the natural length,
      # the string is padded to that width. If +width+ is smaller than the
      # natural length, the full representation is returned without
      # truncation to preserve correctness.
      #
      # @param width [Integer, nil] optional explicit width
      # @return [String]
      def to_binary_string(width: nil)
        bits = self.class.flags.size
        effective_width = width || bits
        to_i.to_s(2).rjust(effective_width, '0')
      end

      # Return an array of set flag names
      #
      # @return [Array<Symbol>]
      def to_a
        self.class.flags.select { |f| flag_set?(f) }
      end

      # Return all defined flag names
      #
      # @return [Array<Symbol>]
      def flags
        self.class.flags
      end

      # Return a hash representation
      #
      # @return [Hash{Symbol => Object}]
      def to_h
        { flags: to_a, value: @value }
      end

      # Return a JSON string representation
      #
      # @return [String]
      def to_json(*_args)
        { flags: to_a.map(&:to_s), value: @value }.to_json
      end

      # Bitwise OR
      #
      # @param other [Base] another bit field of the same type
      # @return [Base]
      def |(other)
        raise Error, 'cannot combine different bit field types' unless other.is_a?(self.class)

        self.class.from_i(@value | other.to_i)
      end

      # Bitwise AND
      #
      # @param other [Base] another bit field of the same type
      # @return [Base]
      def &(other)
        raise Error, 'cannot combine different bit field types' unless other.is_a?(self.class)

        self.class.from_i(@value & other.to_i)
      end

      # Bitwise XOR
      #
      # @param other [Base] another bit field of the same type
      # @return [Base]
      def ^(other)
        raise Error, 'cannot combine different bit field types' unless other.is_a?(self.class)

        self.class.from_i(@value ^ other.to_i)
      end

      # Compare by integer value
      #
      # @param other [Base] another bit field
      # @return [Integer, nil]
      def <=>(other)
        return nil unless other.is_a?(self.class)

        @value <=> other.to_i
      end

      # Equality check
      #
      # @param other [Base] another bit field
      # @return [Boolean]
      def ==(other)
        other.is_a?(self.class) && @value == other.to_i
      end

      # Hash code for use in Hash keys
      #
      # @return [Integer]
      def hash
        [self.class, @value].hash
      end

      # Return flags set in self but not in other
      #
      # @param other [Base] another bit field of the same type
      # @return [Array<Symbol>]
      def added_flags(other)
        raise Error, 'cannot compare different bit field types' unless other.is_a?(self.class)

        self.class.flags.select { |f| flag_set?(f) && !other.flag_set?(f) }
      end

      # Return flags set in other but not in self
      #
      # @param other [Base] another bit field of the same type
      # @return [Array<Symbol>]
      def removed_flags(other)
        raise Error, 'cannot compare different bit field types' unless other.is_a?(self.class)

        self.class.flags.select { |f| !flag_set?(f) && other.flag_set?(f) }
      end

      # Check whether every flag set in self is also set in `other`.
      #
      # @param other [Base] another instance of the same BitField subclass
      # @return [Boolean]
      # @raise [ArgumentError] when `other` is not the same BitField subclass
      def subset_of?(other)
        raise ArgumentError, "expected #{self.class}, got #{other.class}" unless other.is_a?(self.class)

        other.to_i.allbits?(to_i)
      end

      alias eql? ==

      private

      def position_for(flag)
        pos = self.class.flags_map[flag]
        raise Error, "unknown flag: #{flag}" unless pos

        pos
      end

      def group_flags(group_name)
        flags_list = self.class.groups_map[group_name]
        raise Error, "unknown group: #{group_name}" unless flags_list

        flags_list
      end
    end
  end
end
