# frozen_string_literal: true

require_relative '../base'
require_relative '../../constants/type_constants'

module SpeckleConnector3
  module SpeckleObjects
    module BuiltElements
      # Network object represents scenes on Sketchup.
      class Network < Base
        SPECKLE_TYPE = OBJECTS_BUILTELEMENTS_NETWORK

        def self.to_native(state, network, layer, entities, &convert_to_native)
          network['elements'].each do |element|
            state, _converted_entities = convert_to_native.call(state, element['elements'], layer, entities)
          end

          return state, []
        end
      end
    end
  end
end
