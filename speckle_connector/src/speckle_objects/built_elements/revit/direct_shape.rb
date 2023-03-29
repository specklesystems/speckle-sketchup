# frozen_string_literal: true

require_relative '../../base'
require_relative '../../other/render_material'
require_relative '../../../constants/type_constants'
require_relative '../../../sketchup_model/query/entity'

module SpeckleConnector
  module SpeckleObjects
    module BuiltElements
      module Revit
        # Direct shape definition for Revit mappings.
        class DirectShape < Base
          SPECKLE_TYPE = OBJECTS_BUILTELEMENTS_REVIT_DIRECTSHAPE

          def initialize(name:, category:, units:, base_geometries:, application_id: nil)
            super(
              speckle_type: SPECKLE_TYPE,
              total_children_count: 0,
              application_id: application_id,
              id: nil
            )
            self[:name] = name
            self[:category] = category
            self[:units] = units
            self[:baseGeometries] = base_geometries
          end

          # rubocop:disable Metrics/AbcSize
          # rubocop:disable Metrics/CyclomaticComplexity
          # rubocop:disable Metrics/MethodLength
          # rubocop:disable Metrics/PerceivedComplexity
          def self.from_entity(entity, path, units, preferences)
            schema = SketchupModel::Dictionary::SpeckleSchemaDictionaryHandler.attribute_dictionary(entity)
            if schema.nil? && entity.respond_to?(:definition)
              schema = SketchupModel::Dictionary::SpeckleSchemaDictionaryHandler.attribute_dictionary(entity.definition)
            end
            entities_with_path = []
            entities_with_path.append([entity] + path) if entity.is_a?(Sketchup::Face) || entity.is_a?(Sketchup::Edge)
            # Collect here flat list
            if entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group)
              # entities.append(entity)
              entities_with_path += SketchupModel::Query::Entity
                                    .flat_entities_with_path(
                                      entity.definition.entities,
                                      [Sketchup::Face], path.append(entity)
                                    )
            end
            base_geometries = []
            entities_with_path.each do |entity_with_path|
              e = entity_with_path[0]
              entity_path = entity_with_path[1..-1]
              # next if entity.is_a?(Sketchup::Edge) && entity.faces.any?
              next unless e.is_a?(Sketchup::Face)

              mesh = SpeckleObjects::Geometry::Mesh
                     .from_face(face: e, units: units, model_preferences: preferences[:model],
                                global_transform: SketchupModel::Query::Entity.global_transformation(e, entity_path),
                                parent_material: SketchupModel::Query::Entity.parent_material(entity_path))
              base_geometries.append(mesh)
            end
            DirectShape.new(
              name: schema[:name],
              category: schema[:category],
              units: units,
              base_geometries: base_geometries,
              application_id: entity.persistent_id
            )
          end
          # rubocop:enable Metrics/AbcSize
          # rubocop:enable Metrics/CyclomaticComplexity
          # rubocop:enable Metrics/MethodLength
          # rubocop:enable Metrics/PerceivedComplexity
        end
      end
    end
  end
end
