# frozen_string_literal: true

require_relative 'render_material'
require_relative 'transform'
require_relative 'block_definition'
require_relative '../../immutable/immutable'
require_relative '../../ext/immutable_ruby/hash'
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
        def self.to_native(state, obj, layer, entities, &convert_to_native)
          # Switch displayValue with geometry
          obj['geometry'] = obj['displayValue']
          obj['geometry'] += obj['elements'] unless obj['elements'].nil?

          state, _definitions = BlockDefinition.to_native(
            state,
            obj,
            layer,
            entities,
            &convert_to_native
          )

          definition = state.sketchup_state.sketchup_model.definitions[BlockDefinition.get_definition_name(obj)]

          BlockInstance.find_and_erase_existing_instance(definition, obj['id'], obj['applicationId'])
          t_arr = obj['transform']
          transform = t_arr.nil? ? Geom::Transformation.new : OTHER::Transform.to_native(t_arr, units)
          instance = entities.add_instance(definition, transform)
          instance.name = obj['name'] unless obj['name'].nil?
          return state, [instance, definition]
        end
      end
    end
  end
end
