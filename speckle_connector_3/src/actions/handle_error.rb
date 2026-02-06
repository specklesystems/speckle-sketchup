# frozen_string_literal: true

module SpeckleConnector3
  module Actions
    # Action to return error message to UI.
    # It is "TopLevelExceptionHandler" equivalent of C#.
    class HandleError < Action
      # @return [StandardError] error
      attr_reader :error

      # @param error [StandardError] error
      # @param view_name [String] name of the view (binding)
      # @param action [Action] action that error happened
      # @param parameters [Array<String>] arguments
      def initialize(error, view_name, action, parameters)
        super()
        @error = error
        @view_name = view_name
        @action = action
        @args = parameters
      end

      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def update_state(state)
        # TODO: Log here when it is ready!!!
        host_app_error = {
          message: error.message,
          error: error,
          stackTrace: error.backtrace
        }
        
        js_error_script = "#{@view_name}.receiveResponse('#{@args.first}', #{host_app_error.to_json})"
        state.with_add_queue_js_command("error_#{@view_name}", js_error_script)
      end
    end
  end
end
