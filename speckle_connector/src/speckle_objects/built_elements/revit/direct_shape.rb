# frozen_string_literal: true

require_relative '../../base'
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

          def self.from_entity(entity, path, units, preferences)
            schema = SketchupModel::Dictionary::SpeckleSchemaDictionaryHandler.attribute_dictionary(entity)
            if schema.nil? && entity.respond_to?(:definition)
              schema = SketchupModel::Dictionary::SpeckleSchemaDictionaryHandler.attribute_dictionary(entity.definition)
            end
            entities = []
            entities.append(entity) if entity.is_a?(Sketchup::Face) || entity.is_a?(Sketchup::Edge)
            # Collect here flat list
            if entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group)
              # entities.append(entity)
              entities += SketchupModel::Query::Entity.flat_entities(entity.definition.entities, [Sketchup::Face])
            end
            base_geometries = []
            entities.each do |e|
              # next if entity.is_a?(Sketchup::Edge) && entity.faces.any?
              next unless e.is_a?(Sketchup::Face)

              mesh = SpeckleObjects::Geometry::Mesh
                     .from_face(e, units, preferences[:model],
                                SketchupModel::Query::Entity.global_transformation(entity, path))
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
        end
      end
    end
  end
end
