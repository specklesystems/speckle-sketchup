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
        state.sketchup_state.sketchup_model.active_path = nil
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
          model_card.send_filter.selected_object_ids.any?(e.persistent_id)
        end

        unpacked_entities = SketchupModel::Definitions::DefinitionManager
                            .new(Converters::SKETCHUP_UNITS[state.sketchup_state.length_units])
                            .unpack_entities(entities)

        unpacked_materials = SketchupModel::Materials::MaterialManager.new.unpack_materials(entities)

        unpacked_colors = SketchupModel::Colors::ColorManager.new.unpack_colors(state.sketchup_state.sketchup_model)

        account = Accounts.get_account_by_id(model_card.account_id)
        converter = Converters::ToSpeckleV2.new(state, unpacked_entities, model_card)

        new_speckle_state, base = converter.convert_entities_to_base_blocks_poc

        base[:instanceDefinitionProxies] = unpacked_entities.instance_definition_proxies
        base[:renderMaterialProxies] = unpacked_materials
        base[:colorProxies] = unpacked_colors

        id, batches, refs = converter.serialize(base, state.user_state.preferences)
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
          sendConversionResults: converter.conversion_results,
          sendObject: {
            id: id,
            batches: batches
          }
        }
        js_script = "sendBinding.emit('sendViaBrowser', #{args.to_json})"
        state.with_add_queue_js_command('sendViaBrowser', js_script)
      end
    end
  end
end
