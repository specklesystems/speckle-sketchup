# frozen_string_literal: true

require_relative 'render_material'
require_relative 'transform'
require_relative 'block_definition'
require_relative '../base'
require_relative '../geometry/bounding_box'
require_relative '../../sketchup_model/dictionary/dictionary_handler'

module SpeckleConnector
  module SpeckleObjects
    module Other
      # DisplayValue object definition for Speckle that represents as BlockInstance in Sketchup.
      class DisplayValue
        # Creates a component definition and instance from a speckle object with a display value
        # @param state [States::State] state of the application.
        def self.to_native(state, obj, layer, entities, stream_id, &convert_to_native)
          # Switch displayValue with geometry
          obj['geometry'] = obj['displayValue']
          obj['geometry'] += obj['elements'] unless obj['elements'].nil?

          new_state = BlockDefinition.to_native(
            state,
            obj,
            layer,
            entities,
            stream_id,
            &convert_to_native
          )

          definition = new_state.sketchup_state.sketchup_model.definitions[BlockDefinition.get_definition_name(obj)]

          BlockInstance.find_and_erase_existing_instance(definition, obj['id'], obj['applicationId'])
          t_arr = obj['transform']
          transform = t_arr.nil? ? Geom::Transformation.new : OTHER::Transform.to_native(t_arr, units)
          instance = entities.add_instance(definition, transform)
          instance.name = obj['name'] unless obj['name'].nil?
          display_value_to_speckle_entity(new_state, instance, obj, stream_id)
        end

        def self.display_value_to_speckle_entity(state, instance, speckle_instance, stream_id)
          return state unless state.user_state.user_preferences[:register_speckle_entity]

          speckle_id = speckle_instance['id']
          speckle_type = speckle_instance['speckle_type']
          children = speckle_instance['__closure'].nil? ? [] : speckle_instance['__closure']
          ent = SpeckleEntities::SpeckleEntity.new(instance, speckle_id, speckle_type, children, [stream_id])
          ent.write_initial_base_data
          new_speckle_state = state.speckle_state.with_speckle_entity(ent)
          state.with_speckle_state(new_speckle_state)
        end
      end
    end
  end
end
