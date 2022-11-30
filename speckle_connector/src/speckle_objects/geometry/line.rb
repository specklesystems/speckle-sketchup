# frozen_string_literal: true

require_relative 'length'
require_relative 'point'
require_relative 'bounding_box'
require_relative '../primitive/interval'
require_relative '../base'
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

        # TODO: Add constructor when we inherit from base object
        # def initialize(application_id: nil)
        #   super(
        #       speckle_type: 'Objects.Geometry.Line',
        #       total_children_count: 0,
        #       application_id: application_id,
        #       id: nil
        #     )
        # end

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

        # @param line [Object] object represents Speckle line.
        # @param layer [Sketchup::Layer] layer to add {Sketchup::Edge} into it.
        # @param entities [Sketchup::Entities] entities collection to add {Sketchup::Edge} into it.
        # rubocop:disable Metrics/AbcSize
        def self.to_native(line, layer, entities)
          if line.key?('value')
            values = line['value']
            points = values.each_slice(3).to_a.map { |pt| Point.to_native(pt[0], pt[1], pt[2], line['units']) }
            points.push(points[0]) if line['closed']
            edges = entities.add_edges(*points)
          else
            start_pt = Point.to_native(line['start']['x'], line['start']['y'], line['start']['z'], line['units'])
            end_pt = Point.to_native(line['end']['x'], line['end']['y'], line['end']['z'], line['units'])
            edges = entities.add_edges(start_pt, end_pt)
          end
          edges.each { |edge| edge.layer = layer }
        end
        # rubocop:enable Metrics/AbcSize

        def self.test_line(start_point, end_point, units)
          Line.new(
            speckle_type: SPECKLE_TYPE,
            units: units,
            applicationId: '',
            start: start_point,
            end: end_point,
            domain: Primitive::Interval.from_numeric(0, 5, units),
            bbox: Geometry::BoundingBox.test_bounds(units)
          )
        end

        def attribute_types
          ATTRIBUTES
        end
      end
    end
  end
end
