# frozen_string_literal: true

require_relative 'render_material'
require_relative 'transform'
require_relative 'block_instance'
require_relative '../base'
require_relative '../geometry/point'
require_relative '../geometry/mesh'
require_relative '../geometry/bounding_box'
require_relative '../../sketchup_model/dictionary/dictionary_handler'

module SpeckleConnector
  module SpeckleObjects
    module Other
      # BlockDefinition object definition for Speckle.
      class BlockDefinition < Base
        SPECKLE_TYPE = 'Objects.Other.BlockDefinition'

        # @param geometry [Object] geometric definition of the block.
        # @param base_point [Geometry::Point] base point of the block definition.
        # @param name [String] name of the block definition.
        # @param units [String] units of the block definition.
        # @param application_id [String, NilClass] application id of the block definition.
        # rubocop:disable Metrics/ParameterLists
        def initialize(geometry:, base_point:, name:, units:, always_face_camera:, sketchup_attributes: {},
                       application_id: nil)
          super(
            speckle_type: SPECKLE_TYPE,
            total_children_count: 0,
            application_id: application_id,
            id: nil
          )
          self[:units] = units
          self[:name] = name
          self[:basePoint] = base_point
          self[:always_face_camera] = always_face_camera
          self[:sketchup_attributes] = sketchup_attributes if sketchup_attributes.any?
          self['@geometry'] = geometry
        end
        # rubocop:enable Metrics/ParameterLists

        # @param definition [Sketchup::ComponentDefinition] component definition might be belong to group or component
        #  instance
        # @param units [String] units of the Sketchup model
        # @param definitions [Hash{String=>BlockDefinition}] all converted {BlockDefinition}s on the converter.
        # rubocop:disable Metrics/CyclomaticComplexity
        # rubocop:disable Metrics/PerceivedComplexity
        # rubocop:disable Metrics/MethodLength
        def self.from_definition(definition, units, definitions, preferences, &convert)
          guid = definition.guid
          return definitions[guid] if definitions.key?(guid)

          dictionaries = {}
          if preferences[:model][:include_entity_attributes]
            dictionaries = SketchupModel::Dictionary::DictionaryHandler.attribute_dictionaries_to_speckle(definition)
          end
          att = dictionaries.any? ? { dictionaries: dictionaries } : {}

          # TODO: Solve logic
          geometry = if definition.entities[0].is_a?(Sketchup::Edge) || definition.entities[0].is_a?(Sketchup::Face)
                       group_entities_to_speckle(definition, units, definitions, preferences, &convert)
                     else
                       definition.entities.map do |entity|
                         convert.call(entity, preferences) unless entity.is_a?(Sketchup::Edge) && entity.faces.any?
                       end
                     end

          # FIXME: Decide how to approach base point of the definition instead origin.
          BlockDefinition.new(
            units: units,
            name: definition.name,
            base_point: Geometry::Point.new(0, 0, 0, units),
            geometry: geometry,
            always_face_camera: definition.behavior.always_face_camera?,
            sketchup_attributes: att,
            application_id: guid
          )
        end
        # rubocop:enable Metrics/CyclomaticComplexity
        # rubocop:enable Metrics/PerceivedComplexity
        # rubocop:enable Metrics/MethodLength

        # Finds or creates a component definition from the geometry and the given name
        # @param sketchup_model [Sketchup::Model] sketchup model to check block definitions.
        # rubocop:disable Metrics/CyclomaticComplexity
        # rubocop:disable Metrics/PerceivedComplexity
        # rubocop:disable Metrics/ParameterLists
        def self.to_native(sketchup_model, geometry, layer, name, always_face_camera, model_preferences,
                           sketchup_attributes, application_id = '', &convert)
          definition = sketchup_model.definitions[name]
          return definition if definition && (definition.name == name || definition.guid == application_id)

          definition&.entities&.clear!
          definition ||= sketchup_model.definitions.add(name)
          definition.layer = layer
          if geometry.is_a?(Array)
            geometry.each { |obj| convert.call(obj, layer, model_preferences, definition.entities) }
          end
          if geometry.is_a?(Hash) && !geometry['speckle_type'].nil?
            convert.call(geometry, layer, model_preferences, definition.entities)
          end
          # puts("definition finished: #{name} (#{application_id})")
          # puts("    entity count: #{definition.entities.count}")
          definition.behavior.always_face_camera = always_face_camera
          unless sketchup_attributes.nil?
            SketchupModel::Dictionary::DictionaryHandler
              .attribute_dictionaries_to_native(definition, sketchup_attributes['dictionaries'])
          end
          definition
        end
        # rubocop:enable Metrics/CyclomaticComplexity
        # rubocop:enable Metrics/PerceivedComplexity
        # rubocop:enable Metrics/ParameterLists

        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Metrics/MethodLength
        # rubocop:disable Metrics/CyclomaticComplexity
        # rubocop:disable Metrics/PerceivedComplexity
        def self.group_entities_to_speckle(definition, units, definitions, preferences, &convert)
          orphan_edges = definition.entities.grep(Sketchup::Edge).filter { |edge| edge.faces.none? }
          lines = orphan_edges.collect do |orphan_edge|
            Geometry::Line.from_edge(orphan_edge, units, preferences[:model])
          end

          nested_blocks = definition.entities.grep(Sketchup::ComponentInstance).collect do |component_instance|
            BlockInstance.from_component_instance(component_instance, units, definitions, preferences, &convert)
          end

          nested_groups = definition.entities.grep(Sketchup::Group).collect do |group|
            BlockInstance.from_group(group, units, definitions, preferences, &convert)
          end

          if preferences[:model][:combine_faces_by_material]
            mesh_groups = {}
            definition.entities.grep(Sketchup::Face).collect do |face|
              group_meshes_by_material(definition, face, mesh_groups, units, preferences[:model])
            end

            lines + nested_blocks + nested_groups + mesh_groups.values
          else
            meshes = definition.entities.grep(Sketchup::Face).collect do |face|
              Geometry::Mesh.from_face(face, units, preferences[:model])
            end

            lines + nested_blocks + nested_groups + meshes
          end
        end
        # rubocop:enable Metrics/AbcSize
        # rubocop:enable Metrics/MethodLength
        # rubocop:enable Metrics/CyclomaticComplexity
        # rubocop:enable Metrics/PerceivedComplexity

        # rubocop:disable Metrics/AbcSize
        def self.group_meshes_by_material(definition, face, mat_groups, units, model_preferences)
          # convert material
          mat_id = get_mesh_group_id(face, model_preferences)
          mat_groups[mat_id] = initialise_group_mesh(face, definition.bounds, units) unless mat_groups.key?(mat_id)
          mat_group = mat_groups[mat_id]
          if face.loops.size > 1
            mesh = face.mesh
            mat_group[:'@(31250)vertices'].push(*Geometry::Mesh.mesh_points_to_array(mesh, units))
            mat_group[:'@(62500)faces'].push(*Geometry::Mesh.mesh_faces_to_array(mesh, mat_group[:pt_count] - 1))
            mat_group[:'@(31250)faceEdgeFlags'].push(*Geometry::Mesh.mesh_edge_flags_to_array(mesh))
          else
            mat_group[:'@(31250)vertices'].push(*Geometry::Mesh.face_vertices_to_array(face, units))
            mat_group[:'@(62500)faces'].push(*Geometry::Mesh.face_indices_to_array(face, mat_group[:pt_count]))
            mat_group[:'@(31250)faceEdgeFlags'].push(*Geometry::Mesh.face_edge_flags_to_array(face))
          end
          mat_group[:pt_count] += face.vertices.count
        end
        # rubocop:enable Metrics/AbcSize

        def self.initialise_group_mesh(face, bounds, units)
          has_any_soften_edge = face.edges.any?(&:soft?)
          mesh = Geometry::Mesh.new(
            units: units,
            render_material: face.material.nil? ? nil : RenderMaterial.from_material(face.material),
            bbox: Geometry::BoundingBox.from_bounds(bounds, units),
            vertices: [],
            faces: [],
            face_edge_flags: [],
            sketchup_attributes: { is_soften: has_any_soften_edge }
          )
          mesh[:pt_count] = 0
          mesh
        end

        # Mesh group id helps to determine how to group faces into meshes.
        # @param face [Sketchup::Face] face to get mesh group id.
        def self.get_mesh_group_id(face, model_preferences)
          if model_preferences[:include_entity_attributes]
            has_attribute_dictionary = !(face.attribute_dictionaries.nil? || face.attribute_dictionaries.first.nil?)
            return face.persistent_id.to_s if has_attribute_dictionary
          end

          material = face.material || face.back_material
          return 'none' if material.nil?

          return material.entityID.to_s
        end
      end
    end
  end
end
