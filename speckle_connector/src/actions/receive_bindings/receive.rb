# frozen_string_literal: true

require_relative '../action'
require_relative '../../accounts/accounts'
require_relative '../../convertors/units'
require_relative '../../convertors/to_speckle'
require_relative '../../operations/send'

module SpeckleConnector
  module Actions
    # Receive from server.
    class Receive < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id, model_card_id)
        model_card = state.speckle_state.receive_cards[model_card_id]
        resolve_js_script = "receiveBinding.receiveResponse('#{resolve_id}')"
        state = state.with_add_queue_js_command('receive', resolve_js_script)
        args = {
          modelCardId: model_card_id,
          projectId: model_card.project_id,
          accountId: model_card.account_id,
          modelId: model_card.model_id,
          selectedVersionId: model_card.selected_version_id
        }
        js_script = "receiveBinding.emit('receiveViaBrowser', #{args.to_json})"
        state.with_add_queue_js_command('receiveViaBrowser', js_script)
      end
    end
  end
end
