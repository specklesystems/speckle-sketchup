# frozen_string_literal: true

require_relative 'hash'
require_relative 'set'
require_relative 'vector'
# Add json conversion methods
require_relative 'json'

module SpeckleConnector
  module Immutable
    class Hash
      # Return a new {Set} containing the keys from this `Hash`.
      #
      # @example
      #   Immutable::Hash["A" => 1, "B" => 2, "C" => 3, "D" => 2].keys
      #   # => Immutable::Set["D", "C", "B", "A"]
      #
      # @return [Set]
      def keys
        Set.alloc(@trie)
      end

      # Return a new {Vector} populated with the values from this `Hash`.
      #
      # @example
      #   Immutable::Hash["A" => 1, "B" => 2, "C" => 3, "D" => 2].values
      #   # => Immutable::Vector[2, 3, 2, 1]
      #
      # @return [Vector]
      def values
        Vector.new(each_value.to_a.freeze)
      end
    end
  end
end
