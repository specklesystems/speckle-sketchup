# frozen_string_literal: true

require_relative 'render_material'
require_relative 'transform'
require_relative 'block_instance'
require_relative '../base'
require_relative '../geometry/point'
require_relative '../geometry/mesh'
require_relative '../geometry/bounding_box'

module SpeckleConnector
  module SpeckleObjects
    module Other
      # BlockDefinition object definition for Speckle.
      class BlockDefinition < Base
        SPECKLE_TYPE = 'Objects.Other.BlockDefinition'

        def initialize(geometry:, base_point:, name:, units:, application_id: nil)
          super(
            speckle_type: SPECKLE_TYPE,
            total_children_count: 0,
            application_id: application_id,
            id: nil
          )
          self[:units] = units
          self[:name] = name
          self[:basePoint] = base_point
          self['@geometry'] = geometry
        end

        # @param definition [Sketchup::ComponentDefinition] component definition might be belong to group or component
        #  instance
        # @param units [String] units of the Sketchup model
        # @param definitions [Hash{String=>BlockDefinition}] all converted {BlockDefinition}s on the converter.
        def self.from_definition(definition, units, definitions, &convert)
          guid = definition.guid
          return definitions[guid] if definitions.key?(guid)

          # TODO: Solve logic
          geometry = if definition.entities[0].is_a?(Sketchup::Edge) | definition.entities[0].is_a?(Sketchup::Face)
                       group_mesh_to_speckle(definition, units, definitions)
                     else
                       definition.entities.map { |entity| convert.call(entity) }
                     end

          BlockDefinition.new(
            units: units,
            name: definition.name,
            base_point: Geometry::Point.new(0, 0, 0, units),
            geometry: geometry,
            application_id: guid
          )
        end

        # Finds or creates a component definition from the geometry and the given name
        # @param sketchup_model [Sketchup::Model] sketchup model to check block definitions.
        # rubocop:disable Metrics/CyclomaticComplexity
        # rubocop:disable Metrics/ParameterLists
        def self.to_native(sketchup_model, geometry, layer, name, application_id = '', &convert)
          definition = sketchup_model.definitions[name]
          return definition if definition && (definition.name == name || definition.guid == application_id)

          definition&.entities&.clear!
          definition ||= sketchup_model.definitions.add(name)
          definition.layer = layer
          geometry.each { |obj| convert.call(obj, layer, definition.entities) }
          puts("definition finished: #{name} (#{application_id})")
          # puts("    entity count: #{definition.entities.count}")
          definition
        end
        # rubocop:enable Metrics/CyclomaticComplexity
        # rubocop:enable Metrics/ParameterLists

        def self.group_mesh_to_speckle(definition, units, definitions)
          # {material_id => Mesh}
          mat_groups = {}
          nested_blocks = []
          lines = []

          definition.entities.each do |entity|
            if entity.is_a?(Sketchup::ComponentInstance)
              nested_blocks.push(BlockInstance.from_component_instance(entity, units, definitions))
            end
            next unless entity.is_a?(Sketchup::Face)

            group_meshes_by_material(definition, entity, mat_groups, units)
          end

          mat_groups.values.map { |group| group.delete(:pt_count) }
          mat_groups.values + lines + nested_blocks
        end

        # rubocop:disable Metrics/AbcSize
        def self.group_meshes_by_material(definition, face, mat_groups, units)
          # convert material
          mat_id = face.material.nil? ? 'none' : face.material.entityID
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
            sketchup_attributes: { is_soften: has_any_soften_edge },
          )
          mesh[:pt_count] = 0
          mesh
        end
      end
    end
  end
end
