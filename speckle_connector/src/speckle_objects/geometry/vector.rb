# frozen_string_literal: true

require_relative '../base'

module SpeckleConnector
  module SpeckleObjects
    module Geometry
      # Vector object definition for Speckle.
      class Vector < Base
        SPECKLE_TYPE = 'Objects.Geometry.Vector'

        # @param x [Numeric] x coordinate of the vector.
        # @param y [Numeric] y coordinate of the vector.
        # @param z [Numeric] z coordinate of the vector.
        # @param units [String] unit of the vector.
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
      end
    end
  end
end
