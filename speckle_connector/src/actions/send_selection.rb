# frozen_string_literal: true

require_relative 'action'
require_relative '../convertors/units'
require_relative '../convertors/to_speckle'

module SpeckleConnector
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
        converter = Converters::ToSpeckle.new(state)
        base = converter.convert_selection_to_base
        new_speckle_state, id, total_children_count, batches = converter.send_info(base)
        puts("converted #{base.count} objects for stream #{@stream_id}")
        new_state = state.with_speckle_state(new_speckle_state)
        new_state.with_add_queue('convertedFromSketchup', @stream_id, [
                               { is_string: false, val: batches },
                               { is_string: true, val: id },
                               { is_string: false, val: total_children_count }
                             ])
      end
    end
  end
end
