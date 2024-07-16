# frozen_string_literal: true

require_relative '../../speckle_objects/instance_proxy'
require_relative '../../speckle_objects/instance_definition_proxy'
require_relative '../../speckle_objects/other/transform'
require_relative '../../speckle_objects/geometry/grouped_mesh'

module SpeckleConnector
  # Operations related to {SketchupModel}.
  module SketchupModel
    # Definition related utilities.
    module Definitions
      # Handle definitions with its parents (component or group) and children with proxies.
      class DefinitionManager
        # @return [Hash{String=>SpeckleObjects::InstanceProxy}] instance proxies.
        attr_reader :instance_proxies

        # @return [Hash{String=>SpeckleObjects::InstanceDefinitionProxy}] instance definition proxies.
        attr_reader :definition_proxies

        # @return [Hash{String=>Array<SpeckleObjects::InstanceProxy>}] instance proxies by definition id.
        attr_reader :instance_proxies_by_definition_id

        # @return [Hash{String=>Sketchup::Entity}] atomic objects.
        attr_reader :flat_atomic_objects

        def initialize(units)
          @instance_proxies = {}
          @definition_proxies = {}
          @instance_proxies_by_definition_id = {}
          @flat_atomic_objects = {}
          @units = units
        end

        # @param entities [Array<Sketchup::Entity>] entities to unpack
        def unpack_entities(entities)
          entities.each do |entity|
            unpack_instance(entity) if entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group)
            flat_atomic_objects[entity.persistent_id.to_s] = entity
          end
          UnpackResult.new(flat_atomic_objects.values, instance_proxies, definition_proxies.values)
        end

        # @param entity [Sketchup::ComponentInstance, Sketchup::Group] instance to unpack
        def unpack_instance(entity, depth = 0)
          instance_id = entity.persistent_id.to_s
          definition_id = entity.definition.persistent_id.to_s

          instance_proxies[instance_id] = SpeckleObjects::InstanceProxy.new(
            definition_id,
            SpeckleObjects::Other::Transform.from_transformation(entity.transformation, @units).value,
            depth,
            @units,
            application_id: instance_id
          )

          unless instance_proxies_by_definition_id.key?(definition_id)
            instance_proxies_by_definition_id[definition_id] = []
          end

          instance_proxies_with_same_definition = instance_proxies_by_definition_id[definition_id]
          instance_proxies_with_same_definition.each do |item|
            item[:MaxDepth] = depth if item[:MaxDepth] < depth # only set if given depth is higher.
          end
          instance_proxies_with_same_definition.append(instance_proxies[instance_id])

          if definition_proxies.key?(definition_id)
            diff = depth - definition_proxies[definition_id][:MaxDepth]
            update_children_max_depth(definition_proxies[definition_id], diff) if diff > 0
            return
          end

          definition_proxy = SpeckleObjects::InstanceDefinitionProxy.new(entity.definition, [], depth, application_id: definition_id)
          definition_proxy[:name] = entity.definition.name
          definition_proxy[:description] = entity.definition.description

          definition_proxies[definition_id] = definition_proxy

          # Group meshes
          faces = entity.definition.entities.grep(Sketchup::Face)
          unless faces.empty?
            grouped_meshes = faces.group_by { |face| [face.layer, face.material || face.back_material] }
            grouped_meshes.each do |(layer, mat), faces|
              material_id = mat.nil? ? 'none' : mat.persistent_id.to_s
              grouped_mesh_id = "#{layer.name} - #{material_id}"
              grouped_mesh = SpeckleObjects::Geometry::GroupedMesh.new(faces, layer, mat, grouped_mesh_id)
              flat_atomic_objects[grouped_mesh.persistent_id] = grouped_mesh
            end
          end

          entity.definition.entities.reject { |e| e.is_a?(Sketchup::Face) }.each do |sub_ent|
            # sketchup specific logic that we exclude edges that belongs to any face.
            next if sub_ent.is_a?(Sketchup::Edge) && sub_ent.faces.any?

            definition_proxy.add_object_id(sub_ent.persistent_id.to_s)
            if sub_ent.is_a?(Sketchup::ComponentInstance) || sub_ent.is_a?(Sketchup::Group)
              unpack_instance(sub_ent, depth + 1)
            end

            flat_atomic_objects[sub_ent.persistent_id.to_s] = sub_ent
          end
        end

        # @param definition_proxy [SpeckleObjects::InstanceDefinitionProxy]
        # @param depth_difference [Integer]
        def update_children_max_depth(definition_proxy, depth_difference)
          # Increase depth of definition
          definition_proxy[:MaxDepth] += depth_difference

          # Find instance proxies of given definition
          definition_instance_proxies = definition_proxy[:Objects].collect { |id| instance_proxies[id] }.compact

          # Break the loop if no instance proxy found under definition.
          return if definition_instance_proxies.empty?

          sub_definitions = {}
          definition_instance_proxies.each do |instance_proxy|
            # Increase depth of instance
            instance_proxy[:MaxDepth] += depth_difference
            # Collect sub definitions
            sub_definitions[instance_proxy[:DefinitionId]] = definition_proxies[instance_proxy[:DefinitionId]]
          end

          # Iterate through sub definitions
          sub_definitions.each_value do |sub_definition|
            update_children_max_depth(sub_definition, depth_difference)
          end
        end
      end

      # Data class to represent result of unpacking.
      class UnpackResult
        attr_reader :atomic_objects

        attr_reader :instance_proxies

        attr_reader :instance_definition_proxies

        def initialize(atomic_objects, instance_proxies, instance_definition_proxies)
          @atomic_objects = atomic_objects
          @instance_proxies = instance_proxies
          @instance_definition_proxies = instance_definition_proxies
        end
      end
    end
  end
end
