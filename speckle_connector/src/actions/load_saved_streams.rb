# frozen_string_literal: true

require_relative 'action'

module SpeckleConnector
  module Actions
    # Action to load saved streams.
    class LoadSavedStreams < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, _data)
        (saved_streams = state.sketchup_state.sketchup_model.attribute_dictionary('Speckle', true)['saved_streams']) or []
        state.with_add_queue('setSavedStreams', saved_streams, [])
      end
    end
  end
end
