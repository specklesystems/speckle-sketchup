# frozen_string_literal: true

require_relative 'command'
require_relative '../convertors/units'
require_relative '../../converter/converter_sketchup'

module SpeckleConnector
  module Commands
    class SendSelection < Command
      def _run(data)
        stream_id = data['stream_id']
        su_unit = Sketchup.active_model.options['UnitsOptions']['LengthUnit']
        unit = Convertors::SKETCHUP_UNITS[su_unit]
        converter = SpeckleConnector::ConverterSketchup.new(unit)
        converted = Sketchup.active_model.selection.map { |entity| converter.convert_to_speckle(entity) }
        puts("converted #{converted.count} objects for stream #{stream_id}")
        view.dialog.execute_script("#{command_name}('#{stream_id}',#{converted.to_json})")
      end
    end
  end
end
