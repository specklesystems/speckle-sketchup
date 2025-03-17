# frozen_string_literal: true

require_relative 'command'
require_relative '../ui/dui3_dialog'
require_relative '../states/initial_state'
require_relative '../ui/bindings/accounts_binding'
require_relative '../ui/bindings/base_binding'
require_relative '../ui/bindings/send_binding'
require_relative '../ui/bindings/receive_binding'
require_relative '../ui/bindings/selection_binding'
require_relative '../ui/test_binding'
require_relative '../ui/bindings/config_binding'
require_relative '../ui/sketchup_config_binding'
require_relative '../actions/initialize_speckle'
require_relative '../observers/factory'

module SpeckleConnector3
  module Commands
    # Command to initialize Speckle UI and register it to ui_controller.
    # This is the command where we show UI to user.
    class InitializeDUI3Speckle < Command
      SPECKLE_DUI3 = 'speckle_dui3'

      def dialog_title
        "Speckle (Beta) for SketchUp"
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
        app.update_state!(Actions::InitializeSpeckle, observers, app.method(:instant_message_sender))
        dialog_specs = {
          dialog_id: SPECKLE_DUI3,
          dialog_title: dialog_title,
          height: 950,
          width: 300
        }
        # Init bindings
        base_binding = Ui::BaseBinding.new(app, Ui::BASE_BINDING_NAME)
        accounts_binding = Ui::AccountsBinding.new(app, Ui::ACCOUNTS_BINDING_NAME)
        send_binding = Ui::SendBinding.new(app, Ui::SEND_BINDING_NAME)
        receive_binding = Ui::ReceiveBinding.new(app, Ui::RECEIVE_BINDING_NAME)
        selection_binding = Ui::SelectionBinding.new(app, Ui::SELECTION_BINDING_NAME)
        test_bindings = Ui::TestBinding.new(app, Ui::TEST_BINDINGS_NAME)
        config_bindings = Ui::ConfigBinding.new(app, Ui::CONFIG_BINDING_NAME)
        connector_config_bindings = Ui::SketchupConfigBinding.new(app, Ui::CONNECTOR_CONFIG_BINDING_NAME)

        # Init dialog
        dui3_dialog = SpeckleConnector3::Ui::DUI3Dialog.new(**dialog_specs)

        # Register bindings to dialog
        dui3_dialog.bindings[Ui::BASE_BINDING_NAME] = base_binding
        dui3_dialog.bindings[Ui::ACCOUNTS_BINDING_NAME] = accounts_binding
        dui3_dialog.bindings[Ui::SEND_BINDING_NAME] = send_binding
        dui3_dialog.bindings[Ui::RECEIVE_BINDING_NAME] = receive_binding
        dui3_dialog.bindings[Ui::TEST_BINDINGS_NAME] = test_bindings
        dui3_dialog.bindings[Ui::CONFIG_BINDING_NAME] = config_bindings
        dui3_dialog.bindings[Ui::CONNECTOR_CONFIG_BINDING_NAME] = connector_config_bindings
        dui3_dialog.bindings[Ui::SELECTION_BINDING_NAME] = selection_binding

        app.ui_controller.register_ui(SPECKLE_DUI3, dui3_dialog)
        dui3_dialog.show
      end
      # rubocop:enable Naming/VariableNumber
    end
  end
end
