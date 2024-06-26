# frozen_string_literal: true

require_relative 'base'
require_relative '../constants/type_constants'

module SpeckleConnector
  module SpeckleObjects
    # A proxy class for an instance definition.
    class InstanceDefinitionProxy < Base
      SPECKLE_TYPE = SPECKLE_CORE_MODELS_INSTANCES_INSTANCE_DEFINITION_PROXY

      # @return [Sketchup::ComponentDefinition] definition in sketchup represented as proxy
      attr_reader :definition

      # @return [Array<String>] The original ids of the objects that are part of this definition, as present in the
      # source host app. On receive, they will be mapped to corresponding newly created definition ids.
      attr_reader :object_ids

      def initialize(definition, object_ids, max_depth, application_id: nil)
        super(
          speckle_type: SPECKLE_TYPE,
          total_children_count: 0,
          application_id: application_id,
          id: nil
        )
        @definition = definition
        @object_ids = object_ids
        self[:Objects] = object_ids
        self[:MaxDepth] = max_depth
      end

      def add_object_id(object_id)
        object_ids.append(object_id)
        self[:Objects] = object_ids
      end
    end
  end
end
