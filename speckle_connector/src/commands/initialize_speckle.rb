# frozen_string_literal: true

require_relative 'command'
require_relative '../states/initial_state'
require_relative '../ui/legacy_binding'
require_relative '../actions/initialize_speckle'
require_relative '../observers/factory'

module SpeckleConnector
  module Commands
    # Command to initialize old Speckle UI and register it to ui_controller.
    # This is the command where we show UI to user.
    class InitializeSpeckle < Command
      SPECKLE_LEGACY_UI = 'speckle_legacy_ui'

      def dialog_title
        "Speckle #{CONNECTOR_VERSION}"
      end

      private

      def _run
        app = self.app
        if !app.state.instance_of?(States::InitialState) && app.ui_controller.user_interfaces[SPECKLE_LEGACY_UI]
          vue_view = app.ui_controller.user_interfaces[SPECKLE_LEGACY_UI]
          vue_view.show
          return
        end

        initialize_speckle_legacy_view(app)
      end

      # Do the actual Speckle initialization.
      def initialize_speckle_legacy_view(app)
        # TODO: Initialize here speckle states and observers.
        observer_handler = Observers::Factory.create_handler(app)
        app.add_observer_handler!(observer_handler)
        observers = Observers::Factory.create_observers(observer_handler)
        app.update_state!(Actions::InitializeSpeckle, observers)
        dialog_specs = {
          dialog_id: SPECKLE_LEGACY_UI,
          htm_file: Ui::VUE_UI_HTML,
          dialog_title: dialog_title,
          height: 950,
          width: 300
        }
        legacy_ui_dialog = SpeckleConnector::Ui::Dialog.new(**dialog_specs)
        legacy_binding = Ui::LegacyBinding.new(app, 'legacy_ui')
        legacy_ui_dialog.bindings[Ui::SPECKLE_LEGACY_BINDING_NAME] = legacy_binding
        app.ui_controller.register_ui(SPECKLE_LEGACY_UI, legacy_ui_dialog)
        legacy_ui_dialog.show
      end
    end
  end
end
