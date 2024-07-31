# frozen_string_literal: true

require_relative 'command'
require_relative '../states/initial_state'
require_relative '../actions/initialize_speckle'
require_relative '../observers/factory'

module SpeckleConnector3
  module Commands
    # Command to reset Speckle UI window location onto center of SketchUp window.
    class ResetWindowLocation < Command

      private

      def _run
        app = self.app
        vue_view = app.ui_controller.user_interfaces[Ui::SPECKLE_LEGACY_UI]
        if vue_view
          vue_view.dialog.reset_dialog_location
        else
          puts "Speckle UI didn't initialized!"
        end
      end
    end
  end
end
