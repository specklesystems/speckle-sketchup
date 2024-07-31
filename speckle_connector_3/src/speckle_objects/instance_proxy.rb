# frozen_string_literal: true

require_relative 'base'
require_relative '../constants/type_constants'
require_relative '../speckle_objects/other/transform'

module SpeckleConnector3
  module SpeckleObjects
    class InstanceProxy < Base
      SPECKLE_TYPE = SPECKLE_CORE_MODELS_INSTANCES_INSTANCE_PROXY
      def initialize(definition_id, transform, max_depth, units, application_id: nil)
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
      end

      def self.to_native(state, instance_proxy, layer, entities, definition_proxies, &_convert_to_native)
        definition_id = instance_proxy['definitionId']
        proxy_transform = instance_proxy['transform']
        transform = Other::Transform.to_native(proxy_transform, instance_proxy['units'])
        definition = definition_proxies[definition_id].definition
        instance = entities.add_instance(definition, transform)
        instance.layer = layer if layer # TODO: CONVERTER_V2 check
        # TODO: CONVERTER_V2 handle groups
        return state, [instance, definition]
      end
    end
  end
end
