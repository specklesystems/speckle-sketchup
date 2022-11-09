# frozen_string_literal: true

require_relative 'command'
require_relative '../convertors/units'
require_relative '../convertors/converter_sketchup'

module SpeckleConnector
  module Commands
    # Command to receive objects from Speckle Server.
    class ReceiveObjects < Command
      def _run(data)
        stream_id = data['stream_id']
        base = data['base']
        su_unit = Sketchup.active_model.options['UnitsOptions']['LengthUnit']
        unit = Converters::SKETCHUP_UNITS[su_unit]
        converter = Converters::ConverterSketchup.new(unit)
        converter.traverse_commit_object(base)
        view.dialog.execute_script("#{command_name}('#{stream_id}')")
      end
    end
  end
end
