# frozen_string_literal: true

require_relative '../other/block_definition'
require_relative '../base'

module SpeckleConnector3
  module SpeckleObjects
    module Revit
      module Other
        # RevitDefinition for Speckle.
        class RevitDefinition < Base
          SPECKLE_TYPE = OBJECTS_OTHER_REVIT_REVITINSTANCE

          def self.get_definition_name(def_obj)
            family = def_obj['family']
            type = def_obj['type']
            category = def_obj['category']
            element_id = def_obj['elementId']
            id = def_obj['id']

            return "#{family}-#{type}-#{category}-#{element_id}-#{id}"
          end

          def self.to_native(state, definition, layer, entities, &convert_to_native)
            definition_name = get_definition_name(definition)
            definition['name'] = definition_name
            definition['displayValue'] += definition['elements'] unless definition['elements'].nil?
            SpeckleObjects::Other::BlockDefinition.to_native(state, definition, layer, entities, &convert_to_native)
          end
        end
      end
    end
  end
end
