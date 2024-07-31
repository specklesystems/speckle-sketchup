# frozen_string_literal: true

module SpeckleConnector3
  module Actions
    # State changer object.
    class Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @param parameters [Array] parameters that the action takes
      # @return [States::State] the new updated state object
      def self.update_state(_state, *_parameters)
        raise NotImplementedError, 'Implement in subclass.'
      end
    end
  end
end
