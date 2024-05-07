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
        converter = Converters::ToSpeckle.new(state, model_card.project_id, model_card.send_filter, model_card_id)
        new_speckle_state, base = converter.convert_entities_to_base(model_card.send_filter.selected_object_ids,
                                                                     state.user_state.preferences)
        id, total_children_count, batches, refs = converter.serialize(base, state.user_state.preferences)
        new_speckle_state = new_speckle_state.with_object_references(model_card.project_id, refs)
        new_speckle_state = new_speckle_state.with_empty_changed_entity_persistent_ids
        new_speckle_state = new_speckle_state.with_empty_changed_entity_ids

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

      def self.update_state_test(state, resolve_id, model_card_id)
        dialog = UI::HtmlDialog.new(
          {
            :dialog_title => 'Dialog Example',
            :preferences_key => 'com.sample.plugin',
            :scrollable => true,
            :resizable => true,
            :width => 600,
            :height => 400,
            :left => 10,
            :top => 10,
            :min_width => 50,
            :min_height => 50,
            :max_width =>1000,
            :max_height => 1000,
            :style => UI::HtmlDialog::STYLE_DIALOG
          })
        html = '<div id="hi"><b>Hello world!</b></div>'
        dialog.set_html(html)
        dialog.show

        action = Proc.new do |status|
          js_command = "document.getElementById('hi').innerHTML = '<b>#{status}</b>'"
          log_js_command = "console.log('test')"
          dialog.execute_script(js_command)
          dialog.execute_script(log_js_command)
        end

        selected_object_ids = state.sketchup_state.sketchup_model.selection.collect(&:persistent_id)
        state.worker.add_jobs(1000.times.to_a.map { |i| Job.new(i, &action) })
        state.worker.do_work(Time.now.to_f, &action)
      end
    end
  end
end
