# frozen_string_literal: true

require_relative '../action'
require_relative '../../sketchup_model/dictionary/model_card_dictionary_handler'

module SpeckleConnector3
  module Actions
    # Action to update send filter.
    class UpdateSendFilter < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id, data, value)
        SketchupModel::Dictionary::ModelCardDictionaryHandler.update_filter(state.sketchup_state.sketchup_model, data, value)

        js_script = "sendBinding.receiveResponse('#{resolve_id}')"
        state.with_add_queue_js_command('updateSendFilter', js_script)
      end
    end
  end
end
