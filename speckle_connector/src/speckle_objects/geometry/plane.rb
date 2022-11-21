# frozen_string_literal: true

require_relative 'point'
require_relative 'vector'
require_relative '../speckle_geometry_object'

module SpeckleConnector
  module SpeckleObjects
    module Geometry
      # Plane object definition for Speckle.
      class Plane < SpeckleGeometryObject
        ATTRIBUTES = {
          speckle_type: String,
          units: String,
          xdir: Geometry::Vector,
          ydir: Geometry::Vector,
          normal: Geometry::Vector,
          origin: Geometry::Point
        }.freeze

        # @param x_dir [Geometry::Vector] vector on the x direction
        # @param y_dir [Geometry::Vector] vector on the y direction
        # @param normal [Geometry::Vector] normal vector
        # @param origin [Geometry::Point] origin point
        # @param units [String] units of the Sketchup model
        def initialize(x_dir, y_dir, normal, origin, units)
          super(
            'Objects.Geometry.Plane',
            units,
            **{
              xdir: x_dir,
              ydir: y_dir,
              normal: normal,
              origin: origin
            }
          )
        end

        def self.origin(units)
          new(
            Vector.new(1, 0, 0, units),
            Vector.new(0, 1, 0, units),
            Vector.new(0, 0, 1, units),
            Point.new(0, 0, 0, units),
            units
          )
        end

        def attribute_types
          ATTRIBUTES
        end
      end
    end
  end
end
