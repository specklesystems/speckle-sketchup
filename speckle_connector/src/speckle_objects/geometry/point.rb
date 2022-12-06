# frozen_string_literal: true

require_relative 'length'
require_relative '../base'
require_relative '../../typescript/typescript_object'

module SpeckleConnector
  module SpeckleObjects
    module Geometry
      # Point object definition for Speckle.
      class Point < Base
        SPECKLE_TYPE = 'Objects.Geometry.Point'

        # @param x [Numeric] x coordinate of the point.
        # @param y [Numeric] y coordinate of the point.
        # @param z [Numeric] z coordinate of the point.
        # @param units [String] unit of the point.
        def initialize(x, y, z, units)
          super(
            speckle_type: SPECKLE_TYPE,
            total_children_count: 0,
            application_id: nil,
            id: nil
          )
          self[:x] = x
          self[:y] = y
          self[:z] = z
          self[:units] = units
        end

        # @param vertex [Geom::Point3d] sketchup point to convert speckle point.
        # @param units [String] unit of the point.
        def self.from_vertex(vertex, units)
          Point.new(
            Geometry.length_to_speckle(vertex[0], units),
            Geometry.length_to_speckle(vertex[1], units),
            Geometry.length_to_speckle(vertex[2], units),
            units
          )
        end

        def self.to_native(x, y, z, units)
          Geom::Point3d.new(
            Geometry.length_to_native(x, units),
            Geometry.length_to_native(y, units),
            Geometry.length_to_native(z, units)
          )
        end
      end
    end
  end
end
