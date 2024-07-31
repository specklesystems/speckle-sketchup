# frozen_string_literal: true

require_relative '../base'
require_relative '../primitive/interval'
require_relative '../geometry/plane'

module SpeckleConnector3
  module SpeckleObjects
    module Geometry
      # BoundingBox object definition for Speckle.
      class BoundingBox < Base
        SPECKLE_TYPE = 'Objects.Geometry.Box'

        # @param x_size [Primitive::Interval] interval for x size.
        # @param y_size [Primitive::Interval] interval for y size.
        # @param z_size [Primitive::Interval] interval for z size.
        # @param base_plane [Geometry::Plane] plane for base.
        def initialize(x_size, y_size, z_size, base_plane)
          super(
            speckle_type: SPECKLE_TYPE,
            total_children_count: 0,
            application_id: nil,
            id: nil
          )
          self[:area] = 0
          self[:volume] = 0
          self[:xSize] = x_size
          self[:ySize] = y_size
          self[:zSize] = z_size
          self[:basePlane] = base_plane
        end

        # @param bounds [Geom::BoundingBox] bounding box object of Sketchup.
        def self.from_bounds(bounds, units)
          min_pt = bounds.min
          x_size = Primitive::Interval.from_lengths(min_pt[0], bounds.width, units)
          y_size = Primitive::Interval.from_lengths(min_pt[1], bounds.height, units)
          z_size = Primitive::Interval.from_lengths(min_pt[2], bounds.depth, units)
          # FIXME: Decide how to approach center of bounds for each object?!
          base_plane = Plane.origin(units)
          BoundingBox.new(x_size, y_size, z_size, base_plane)
        end

        def self.test_bounds(units)
          x_size = Primitive::Interval.from_numeric(0, 5, units)
          y_size = Primitive::Interval.from_numeric(0, 5, units)
          z_size = Primitive::Interval.from_numeric(0, 0, units)
          base_plane = Plane.origin(units)
          BoundingBox.new(x_size, y_size, z_size, base_plane)
        end
      end
    end
  end
end
