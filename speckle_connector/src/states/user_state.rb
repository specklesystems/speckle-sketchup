# frozen_string_literal: true

require_relative '../immutable/immutable'

module SpeckleConnector
  module States
    # User specific states.
    class UserState
      include Immutable::ImmutableUtils

      # @return [ImmutableHash{Symbol => Object}] user specific preferences
      attr_reader :preferences

      def initialize(preferences)
        @preferences = preferences
      end

      def with_preferences(new_preferences)
        with(:@preferences => new_preferences)
      end
    end
  end
end
