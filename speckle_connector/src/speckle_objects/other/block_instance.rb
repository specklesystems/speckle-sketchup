# frozen_string_literal: true

require_relative 'render_material'
require_relative 'transform'
require_relative 'block_definition'
require_relative '../geometry/bounding_box'
require_relative '../../typescript/typescript_object'

module SpeckleConnector
  module SpeckleObjects
    module Other
      # BlockInstance object definition for Speckle.
      class BlockInstance < Typescript::TypescriptObject
        SPECKLE_TYPE = 'Objects.Other.BlockInstance'
        ATTRIBUTE_TYPES = {
          speckle_type: String,
          units: String,
          applicationId: String,
          is_sketchup_group: [TrueClass, FalseClass],
          bbox: Geometry::BoundingBox,
          name: [String, NilClass],
          renderMaterial: [Other::RenderMaterial, NilClass],
          transform: Other::Transform,
          '@blockDefinition': Other::BlockDefinition
        }.freeze

        # @param group [Sketchup::Group] group to convert Speckle BlockInstance
        def self.from_group(group, units, component_defs)
          BlockInstance.new(
            speckle_type: SPECKLE_TYPE,
            units: units,
            applicationId: group.guid,
            is_sketchup_group: true,
            bbox: Geometry::BoundingBox.from_bounds(group.bounds, units),
            name: group.name == '' ? nil : group.name,
            renderMaterial: group.material.nil? ? nil : RenderMaterial.from_material(group.material),
            transform: Other::Transform.from_transformation(group.transformation, units),
            '@blockDefinition': BlockDefinition.from_definition(group.definition, units, component_defs)
          )
        end

        # @param component_instance [Sketchup::ComponentInstance] component instance to convert Speckle BlockInstance
        def self.from_component_instance(component_instance, units, component_defs)
          BlockInstance.new(
            speckle_type: SPECKLE_TYPE,
            units: units,
            applicationId: component_instance.guid,
            is_sketchup_group: false,
            bbox: Geometry::BoundingBox.from_bounds(component_instance.bounds, units),
            name: component_instance.name == '' ? nil : component_instance.name,
            renderMaterial: component_instance.material.nil? ? nil : RenderMaterial.from_material(group.material),
            transform: Other::Transform.from_transformation(component_instance.transformation, units),
            '@blockDefinition': BlockDefinition.from_definition(component_instance.definition, units, component_defs)
          )
        end

        private

        def attribute_types
          ATTRIBUTE_TYPES
        end
      end
    end
  end
end
