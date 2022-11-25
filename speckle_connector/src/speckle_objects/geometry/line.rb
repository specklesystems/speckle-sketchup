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
          bbox: Geometry::BoundingBox,
          sketchup_attributes: Object
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

        # rubocop:disable Metrics/AbcSize
        def self.to_native(line, entities)
          if line.key?('value')
            values = line['value']
            points = values.each_slice(3).to_a.map { |pt| Point.to_native(pt[0], pt[1], pt[2], line['units']) }
            points.push(points[0]) if line['closed']
            entities.add_edges(*points)
          else
            start_pt = Point.to_native(line['start']['x'], line['start']['y'], line['start']['z'], line['units'])
            end_pt = Point.to_native(line['end']['x'], line['end']['y'], line['end']['z'], line['units'])
            entities.add_edges(start_pt, end_pt)
          end
        end
        # rubocop:enable Metrics/AbcSize

        def attribute_types
          ATTRIBUTES
        end
      end
    end
  end
end
