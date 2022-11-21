# frozen_string_literal: true

require_relative 'point'
require_relative 'bounding_box'
require_relative '../primitive/interval'
require_relative '../speckle_geometry_object'

module SpeckleConnector
  module SpeckleObjects
    module Geometry
      # Line object definition for Speckle.
      class Line < SpeckleGeometryObject
        ATTRIBUTES = {
          speckle_type: String,
          applicationId: String,
          units: String,
          start: Geometry::Point,
          end: Geometry::Point,
          domain: Primitive::Interval,
          bbox: Geometry::BoundingBox
        }.freeze

        # @param edge [Sketchup::Edge] edge to convert line.
        # @param units [String] units of the Sketchup.
        def initialize(edge, units)
          @units = units
          start_vertex = edge.start.position
          end_vertex = edge.end.position
          super(
            'Objects.Geometry.Line',
            units,
            **{
              applicationId: edge.persistent_id.to_s,
              start: to_point(start_vertex, units),
              end: to_point(end_vertex, units),
              domain: Primitive::Interval.new(0, Float(edge.length), units),
              bbox: Geometry::BoundingBox.new(edge.bounds, units)
            }
          )
        end

        private

        def length_to_speckle(length, units)
          length.__send__("to_#{SpeckleConnector::Converters::SKETCHUP_UNIT_STRINGS[units]}")
        end

        def to_point(vertex, units)
          Geometry::Point.new(
            length_to_speckle(vertex[0], units),
            length_to_speckle(vertex[1], units),
            length_to_speckle(vertex[2], units),
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
