# frozen_string_literal: true

require_relative 'point'
require_relative 'vector'
require_relative '../base'

module SpeckleConnector3
  module SpeckleObjects
    module Geometry
      # Plane object definition for Speckle.
      class Plane < Base
        SPECKLE_TYPE = 'Objects.Geometry.Plane'

        # @param x_dir [Geometry::Vector] vector on the x direction
        # @param y_dir [Geometry::Vector] vector on the y direction
        # @param normal [Geometry::Vector] normal vector
        # @param origin [Geometry::Point] origin point
        # @param units [String] units of the Sketchup model
        def initialize(x_dir, y_dir, normal, origin, units)
          super(
            speckle_type: SPECKLE_TYPE,
            application_id: nil,
            id: nil
          )
          self[:xdir] = x_dir
          self[:ydir] = y_dir
          self[:normal] = normal
          self[:origin] = origin
          self[:units] = units
        end

        def self.origin(units)
          Plane.new(
            Vector.new(1, 0, 0, units),
            Vector.new(0, 1, 0, units),
            Vector.new(0, 0, 1, units),
            Point.new(0, 0, 0, units),
            units
          )
        end
      end
    end
  end
end
