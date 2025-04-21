# frozen_string_literal: true

require_relative '../base'
require_relative '../../constants/type_constants'
require_relative '../other/display_value'
require_relative '../../sketchup_model/dictionary/base_dictionary_handler'

module SpeckleConnector3
  module SpeckleObjects
    class RevitDataObject < Base
      SPECKLE_TYPE = SPECKLE_OBJECT_DATA_OBJECT_REVIT

      def self.to_native(state, revit_data_object, layer, entities, &convert_to_native)
        properties = revit_data_object['properties']

        new_state, instance_and_definition = SpeckleObjects::Other::DisplayValue.to_native(state, revit_data_object, layer, entities, &convert_to_native)
        instance, _definition = instance_and_definition
        attr = instance.attribute_dictionary('Speckle', true)

        SketchupModel::Dictionary::BaseDictionaryHandler.hash_to_dict('Revit Parameters', properties, attr) if properties
        return new_state, instance_and_definition
      end
    end
  end
end
