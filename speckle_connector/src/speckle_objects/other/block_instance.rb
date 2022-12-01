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
          '@blockDefinition': Other::BlockDefinition,
          sketchup_attributes: Object
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

        # Creates a component instance from a block
        # @param sketchup_model [Sketchup::Model] sketchup model to check block definitions.
        # @param block [Object] block object that represents Speckle block.
        # @param layer [Sketchup::Layer] layer to add {Sketchup::Edge} into it.
        # @param entities [Sketchup::Entities] entities collection to add {Sketchup::Edge} into it.
        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Metrics/MethodLength
        def self.to_native(sketchup_model, block, layer, entities, &convert)
          # is_group = block.key?("is_sketchup_group") && block["is_sketchup_group"]
          # something about this conversion is freaking out if nested block geo is a group
          # so this is set to false always until I can figure this out
          is_group = false
          definition = BLOCK_DEFINITION.to_native(
            sketchup_model, block['blockDefinition']['geometry'], block['blockDefinition']['name'],
            block['blockDefinition']['applicationId'], convert
          )

          name = block['name'].nil? || block['name'].empty? ? block['id'] : block['name']
          t_arr = block['transform'].is_a?(Hash) ? block['transform']['value'] : block['transform']
          transform = Other::Transform.to_native(t_arr, block['units'])
          instance =
            if is_group
              # rubocop:disable SketchupSuggestions/AddGroup
              group = entities.add_group(definition.entities.to_a)
              group.layer = layer
              # rubocop:enable SketchupSuggestions/AddGroup
            else
              instance = entities.add_instance(definition, transform)
              instance.layer = layer
            end
          # erase existing instances after creation and before rename because you can't have definitions
          #  without instances
          find_and_erase_existing_instance(definition, name, block['applicationId'])
          puts("Failed to create instance for speckle block instance #{block['id']}") if instance.nil?
          instance.transformation = transform if is_group
          instance.material = Other::RenderMaterial.to_native(sketchup_model, block['renderMaterial'])
          instance.name = name
          instance
        end
        # rubocop:enable Metrics/AbcSize
        # rubocop:enable Metrics/MethodLength

        # takes a component definition and finds and erases the first instance with the matching name
        # (and optionally the applicationId)
        def self.find_and_erase_existing_instance(definition, name, app_id = '')
          definition.instances.find { |ins| ins.name == name || ins.guid == app_id }&.erase!
        end

        private

        def attribute_types
          ATTRIBUTE_TYPES
        end
      end
    end
  end
end
