# frozen_string_literal: true

require_relative 'action'
require_relative '../convertors/units'
require_relative '../convertors/converter_sketchup'

module SpeckleConnector
  module Actions
    # Action to receive objects from Speckle Server.
    class ReceiveObjects < Action
      def initialize(stream_id, base)
        super()
        @stream_id = stream_id
        @base = base
      end

      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def update_state(state)
        converter = Converters::ConverterSketchup.new(state.sketchup_state.sketchup_model)
        converter.traverse_commit_object(@base)
        state.with_add_queue('finishedReceiveInSketchup', @stream_id, [])
      end
    end
  end
end
