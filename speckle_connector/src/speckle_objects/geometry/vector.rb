# frozen_string_literal: true

require_relative '../../typescript/typescript_object'

module SpeckleConnector
  module SpeckleObjects
    module Geometry
      # Vector object definition for Speckle.
      class Vector < Typescript::TypescriptObject
        SPECKLE_TYPE = 'Objects.Geometry.Vector'
        ATTRIBUTES = {
          speckle_type: String,
          units: String,
          x: Numeric,
          y: Numeric,
          z: Numeric,
          sketchup_attributes: Object
        }.freeze

        def self.from_coordinates(x, y, z, units)
          Vector.new(
            speckle_type: SPECKLE_TYPE,
            units: units,
            x: x,
            y: y,
            z: z
          )
        end

        def attribute_types
          ATTRIBUTES
        end
      end
    end
  end
end
