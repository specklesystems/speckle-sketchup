# frozen_string_literal: true

require_relative '../action'
require_relative '../../accounts/accounts'
require_relative '../../convertors/units'
require_relative '../../convertors/to_speckle'
require_relative '../../operations/send'
require_relative '../../ext/TT_Lib2/progressbar'

module SpeckleConnector
  module Actions
    # Receive from server.
    class Receive < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id, model_card_id, source_application)
        model_card = state.speckle_state.receive_cards[model_card_id]
        account = Accounts.get_account_by_id(model_card.account_id)

        resolve_js_script = "receiveBinding.receiveResponse('#{resolve_id}')"
        state = state.with_add_queue_js_command('receive', resolve_js_script)
        args = {
          modelCardId: model_card_id,
          projectId: model_card.project_id,
          modelId: model_card.model_id,
          token: account['token'],
          serverUrl: account['serverInfo']['url'],
          accountId: model_card.account_id,
          objectId: model_card.object_id,
          sourceApplication: source_application
        }
        js_script = "receiveBinding.emit('receiveViaBrowser', #{args.to_json})"
        state.with_add_queue_js_command('receiveViaBrowser', js_script)
      end
    end
  end
end
