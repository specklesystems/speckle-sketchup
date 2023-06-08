# frozen_string_literal: true

require_relative 'action'
require_relative 'deactivate_diffing'
require_relative '../convertors/units'
require_relative '../convertors/to_speckle'

module SpeckleConnector
  module Actions
    # Cancel the operation.
    class CancelOperation < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, _data)
        state.ready = false
        state
      end
    end
  end
end
