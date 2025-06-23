# frozen_string_literal: true

require_relative '../action'
require_relative '../../convertors/to_native'
require_relative '../../convertors/to_native_v2'

module SpeckleConnector3
  module Actions
    # Receive from server.
    class AfterGetObjects < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id, model_card_id, source_application, root_obj)
        model_card = state.speckle_state.receive_cards[model_card_id]
        state.sketchup_state.sketchup_model.start_operation('Receive Speckle Objects', true)
        # TODO: CONVERTER_V2: Remove later if statement and make V2 default.
        # FIXME: we will figure it out root commit structure later. It is hacky now.
        converter = Converters::ToNativeV2.new(state,
                                               root_obj['instanceDefinitionProxies'] || [],
                                               root_obj['renderMaterialProxies'] || [],
                                               root_obj['levelProxies'] || [],
                                               source_application,
                                               model_card)
        start_time = Time.now.to_f
        # Have side effects on the sketchup model. It effects directly on the entities by adding new objects.
        state = converter.receive_commit_object(root_obj)
        if state.user_state.model_preferences[:merge_coplanar_faces]
          Converters::CleanUp.merge_coplanar_faces(converter.converted_faces)
        end
        elapsed_time = (Time.now.to_f - start_time).round(3)
        state.sketchup_state.sketchup_model.commit_operation
        puts "==== Converting to Native executed in #{elapsed_time} sec ===="
        puts "==== Source application is #{@source_app}. ===="

        # Where we send info about received top level (for the sake of handling with less) objects.
        top_objects = converter.converted_entities.reject(&:deleted?).select { |e| e.parent.is_a?(Sketchup::Model) }
        top_object_ids = top_objects.collect(&:persistent_id).collect(&:to_s)
        args = {
          modelCardId: model_card_id,
          bakedObjectIds: top_object_ids,
          conversionResults: converter.conversion_results
        }

        # TODO: set here bakedObjectIds when we get rid of patching model as post receive action.

        receive_result_js_script = "receiveBinding.emit('setModelReceiveResult', #{args.to_json})"
        state = state.with_add_queue_js_command('setModelReceiveResult', receive_result_js_script)

        resolve_js_script = "receiveBinding.receiveResponse('#{resolve_id}')"
        state.with_add_queue_js_command('receive', resolve_js_script)
      end
    end
  end
end
