# frozen_string_literal: true

require_relative '../../speckle_objects/instance_proxy'
require_relative '../../speckle_objects/instance_definition_proxy'
require_relative '../../speckle_objects/other/transform'

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

          # NOTE: we should let it create new proxy, otherwise we set depth value wrong in some cases.
          # It is not guaranteed definitions will be handled from max -> min or min -> max from selection.
          # if definition_proxies.key?(definition_id)
          #   if definition_proxies[definition_id][:MaxDepth] < depth
          #     definition_proxies[definition_id][:MaxDepth] = depth
          #   end
          #   return
          # end

          definition_proxy = SpeckleObjects::InstanceDefinitionProxy.new(entity.definition, [], depth, application_id: definition_id)
          definition_proxy[:name] = entity.definition.name
          definition_proxy[:description] = entity.definition.description

          definition_proxies[definition_id] = definition_proxy

          entity.definition.entities.each do |sub_ent|
            definition_proxy.add_object_id(sub_ent.persistent_id.to_s)
            if sub_ent.is_a?(Sketchup::ComponentInstance) || sub_ent.is_a?(Sketchup::Group)
              unpack_instance(sub_ent, depth + 1)
            end
            # FIXME: probably will need here local to global coordinate mapping
            flat_atomic_objects[sub_ent.persistent_id.to_s] = sub_ent
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
