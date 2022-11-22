# frozen_string_literal: true

require_relative 'length'
require_relative 'point'
require_relative 'bounding_box'
require_relative '../primitive/interval'
require_relative '../../typescript/typescript_object'

module SpeckleConnector
  module SpeckleObjects
    module Geometry
      # Line object definition for Speckle.
      class Line < Typescript::TypescriptObject
        SPECKLE_TYPE = 'Objects.Geometry.Line'
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
        def self.from_edge(edge, units)
          start_vertex = edge.start.position
          end_vertex = edge.end.position
          Line.new(
            speckle_type: SPECKLE_TYPE,
            units: units,
            applicationId: edge.persistent_id.to_s,
            start: Geometry::Point.from_vertex(start_vertex, units),
            end: Geometry::Point.from_vertex(end_vertex, units),
            domain: Primitive::Interval.from_numeric(0, Float(edge.length), units),
            bbox: Geometry::BoundingBox.from_bounds(edge.bounds, units)
          )
        end

        def attribute_types
          ATTRIBUTES
        end
      end
    end
  end
end
