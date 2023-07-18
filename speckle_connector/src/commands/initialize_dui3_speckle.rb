# frozen_string_literal: true

require_relative 'command'
require_relative '../states/initial_state'
require_relative '../ui/legacy_binding'
require_relative '../ui/base_binding'
require_relative '../ui/test_binding'
require_relative '../actions/initialize_speckle'
require_relative '../observers/factory'

module SpeckleConnector
  module Commands
    # Command to initialize Speckle UI and register it to ui_controller.
    # This is the command where we show UI to user.
    class InitializeDUI3Speckle < Command
      SPECKLE_DUI3 = 'speckle_dui3'

      def dialog_title
        "Speckle #{CONNECTOR_VERSION}"
      end

      private

      def _run
        app = self.app
        if !app.state.instance_of?(States::InitialState) && app.ui_controller.user_interfaces[SPECKLE_DUI3]
          dialog = app.ui_controller.user_interfaces[SPECKLE_DUI3]
          dialog.show
          return
        end

        initialize_speckle_dui3(app)
      end

      # Do the actual Speckle initialization.
      # rubocop:disable Naming/VariableNumber
      def initialize_speckle_dui3(app)
        # TODO: Initialize here speckle states and observers.
        observer_handler = Observers::Factory.create_handler(app)
        app.add_observer_handler!(observer_handler)
        observers = Observers::Factory.create_observers(observer_handler)
        app.update_state!(Actions::InitializeSpeckle, observers)
        dialog_specs = {
          dialog_id: SPECKLE_DUI3,
          dialog_title: dialog_title,
          height: 950,
          width: 300
        }
        base_binding = Ui::BaseBinding.new(app, Ui::BASE_BINDING_NAME)
        test_bindings = Ui::TestBinding.new(app, Ui::TEST_BINDINGS_NAME)

        dui3_dialog = SpeckleConnector::Ui::DUI3Dialog.new(**dialog_specs)
        dui3_dialog.bindings[Ui::BASE_BINDING_NAME] = base_binding
        dui3_dialog.bindings[Ui::TEST_BINDINGS_NAME] = test_bindings
        app.ui_controller.register_ui(SPECKLE_DUI3, dui3_dialog)
        dui3_dialog.show
      end
      # rubocop:enable Naming/VariableNumber
    end
  end
end
