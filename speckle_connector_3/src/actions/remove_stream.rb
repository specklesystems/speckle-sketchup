# frozen_string_literal: true

require_relative 'action'
require_relative '../accounts/accounts'
require_relative '../convertors/units'
require_relative '../convertors/converter'

module SpeckleConnector3
  module Actions
    # Action to remove stream.
    # Currently it is not a state changer.
    class RemoveStream < Action
      def initialize(stream_id)
        super()
        @stream_id = stream_id
      end

      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def update_state(state)
        speckle_dict = state.sketchup_state.sketchup_model.attribute_dictionary('Speckle', true)
        saved = speckle_dict['saved_streams'] || []
        saved -= [@stream_id]
        speckle_dict['saved_streams'] = saved
        state
      end
    end
  end
end
