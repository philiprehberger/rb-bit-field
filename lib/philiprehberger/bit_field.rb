# frozen_string_literal: true

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
          raise Error, "position must be a non-negative integer" unless position.is_a?(Integer) && position >= 0
          raise Error, "flag #{name} already defined" if flags_map.key?(name)
          raise Error, "position #{position} already used" if flags_map.any? { |_, p| p == position }

          flags_map[name] = position

          define_method(:"#{name}?") do
            flag_set?(name)
          end
        end

        # Return all defined flag names
        #
        # @return [Array<Symbol>]
        def flags
          flags_map.keys
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

        # @api private
        def flags_map
          @flags_map ||= {}
        end

        # @api private
        def inherited(subclass)
          super
          subclass.instance_variable_set(:@flags_map, flags_map.dup)
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
        (@value & (1 << pos)) != 0
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

      # Return the integer representation
      #
      # @return [Integer]
      def to_i
        @value
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

      alias eql? ==

      private

      def position_for(flag)
        pos = self.class.flags_map[flag]
        raise Error, "unknown flag: #{flag}" unless pos

        pos
      end
    end
  end
end
