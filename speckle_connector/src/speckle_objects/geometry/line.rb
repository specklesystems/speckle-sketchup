# frozen_string_literal: true

require_relative 'length'
require_relative 'point'
require_relative 'bounding_box'
require_relative '../base'
require_relative '../primitive/interval'
require_relative '../../sketchup_model/dictionary/dictionary_handler'

module SpeckleConnector
  module SpeckleObjects
    module Geometry
      # Line object definition for Speckle.
      class Line < Base
        SPECKLE_TYPE = 'Objects.Geometry.Line'

        # @param start_pt [Geometry::Point] start point speckle object of the speckle line.
        # @param end_pt [Geometry::Point] end point speckle object of the speckle line.
        # @param domain [Primitive::Interval] interval speckle object of the speckle line -represents domain.
        # @param bbox [Geometry::BoundingBox] bounding box speckle object of the speckle line.
        # @param units [String] units of the speckle line.
        # @param application_id [String, nil] entity id of the {Sketchup::Edge} that represents to the speckle line.
        # rubocop:disable Metrics/ParameterLists
        def initialize(start_pt:, end_pt:, domain:, bbox:, units:, sketchup_attributes: {}, application_id: nil)
          super(
              speckle_type: 'Objects.Geometry.Line',
              total_children_count: 0,
              application_id: application_id,
              id: nil
            )
          self[:start] = start_pt
          self[:end] = end_pt
          self[:domain] = domain
          self[:bbox] = bbox
          self[:units] = units
          self[:sketchup_attributes] = sketchup_attributes if sketchup_attributes.any?
        end
        # rubocop:enable Metrics/ParameterLists

        # @param edge [Sketchup::Edge] edge to convert line.
        def self.from_edge(edge, units, model_preferences)
          dictionaries = {}
          if model_preferences[:include_entity_attributes]
            dictionaries = SketchupModel::Dictionary::DictionaryHandler.attribute_dictionaries_to_speckle(edge)
          end
          att = dictionaries.any? ? { dictionaries: dictionaries } : {}
          start_pt = Geometry::Point.from_vertex(edge.start.position, units)
          end_pt = Geometry::Point.from_vertex(edge.end.position, units)
          domain = Primitive::Interval.from_numeric(0, Float(edge.length), units)
          bbox = Geometry::BoundingBox.from_bounds(edge.bounds, units)
          Line.new(
            start_pt: start_pt,
            end_pt: end_pt,
            domain: domain,
            bbox: bbox,
            units: units,
            sketchup_attributes: att,
            application_id: edge.persistent_id.to_s
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
          edges.each do |edge|
            edge.layer = layer
            SketchupModel::Dictionary::DictionaryHandler
              .attribute_dictionaries_to_native(edge, line['sketchup_attributes']['dictionaries'])
          end
        end
        # rubocop:enable Metrics/AbcSize

        def self.test_line(start_point, end_point, units)
          domain = Primitive::Interval.from_numeric(0, 5, units)
          bbox = Geometry::BoundingBox.test_bounds(units)
          Line.new(
            start_pt: start_point,
            end_pt: end_point,
            domain: domain,
            bbox: bbox,
            application_id: '',
            units: units
          )
        end
      end
    end
  end
end
