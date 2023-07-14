# frozen_string_literal: true

require_relative '../action'

module SpeckleConnector
  module Actions
    # Test purpose action.
    class SayHi < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id, name, count, say_hello_not_hi)
        said_hi = []
        count.times do
          said_hi.append("#{say_hello_not_hi ? 'Hello' : 'Hi'} #{name}!")
        end
        js_script = "testBindings.receiveResponse('#{resolve_id}', #{said_hi})"
        state.with_add_queue_js_command('sayHi', js_script)
      end
    end
  end
end
