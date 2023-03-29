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

          def self.from_entity(entity, path, units, preferences)
            schema = SketchupModel::Dictionary::SpeckleSchemaDictionaryHandler.attribute_dictionary(entity)
            if schema.nil? && entity.respond_to?(:definition)
              schema = SketchupModel::Dictionary::SpeckleSchemaDictionaryHandler.attribute_dictionary(entity.definition)
            end
            entities_with_path = []
            entities_with_path.append([entity] + path) if entity.is_a?(Sketchup::Face) || entity.is_a?(Sketchup::Edge)
            # Collect here flat list
            if entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group)
              entities_with_path += SketchupModel::Query::Entity
                                    .flat_entities_with_path(
                                      entity.definition.entities, [Sketchup::Face], path.append(entity)
                                    )
            end
            base_geometries = group_faces_under_mesh_by_material(entities_with_path, units, preferences)
            DirectShape.new(
              name: schema[:name], category: schema[:category], units: units,
              base_geometries: base_geometries, application_id: entity.persistent_id
            )
          end

          def self.group_faces_under_mesh_by_material(faces_with_path, units, preferences)
            mesh_groups = {}
            faces_with_path.each do |face_with_path|
              face = face_with_path[0]
              entity_path = face_with_path[1..-1]
              mesh_group_id = Geometry::Mesh.get_mesh_group_id(face, preferences[:model], entity_path)

              if mesh_groups.key?(mesh_group_id)
                mesh_group = mesh_groups[mesh_group_id]
                mesh_group[0].face_to_mesh(face, SketchupModel::Query::Entity.global_transformation(face, entity_path))
                mesh_group[1].append(face)
              else
                mesh = Geometry::Mesh.from_face(
                  face: face, units: units, model_preferences: preferences[:model],
                  global_transform: SketchupModel::Query::Entity.global_transformation(face, entity_path),
                  parent_material: SketchupModel::Query::Entity.parent_material(entity_path)
                )
                mesh_groups[mesh_group_id] = [mesh, [face]]
              end
            end
            # Update mesh overwrites points and polygons into base object.
            mesh_groups.each { |_, mesh| mesh.first.update_mesh }
            mesh_groups.values
          end
        end
      end
    end
  end
end
