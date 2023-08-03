# frozen_string_literal: true

require_relative '../action'
require_relative '../../filters/send_filters'
require_relative '../../sketchup_model/dictionary/send_card_dictionary_handler'

module SpeckleConnector
  module Actions
    # Add model to document state.
    class AddModelToDocumentState < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id, model)
        puts model
        js_script = "baseBinding.receiveResponse('#{resolve_id}')"
        state.with_add_queue_js_command('addModelToDocumentState', js_script)
      end
    end
  end
end
