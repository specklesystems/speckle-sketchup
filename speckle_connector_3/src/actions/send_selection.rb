# frozen_string_literal: true

require_relative 'action'
require_relative 'deactivate_diffing'
require_relative '../convertors/units'
require_relative '../convertors/to_speckle'
require_relative '../operations/send'

module SpeckleConnector3
  module Actions
    # Send selection to server.
    class SendSelection < Action
      def initialize(stream_id)
        super()
        @stream_id = stream_id
      end

      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def update_state(state)
        state = DeactivateDiffing.update_state(state, nil, {})
        converter = Converters::ToSpeckle.new(state, @stream_id, {})
        new_speckle_state, base = converter.convert_selection_to_base
        id, batches = converter.serialize(base, state.user_state.preferences)
        # TODO: Later active send operation.
        # Operations.send(@stream_id, batches)

        puts("converted #{base.count} objects for stream #{@stream_id}")

        # This is the place we can send information to UI for diffing check
        diffing = state.user_state.preferences[:user][:diffing]
        new_speckle_state = new_speckle_state.with_invalid_streams_queue if diffing

        new_state = state.with_speckle_state(new_speckle_state)
        new_state.with_add_queue('convertedFromSketchup', @stream_id, [
                                   { is_string: false, val: batches },
                                   { is_string: true, val: id },
                                   { is_string: false, val: 0 }
                                 ])
      end
    end
  end
end
