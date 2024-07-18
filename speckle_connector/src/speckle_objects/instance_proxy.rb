# frozen_string_literal: true

require_relative 'base'
require_relative '../constants/type_constants'
require_relative '../speckle_objects/other/transform'

module SpeckleConnector
  module SpeckleObjects
    class InstanceProxy < Base
      SPECKLE_TYPE = SPECKLE_CORE_MODELS_INSTANCES_INSTANCE_PROXY
      def initialize(definition_id, transform, max_depth, units, is_sketchup_group, application_id: nil)
        super(
          speckle_type: SPECKLE_TYPE,
          total_children_count: 0,
          application_id: application_id,
          id: nil
        )
        self[:units] = units
        self[:definitionId] = definition_id
        self[:maxDepth] = max_depth
        self[:transform] = transform
        self[:isSketchupGroup] = is_sketchup_group
      end

      # @param entities [Sketchup::Entities]
      def self.to_native(state, instance_proxy, layer, entities, definition_proxies, &_convert_to_native)
        definition_id = instance_proxy['definitionId']
        is_sketchup_group = instance_proxy['isSketchupGroup']
        proxy_transform = instance_proxy['transform']
        transform = Other::Transform.to_native(proxy_transform, instance_proxy['units'])
        definition = definition_proxies[definition_id].definition
        instance = if is_sketchup_group
                     # rubocop:disable SketchupSuggestions/AddGroup
                     definition.entities.to_a.any? ? entities.add_group : entities.add_group(definition.entities.to_a)
                     # rubocop:enable SketchupSuggestions/AddGroup
                   else
                     entities.add_instance(definition, transform)
                   end
        instance.layer = layer if layer
        instance.transformation = transform if is_sketchup_group # Transform already applied to instance unless is group
        return state, [instance, definition]
      end
    end
  end
end
