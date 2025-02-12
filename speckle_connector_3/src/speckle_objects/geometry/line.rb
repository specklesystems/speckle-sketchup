# frozen_string_literal: true

require_relative 'length'
require_relative 'point'
require_relative 'bounding_box'
require_relative '../base'
require_relative '../primitive/interval'
require_relative '../../convertors/conversion_error'
require_relative '../../ui_data/report/conversion_result'
require_relative '../../sketchup_model/dictionary/base_dictionary_handler'
require_relative '../../sketchup_model/dictionary/speckle_schema_dictionary_handler'

module SpeckleConnector3
  module SpeckleObjects
    module Geometry
      # Line object definition for Speckle.
      class Line < Base
        SPECKLE_TYPE = 'Objects.Geometry.Line'

        # @param start_pt [Geometry::Point] start point speckle object of the speckle line.
        # @param end_pt [Geometry::Point] end point speckle object of the speckle line.
        # @param domain [Primitive::Interval] interval speckle object of the speckle line -represents domain.
        # @param units [String] units of the speckle line.
        # @param application_id [String, nil] entity id of the {Sketchup::Edge} that represents to the speckle line.
        # rubocop:disable Metrics/ParameterLists
        def initialize(start_pt:, end_pt:, domain:, units:, layer:,
                       sketchup_attributes: {}, speckle_schema: {}, application_id: nil)
          super(
              speckle_type: 'Objects.Geometry.Line',
              application_id: application_id,
              id: nil
            )
          self[:start] = start_pt
          self[:end] = end_pt
          self[:domain] = domain
          self[:units] = units
          self[:layer] = layer unless layer.nil?
          self['@SpeckleSchema'] = speckle_schema if speckle_schema.any?
          self[:properties] = sketchup_attributes if sketchup_attributes.any?
        end
        # rubocop:enable Metrics/ParameterLists

        def self.to_speckle_schema(edge:, units:)
          start_pt = Geometry::Point.from_vertex(edge.start.position, units)
          end_pt = Geometry::Point.from_vertex(edge.end.position, units)
          domain = Primitive::Interval.from_numeric(0, Float(edge.length), units)
          Line.new(
            start_pt: start_pt,
            end_pt: end_pt,
            domain: domain,
            units: units,
            layer: SketchupModel::Query::Layer.entity_path(edge),
            sketchup_attributes: {},
            speckle_schema: {},
            application_id: edge.persistent_id.to_s
          )
        end

        # @param edge [Sketchup::Edge] edge to convert line.
        def self.from_edge(speckle_state:, edge:, units:, model_preferences:, global_transformation: nil)
          dictionaries = SketchupModel::Dictionary::BaseDictionaryHandler
                         .attribute_dictionaries_to_speckle(edge, model_preferences)
          att = dictionaries.any? ? { dictionaries: dictionaries } : {}
          speckle_schema = Mapper.to_speckle(speckle_state, edge, units, global_transformation: global_transformation)
          start_pt = Geometry::Point.from_vertex(edge.start.position, units)
          end_pt = Geometry::Point.from_vertex(edge.end.position, units)
          domain = Primitive::Interval.from_numeric(0, Float(edge.length), units)
          Line.new(
            start_pt: start_pt,
            end_pt: end_pt,
            domain: domain,
            units: units,
            layer: SketchupModel::Query::Layer.entity_path(edge),
            sketchup_attributes: att,
            speckle_schema: speckle_schema,
            application_id: edge.persistent_id.to_s
          )
        end

        # @param edge [Sketchup::Face] face to get base line from face.
        def self.base_line_from_face(face, units, global_transformation: nil)
          points = face.vertices.collect(&:position)
          points_z_values = points.collect(&:z)
          height = Geometry.length_to_speckle(points_z_values.max - points_z_values.min, units)
          min_z = points_z_values.min
          projected_points = points.map { |p| Geom::Point3d.new(p.x, p.y, min_z) }
          distance_with_points = Struct.new(:distance, :point_1, :point_2)
          lines_with_distances = []
          projected_points.each do |p|
            projected_points.each do |p_other|
              next if p_other == p

              lines_with_distances.append(distance_with_points.new(p.distance(p_other), p, p_other))
            end
          end
          lines_with_distances.sort_by!(&:distance).reverse!
          p_1 = lines_with_distances.first.point_1
          p_2 = lines_with_distances.first.point_2
          unless global_transformation.nil?
            p_1 = p_1.transform!(global_transformation)
            p_2 = p_2.transform!(global_transformation)
          end
          Line.new(
            start_pt: Geometry::Point.from_vertex(p_1, units),
            end_pt: Geometry::Point.from_vertex(p_2, units),
            domain: Primitive::Interval.from_numeric(0, Geometry.length_to_speckle(p_1.distance(p_2), units), units),
            units: units,
            layer: SketchupModel::Query::Layer.entity_path(face),
            sketchup_attributes: {},
            speckle_schema: {},
            application_id: face.persistent_id.to_s
          )
        end

        # @param state [States::State] state of the application.
        # @param line [Object] object represents Speckle line.
        # @param layer [Sketchup::Layer] layer to add {Sketchup::Edge} into it.
        # @param entities [Sketchup::Entities] entities collection to add {Sketchup::Edge} into it.
        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Metrics/PerceivedComplexity
        # rubocop:disable Metrics/CyclomaticComplexity
        def self.to_native(state, line, layer, entities, &_convert_to_native)
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

          if edges.nil?
            raise Converters::ConverterError.new('Start and end points of line overlaps.',
                                                 UiData::Report::ConversionStatus::WARNING)
          end

          # line_layer_name = SketchupModel::Query::Layer.entity_layer_from_path(line['layer'])
          # line_layer = state.sketchup_state.sketchup_model.layers.to_a.find { |l| l.display_name == line_layer_name }
          edges.each do |edge|
            edge.layer = layer
            # edge.layer = line_layer.nil? ? layer : line_layer
            unless line['sketchup_attributes'].nil?
              SketchupModel::Dictionary::BaseDictionaryHandler
                .attribute_dictionaries_to_native(edge, line['sketchup_attributes']['dictionaries'])
            end
          end
          return state, edges
        end
        # rubocop:enable Metrics/AbcSize
        # rubocop:enable Metrics/PerceivedComplexity
        # rubocop:enable Metrics/CyclomaticComplexity

        def self.test_line(start_point, end_point, units)
          domain = Primitive::Interval.from_numeric(0, 5, units)
          Line.new(
            start_pt: start_point,
            end_pt: end_point,
            domain: domain,
            layer: 'test',
            application_id: 'test',
            units: units
          )
        end
      end
    end
  end
end
