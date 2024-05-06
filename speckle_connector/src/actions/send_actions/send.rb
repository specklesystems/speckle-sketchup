# frozen_string_literal: true

require_relative '../action'
require_relative '../../accounts/accounts'
require_relative '../../convertors/units'
require_relative '../../convertors/to_speckle'
require_relative '../../operations/send'
require_relative '../../ext/TT_Lib2/progressbar'

module SpeckleConnector
  module Actions
    # Send to server.
    class Send < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id, model_card_id)
        model_card = state.speckle_state.send_cards[model_card_id]
        unless model_card.send_filter.selected_object_ids.any?
          resolve_js_script = "sendBinding.receiveResponse('#{resolve_id}')"
          state = state.with_add_queue_js_command('resolveSend', resolve_js_script)
          args = {
            modelCardId: model_card_id,
            error: 'No objects were found. Please update your send filter!'
          }
          js_script = "sendBinding.emit('setModelError', #{args.to_json})"
          return state.with_add_queue_js_command('setModelsError', js_script)
        end

        account = Accounts.get_account_by_id(model_card.account_id)
        converter = Converters::ToSpeckle.new(state, model_card.project_id, model_card.send_filter)
        new_speckle_state, base = converter.convert_entities_to_base(model_card.send_filter.selected_object_ids,
                                                                     state.user_state.preferences)
        id, total_children_count, batches, refs = converter.serialize(base, state.user_state.preferences)
        new_speckle_state = new_speckle_state.with_object_references(model_card.project_id, refs)
        new_speckle_state = new_speckle_state.with_empty_changed_object_ids

        puts("converted #{base.count} objects for stream #{model_card.project_id}")

        state = state.with_speckle_state(new_speckle_state)

        resolve_js_script = "sendBinding.receiveResponse('#{resolve_id}')"
        state = state.with_add_queue_js_command('send', resolve_js_script)
        args = {
          modelCardId: model_card_id,
          projectId: model_card.project_id,
          modelId: model_card.model_id,
          token: account['token'],
          serverUrl: account['serverInfo']['url'],
          accountId: model_card.account_id,
          message: model_card.message,
          sendObject: {
            id: id,
            totalChildrenCount: total_children_count,
            batches: batches
          }
        }
        js_script = "sendBinding.emit('sendViaBrowser', #{args.to_json})"
        state.with_add_queue_js_command('sendViaBrowser', js_script)
      end
    end
  end
end
