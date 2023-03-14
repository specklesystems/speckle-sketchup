# frozen_string_literal: true

require_relative '../block_definition'
require_relative '../../base'

module SpeckleConnector
  module SpeckleObjects
    module Other
      module Revit
        # RevitDefinition for Speckle.
        class RevitDefinition < Base
          SPECKLE_TYPE = OBJECTS_OTHER_REVIT_REVITINSTANCE

          def self.get_definition_name(def_obj)
            family = def_obj['family']
            type = def_obj['type']
            category = def_obj['category']

            return "#{family}-#{type}-#{category}"
          end

          def self.to_native(state, definition, layer, entities, &convert_to_native)
            definition_name = get_definition_name(definition)
            definition['name'] = definition_name
            BlockDefinition.to_native(state, definition, layer, entities, &convert_to_native)
          end
        end
      end
    end
  end
end
