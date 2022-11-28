# frozen_string_literal: true

require_relative '../../typescript/typescript_object'
require_relative '../primitive/interval'
require_relative '../geometry/plane'

module SpeckleConnector
  module SpeckleObjects
    module Geometry
      # BoundingBox object definition for Speckle.
      class BoundingBox < Typescript::TypescriptObject
        SPECKLE_TYPE = 'Objects.Geometry.Box'
        ATTRIBUTES = {
          speckle_type: String,
          units: String,
          area: Numeric,
          volume: Numeric,
          xSize: Primitive::Interval,
          ySize: Primitive::Interval,
          zSize: Primitive::Interval,
          basePlane: Geometry::Plane,
          sketchup_attributes: Object
        }.freeze

        # @param bounds [Geom::BoundingBox] bounding box object of Sketchup.
        def self.from_bounds(bounds, units)
          min_pt = bounds.min
          BoundingBox.new(
            speckle_type: SPECKLE_TYPE,
            units: units,
            area: 0,
            volume: 0,
            xSize: Primitive::Interval.from_lengths(min_pt[0], bounds.width, units),
            ySize: Primitive::Interval.from_lengths(min_pt[1], bounds.height, units),
            zSize: Primitive::Interval.from_lengths(min_pt[2], bounds.depth, units),
            basePlane: Plane.origin(units)
          )
        end

        private

        def attribute_types
          ATTRIBUTES
        end
      end
    end
  end
end
