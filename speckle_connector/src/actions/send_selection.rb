# frozen_string_literal: true

require_relative 'action'
require_relative '../convertors/units'
require_relative '../convertors/converter_sketchup'

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
        su_unit = Sketchup.active_model.options['UnitsOptions']['LengthUnit']
        unit = Converters::SKETCHUP_UNITS[su_unit]
        converter = Converters::ConverterSketchup.new(unit)
        converted = Sketchup.active_model.selection.map { |entity| converter.convert_to_speckle(entity) }

        puts("converted #{converted.count} objects for stream #{@stream_id}")
        state.with_add_queue('convertedFromSketchup', @stream_id, [converted.to_json])
      end
    end
  end
end
