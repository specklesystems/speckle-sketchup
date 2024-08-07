# frozen_string_literal: true

require_relative 'base'
require_relative '../constants/type_constants'

module SpeckleConnector3
  module SpeckleObjects
    # A proxy class for an render materials.
    class RenderMaterialProxy < Base
      SPECKLE_TYPE = SPECKLE_CORE_OTHER_RENDER_MATERIAL_PROXY

      # @return [Sketchup::Material]
      attr_reader :sketchup_material

      # @return [SpeckleObjects::Other::RenderMaterial]
      attr_reader :value

      # @return [Array<String>] The original ids of the objects that has render material
      attr_reader :object_ids

      # @param sketchup_material [Sketchup::Material]
      # @param object_ids [Array<String>]
      # @param application_id [String | NilClass]
      def initialize(sketchup_material, value, object_ids, application_id: nil)
        super(
          speckle_type: SPECKLE_TYPE,
          total_children_count: 0,
          application_id: application_id,
          id: nil
        )
        @sketchup_material = sketchup_material
        @object_ids = object_ids
        @value = value
        self[:value] = value
        self[:objects] = object_ids
      end

      # @param object_id [String] application id of the object to add into proxy list
      def add_object_id(object_id)
        object_ids.append(object_id)
        self[:objects] = object_ids
      end
    end
  end
end
