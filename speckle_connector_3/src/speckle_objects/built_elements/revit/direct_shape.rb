# frozen_string_literal: true

require_relative '../../base'
require_relative '../../other/render_material'
require_relative '../../other/block_instance'
require_relative '../../other/block_definition'
require_relative '../../other/transform'
require_relative '../../../constants/type_constants'
require_relative '../../../sketchup_model/query/entity'
require_relative '../../../sketchup_model/reader/mapper_reader'
require_relative '../../../sketchup_model/dictionary/speckle_schema_dictionary_handler'

module SpeckleConnector3
  module SpeckleObjects
    module BuiltElements
      module Revit
        # Direct shape definition for Revit mappings.
        class DirectShape < Base
          SPECKLE_TYPE = OBJECTS_BUILTELEMENTS_REVIT_DIRECTSHAPE
          READER = SketchupModel::Reader
          QUERY = SketchupModel::Query
          DICTIONARY = SketchupModel::Dictionary

          def initialize(name:, category:, units:, base_geometries:, application_id: nil)
            super(
              speckle_type: SPECKLE_TYPE,
              application_id: application_id,
              id: nil
            )
            self[:name] = name
            self[:category] = category
            self[:units] = units
            self[:baseGeometries] = base_geometries
          end

          def self.get_direct_shape_name(direct_shape)
            if direct_shape['name'] == ''
              direct_shape['applicationId'].to_s
            else
              "#{direct_shape['name']}::#{direct_shape['applicationId']}"
            end
          end

          # @param state [States::State] state of the application.
          def self.to_native(state, direct_shape, layer, entities, &convert_to_native)
            direct_shape['geometry'] = direct_shape['baseGeometries']
            direct_shape['name'] = get_direct_shape_name(direct_shape)

            state, _definitions = Other::BlockDefinition.to_native(
              state, direct_shape, layer, entities, &convert_to_native
            )

            definition = state.sketchup_state.sketchup_model
                              .definitions[Other::BlockDefinition.get_definition_name(direct_shape)]

            instance = entities.add_instance(definition, Geom::Transformation.new)
            instance.name = direct_shape['name'] unless direct_shape['name'].nil?
            DICTIONARY::SpeckleSchemaDictionaryHandler.set_hash(
              instance,
              {
                name: direct_shape['name'], category: direct_shape['category'], method: 'Direct Shape'
              }
            )
            new_speckle_state = state.speckle_state.with_mapped_entity(instance)
            state = state.with_speckle_state(new_speckle_state)
            instance.layer = layer unless layer.nil?

            return state, [instance, definition]
          end

          # Collects direct shapes on selection as flat list.
          def self.direct_shapes_on_selection(sketchup_model)
            flat_selection_with_path = QUERY::Entity.flat_entities_with_path(
              sketchup_model.selection,
              [Sketchup::Face, Sketchup::ComponentInstance, Sketchup::Group], [sketchup_model]
            )
            mapped_selection = []
            flat_selection_with_path.each do |entities|
              entity = entities[0]
              is_entity_mapped = READER::MapperReader.mapped_with_schema?(entity)
              if entity.respond_to?(:definition)
                is_definition_mapped = READER::MapperReader.mapped_with_schema?(entity.definition)
                mapped_selection.append(entities) if is_entity_mapped || is_definition_mapped
                next
              end
              mapped_selection.append(entities) if is_entity_mapped
            end
            mapped_selection
          end

          def self.from_entity(speckle_state, entity, path, units, model_preferences)
            schema = DICTIONARY::SpeckleSchemaDictionaryHandler.attribute_dictionary(entity)
            if schema.nil? && entity.respond_to?(:definition)
              schema = DICTIONARY::SpeckleSchemaDictionaryHandler.attribute_dictionary(entity.definition)
            end
            entities_with_path = []
            entities_with_path.append([entity] + path) if entity.is_a?(Sketchup::Face) || entity.is_a?(Sketchup::Edge)
            # Collect here flat list
            if entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group)
              entities_with_path += QUERY::Entity
                                    .flat_entities_with_path(
                                      entity.definition.entities, [Sketchup::Face], path.append(entity)
                                    )
            end
            base_geometries = if entity.is_a?(Sketchup::Edge)
                                [Geometry::Line.from_edge(speckle_state: speckle_state, edge: entity, units: units,
                                                          model_preferences: model_preferences,
                                                          global_transformation: nil)]
                              else
                                group_faces_under_mesh_by_material(speckle_state, entities_with_path, units,
                                                                   model_preferences)
                              end
            DirectShape.new(
              name: schema[:name], category: schema[:category], units: units,
              base_geometries: base_geometries, application_id: entity.persistent_id.to_s
            )
          end

          # rubocop:disable Metrics/MethodLength
          def self.group_faces_under_mesh_by_material(speckle_state, faces_with_path, units, model_preferences)
            mesh_groups = {}
            faces_with_path.each do |face_with_path|
              face = face_with_path[0]
              entity_path = face_with_path[1..-1]
              parent_material = QUERY::Entity.parent_material(entity_path)
              mesh_group_id = Geometry::Mesh.get_mesh_group_id(face, model_preferences, parent_material)

              if mesh_groups.key?(mesh_group_id)
                mesh_group = mesh_groups[mesh_group_id]
                mesh_group[0].face_to_mesh(face, QUERY::Entity.global_transformation(face, entity_path))
                mesh_group[1].append(face)
              else
                mesh = Geometry::Mesh.from_face(
                  speckle_state: speckle_state,
                  face: face, units: units, model_preferences: model_preferences,
                  global_transform: QUERY::Entity.global_transformation(face, entity_path),
                  parent_material: parent_material
                )
                mesh_groups[mesh_group_id] = [mesh, [face]]
              end
            end
            # Update mesh overwrites points and polygons into base object.
            mesh_groups.each { |_, mesh| mesh.first.update_mesh }
            mesh_groups.values
          end
          # rubocop:enable Metrics/MethodLength
        end
      end
    end
  end
end
