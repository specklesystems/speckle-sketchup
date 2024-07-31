# frozen_string_literal: true

module SpeckleConnector3
  module Actions
    # Action to return error message to UI.
    # It is "TopLevelExceptionHandler" equivalent of C#.
    class HandleError < Action
      # @param error [String] error
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
        error_message = "Error: #{@error}\nBinding: #{@view_name}\nAction:#{@action}\nArgs: #{@args}\n"
        error = {
          error: error_message
        }
        global_notification = {
          type: 2,
          title: 'Host App Error',
          description: error
        }
        js_error_script = "#{@view_name}.receiveResponse('#{@args.first}', #{error.to_json})"
        new_state = state.with_add_queue_js_command("error_#{@view_name}", js_error_script)
        js_global_notification_script = "#{@view_name}.emit('setGlobalNotification', #{global_notification.to_json})"
        new_state.with_add_queue_js_command("global_notification_#{@view_name}", js_global_notification_script)
      end
    end
  end
end
