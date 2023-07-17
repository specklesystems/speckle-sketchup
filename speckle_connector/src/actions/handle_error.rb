# frozen_string_literal: true

module SpeckleConnector
  module Actions
    # Action to return error message to UI.
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
        error_message = "Error: #{@error}\nBinding: #{@view_name}\nArgs: #{@args}\n"
        error = {
          error: error_message
        }
        js_error_script = "#{@view_name}.receiveResponse('#{@args.first}', #{error.to_json})"
        state.with_add_queue_js_command("error_#{@view_name}", js_error_script)
      end
    end
  end
end
