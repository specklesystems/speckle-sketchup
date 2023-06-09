# frozen_string_literal: true

require_relative '../base'
require_relative '../../constants/type_constants'

module SpeckleConnector
  module SpeckleObjects
    module Geometry
      # Polycurve object definition for Speckle.
      # It basically groups the lines-curves under it's `segments` property.
      class Polycurve < Base
        SPECKLE_TYPE = OBJECTS_GEOMETRY_POLYCURVE

        def self.to_native(state, polycurve, layer, entities, &convert_to_native)
          polycurve['displayValue'] = polycurve['segments']
          convert_to_native.call(state, polycurve, layer, entities)
        end
      end
    end
  end
end
