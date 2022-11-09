# frozen_string_literal: true

require_relative 'command'
require_relative '../accounts/accounts'
require_relative '../convertors/units'
require_relative '../convertors/converter_sketchup'

module SpeckleConnector
  module Commands
    # Command to load saved streams.
    class LoadSavedStreams < Command
      def _run(_data)
        (saved_streams = Sketchup.active_model.attribute_dictionary('speckle', true)['streams']) or []
        view.dialog.execute_script("setSavedStreams(#{saved_streams})")
      end
    end
  end
end
