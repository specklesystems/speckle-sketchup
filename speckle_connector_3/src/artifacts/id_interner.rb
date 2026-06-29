# frozen_string_literal: true

module SpeckleConnector3
  module Artifacts
    # First-seen dense-int interner: maps an opaque string key to a sequential
    # int32 id (0..N-1, insertion order). Mirrors the SDK `IdInterner`.
    class IdInterner
      def initialize
        @map = {}
      end

      # @return [Array(Boolean, Integer)] [is_new, id]
      def get_or_add(key)
        if @map.key?(key)
          [false, @map[key]]
        else
          id = @map.size
          @map[key] = id
          [true, id]
        end
      end

      # @return [Integer] the id (interning on first sight); ignores the is-new flag
      def id_for(key)
        _new, id = get_or_add(key)
        id
      end

      def size
        @map.size
      end
    end
  end
end
