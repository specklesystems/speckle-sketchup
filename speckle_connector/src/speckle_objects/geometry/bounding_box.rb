# frozen_string_literal: true

require_relative '../speckle_geometry_object'
require_relative '../primitive/interval'
require_relative '../geometry/plane'

module SpeckleConnector
  module SpeckleObjects
    module Geometry
      # BoundingBox object definition for Speckle.
      class BoundingBox < SpeckleGeometryObject
        ATTRIBUTES = {
          speckle_type: String,
          units: String,
          area: Numeric,
          volume: Numeric,
          xSize: Primitive::Interval,
          ySize: Primitive::Interval,
          zSize: Primitive::Interval,
          basePlane: Geometry::Plane
        }.freeze

        # @param bounds [Geom::BoundingBox] bounding box object of Sketchup.
        def initialize(bounds, units)
          min_pt = bounds.min
          super(
            'Objects.Geometry.Box',
            units,
            **{
              area: 0,
              volume: 0,
              xSize: to_interval(min_pt[0], bounds.width, units),
              ySize: to_interval(min_pt[1], bounds.height, units),
              zSize: to_interval(min_pt[2], bounds.depth, units),
              basePlane: Plane.origin(units)
            }
          )
        end

        private

        def to_interval(l_1, l_2, units)
          Primitive::Interval.new(
            length_to_speckle(l_1, units),
            length_to_speckle(l_2, units),
            units
          )
        end

        def length_to_speckle(length, units)
          length.__send__("to_#{SpeckleConnector::Converters::SKETCHUP_UNIT_STRINGS[units]}")
        end

        def attribute_types
          ATTRIBUTES
        end
      end
    end
  end
end
