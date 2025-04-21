# frozen_string_literal: true

require_relative '../base'
require_relative '../../constants/type_constants'

module SpeckleConnector3
  module SpeckleObjects
    class DataObject < Base
      SPECKLE_TYPE = SPECKLE_OBJECT_DATA_OBJECT

      def self.to_native(state, data_object, layer, _entities, &convert_to_native)
        properties = data_object['properties']
        return state
      end
    end
  end
end
