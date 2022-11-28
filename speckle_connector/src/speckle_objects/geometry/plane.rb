# frozen_string_literal: true

require_relative 'point'
require_relative 'vector'
require_relative '../../typescript/typescript_object'

module SpeckleConnector
  module SpeckleObjects
    module Geometry
      # Plane object definition for Speckle.
      class Plane < Typescript::TypescriptObject
        SPECKLE_TYPE = 'Objects.Geometry.Plane'
        ATTRIBUTES = {
          speckle_type: String,
          units: String,
          xdir: Geometry::Vector,
          ydir: Geometry::Vector,
          normal: Geometry::Vector,
          origin: Geometry::Point,
          sketchup_attributes: Object
        }.freeze

        # @param x_dir [Geometry::Vector] vector on the x direction
        # @param y_dir [Geometry::Vector] vector on the y direction
        # @param normal [Geometry::Vector] normal vector
        # @param origin [Geometry::Point] origin point
        # @param units [String] units of the Sketchup model
        def self.from_vectors(x_dir, y_dir, normal, origin, units)
          Plane.new(
            speckle_type: SPECKLE_TYPE,
            units: units,
            xdir: x_dir,
            ydir: y_dir,
            normal: normal,
            origin: origin
          )
        end

        def self.origin(units)
          from_vectors(
            Vector.from_coordinates(1, 0, 0, units),
            Vector.from_coordinates(0, 1, 0, units),
            Vector.from_coordinates(0, 0, 1, units),
            Point.from_coordinates(0, 0, 0, units),
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
