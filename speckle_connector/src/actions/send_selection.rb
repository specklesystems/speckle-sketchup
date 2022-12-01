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
        sketchup_model = state.sketchup_state.sketchup_model
        converter = Converters::ToSpeckle.new(sketchup_model)
        converted = converter.convert_selection
        base = {
          "speckle_type": 'Base'
        }.merge(converted)
        puts("converted #{converted.count} objects for stream #{@stream_id}")
        state.with_add_queue('convertedFromSketchup', @stream_id, [base.to_json])
      end
    end
  end
end
