# frozen_string_literal: true

require_relative 'command'
require_relative '../states/initial_state'
require_relative '../ui/vue_view'
require_relative '../ui/dui3_view'
require_relative '../actions/initialize_speckle'
require_relative '../observers/factory'

module SpeckleConnector
  module Commands
    # Command to initialize Speckle UI and register it to ui_controller.
    # This is the command where we show UI to user.
    class InitializeDUI3Speckle < Command
      def dialog_title
        "Speckle #{CONNECTOR_VERSION}"
      end

      private

      def _run
        app = self.app
        if !app.state.instance_of?(States::InitialState) && app.ui_controller.user_interfaces[Ui::SPECKLE_DUI3_ID]
          vue_view = app.ui_controller.user_interfaces[Ui::SPECKLE_DUI3_ID]
          vue_view.show
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
          dialog_id: Ui::SPECKLE_DUI3_ID,
          dialog_title: dialog_title,
          height: 950,
          width: 300
        }
        dui3_view = Ui::DUI3View.new(dialog_specs, app)
        app.ui_controller.register_ui(Ui::SPECKLE_DUI3_ID, dui3_view)
        dui3_view.show
        dui3_view.init
      end
      # rubocop:enable Naming/VariableNumber
    end
  end
end
