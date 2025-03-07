# frozen_string_literal: true

require_relative '../action'
require_relative '../../accounts/accounts'
require_relative '../../convertors/units'
require_relative '../../convertors/to_speckle_v2'
require_relative '../../operations/send'
require_relative '../../sketchup_model/definitions/definition_manager'
require_relative '../../sketchup_model/materials/material_manager'
require_relative '../../sketchup_model/colors/color_manager'

module SpeckleConnector3
  module Actions
    # Send to server.
    class Send < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id, model_card_id)
        # Set active path always to model to be safe always. Later we can address it
        start_time = Time.now.to_f
        state.sketchup_state.sketchup_model.active_path = nil
        units = Converters::SKETCHUP_UNITS[state.sketchup_state.length_units]
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

        entities = state.sketchup_state.sketchup_model.entities.select do |e|
          model_card.send_filter.selected_object_ids.any?(e.persistent_id.to_s)
        end

        unpacked_entities = SketchupModel::Definitions::DefinitionManager
                            .new(units)
                            .unpack_entities(entities)

        unpacked_materials = SketchupModel::Materials::MaterialManager.new.unpack_materials(entities)

        unpacked_colors = SketchupModel::Colors::ColorManager.new.unpack_colors(state.sketchup_state.sketchup_model)

        account = Accounts.get_account_by_id(model_card.account_id)
        converter = Converters::ToSpeckleV2.new(state, unpacked_entities, model_card)

        new_speckle_state, base = converter.convert_entities_to_base_blocks_poc

        base[:instanceDefinitionProxies] = unpacked_entities.instance_definition_proxies
        base[:renderMaterialProxies] = unpacked_materials
        base[:colorProxies] = unpacked_colors
        base[:units] = units

        elapsed_time = (Time.now.to_f - start_time).round(3)
        puts "==== Converting objects executed in #{elapsed_time} sec ===="

        start_time = Time.now.to_f

        sender_progress_args = {
          modelCardId: model_card_id,
          progress: {
            progress: nil,
            status: 'Serializing'
          }
        }
        state.instant_message_sender.call("sendBinding.emit('setModelProgress', #{sender_progress_args.to_json})")

        id, batches, refs = converter.serialize(base, state.user_state.preferences)
        elapsed_time = (Time.now.to_f - start_time).round(3)
        puts "==== Serializing objects executed in #{elapsed_time} sec ===="
        new_speckle_state = new_speckle_state.with_object_references(model_card.project_id, refs)
        new_speckle_state = new_speckle_state.with_empty_changed_entity_persistent_ids
        new_speckle_state = new_speckle_state.with_empty_changed_entity_ids

        puts "Cached/Total object: #{converter.cached_object_count}/#{converter.object_count}"

        puts("converted #{base.count} objects for stream #{model_card.project_id}")

        state = state.with_speckle_state(new_speckle_state)

        resolve_js_script = "sendBinding.receiveResponse('#{resolve_id}')"
        state = state.with_add_queue_js_command('send', resolve_js_script)
        # args = {
        #   modelCardId: model_card_id,
        #   projectId: model_card.project_id,
        #   modelId: model_card.model_id,
        #   token: account['token'],
        #   serverUrl: account['serverInfo']['url'],
        #   accountId: model_card.account_id,
        #   message: model_card.message,
        #   sendConversionResults: converter.conversion_results,
        #   sendObject: {
        #     id: id,
        #     batches: batches
        #   }
        # }
        # js_script = "sendBinding.emit('sendViaBrowser', #{args.to_json})"
        # state.with_add_queue_js_command('sendViaBrowser', js_script)

        # store conversion results in state to pick up later
        new_speckle_state = state.speckle_state.with_conversion_results(model_card_id, converter.conversion_results)
        state = state.with_speckle_state(new_speckle_state)

        total_batch_count = batches.count
        batches.each_with_index do |batch, i|
          current_batch = i + 1
          args = {
            modelCardId: model_card_id,
            projectId: model_card.project_id,
            token: account['token'],
            serverUrl: account['serverInfo']['url'],
            batch: batch,
            currentBatch:current_batch,
            totalBatch: total_batch_count,
            referencedObjectId: id
          }
          js_script = "sendBinding.emit('sendBatchViaBrowser', #{args.to_json})"
          state = state.with_add_queue_js_command("sendBatchViaBrowser_#{current_batch}", js_script)
        end
        state
      end
    end
  end
end
