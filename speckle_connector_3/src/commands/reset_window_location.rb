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
        app.ui_controller.user_interfaces.values.each do |interface|
          interface.reset_dialog_location
        end
      end
    end
  end
end
