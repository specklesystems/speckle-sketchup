# frozen_string_literal: true

require_relative 'command'
require_relative '../states/initial_state'
require_relative '../ui/vue_view'

module SpeckleConnector
  module Commands
    class InitializeSpeckle < Command
      def dialog_title
        "Speckle #{CONNECTOR_VERSION}"
      end

      private

      def _run
        app = self.app
        unless app.state.instance_of?(States::InitialState)
          vue_view = app.ui_controller.user_interfaces[Ui::SPECKLE_UI_ID]
          vue_view.show
          return
        end

        initialize_speckle(app)
      end

      # Do the actual Speckle initialization.
      def initialize_speckle(app)
        # TODO: Initialize here speckle states and observers.
        dialog_specs = {
          dialog_id: Ui::SPECKLE_UI_ID,
          htm_file: Ui::VUE_UI_HTML,
          dialog_title: dialog_title,
          height: 950,
          width: 300
        }
        vue_view = Ui::VueView.new(dialog_specs, app)
        app.ui_controller.register_ui(Ui::SPECKLE_UI_ID, vue_view)
        vue_view.show
      end
    end
  end
end
