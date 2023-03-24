# frozen_string_literal: true

require_relative 'revit_definition'
require_relative '../render_material'
require_relative '../transform'
require_relative '../block_definition'
require_relative '../../base'
require_relative '../../geometry/bounding_box'
require_relative '../../../sketchup_model/dictionary/dictionary_handler'

module SpeckleConnector
  module SpeckleObjects
    module Other
      module Revit
        # RevitInstance object definition for Speckle.
        class RevitInstance < Base
          SPECKLE_TYPE = OBJECTS_OTHER_REVIT_REVITINSTANCE

          # Creates a component instance from a block
          # @param state [States::State] state of the application.
          # @param block [Object] block object that represents Speckle block.
          # @param layer [Sketchup::Layer] layer to add {Sketchup::Edge} into it.
          # @param entities [Sketchup::Entities] entities collection to add {Sketchup::Edge} into it.
          def self.to_native(state, block, layer, entities, &convert_to_native)
            block_definition = block['definition']

            state, _definitions = RevitDefinition.to_native(
              state,
              block_definition,
              layer,
              entities,
              &convert_to_native
            )

            definition = state.sketchup_state.sketchup_model
                              .definitions[RevitDefinition.get_definition_name(block_definition)]

            return BlockInstance.add_instance_from_definition(state, block, layer, entities,
                                                              definition, false, &convert_to_native)
          end
        end
      end
    end
  end
end
