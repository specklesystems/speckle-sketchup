# frozen_string_literal: true

require_relative 'render_material'
require_relative 'transform'
require_relative 'block_definition'
require_relative '../base'
require_relative '../geometry/bounding_box'
require_relative '../../sketchup_model/dictionary/dictionary_handler'

module SpeckleConnector
  module SpeckleObjects
    module Other
      # BlockInstance object definition for Speckle.
      class BlockInstance < Base
        SPECKLE_TYPE = 'Objects.Other.BlockInstance'

        # @param units [String] units of the block instance.
        # @param is_sketchup_group [Boolean] whether is sketchup group or not. Sketchup Groups represented as
        #  block instance on Speckle.
        # @param name [String] name of the block instance.
        # @param transform [Other::Transform] transform of the block instance.
        # @param block_definition [Other::BlockDefinition] definition of the block instance.
        # @param sketchup_attributes [Hash{Symbol=>Object}] sketchup attributes of the block instance.
        # @param application_id [String] application id of the block instance.
        # rubocop:disable Metrics/ParameterLists
        def initialize(units:, is_sketchup_group:, name:, render_material:, transform:, block_definition:,
                       sketchup_attributes: {}, application_id: nil)
          super(
            speckle_type: SPECKLE_TYPE,
            total_children_count: 0,
            application_id: application_id,
            id: nil
          )
          self[:units] = units
          self[:name] = name
          self[:is_sketchup_group] = is_sketchup_group
          self[:renderMaterial] = render_material
          self[:transform] = transform
          self[:sketchup_attributes] = sketchup_attributes if sketchup_attributes.any?
          self['@blockDefinition'] = block_definition
        end
        # rubocop:enable Metrics/ParameterLists

        # @param group [Sketchup::Group] group to convert Speckle BlockInstance
        def self.from_group(group, units, component_defs, preferences, &convert)
          dictionaries = {}
          if preferences[:model][:include_entity_attributes]
            dictionaries = SketchupModel::Dictionary::DictionaryHandler.attribute_dictionaries_to_speckle(group)
          end
          att = dictionaries.any? ? { dictionaries: dictionaries } : {}
          BlockInstance.new(
            units: units,
            is_sketchup_group: true,
            name: group.name == '' ? nil : group.name,
            render_material: group.material.nil? ? nil : RenderMaterial.from_material(group.material),
            transform: Other::Transform.from_transformation(group.transformation, units),
            block_definition: BlockDefinition.from_definition(group.definition, units, component_defs,
                                                              preferences, &convert),
            sketchup_attributes: att,
            application_id: group.guid
          )
        end

        # @param component_instance [Sketchup::ComponentInstance] component instance to convert Speckle BlockInstance
        # rubocop:disable Metrics/MethodLength
        def self.from_component_instance(component_instance, units, component_defs, preferences, &convert)
          dictionaries = {}
          if preferences[:model][:include_entity_attributes]
            dictionaries = SketchupModel::Dictionary::DictionaryHandler
                           .attribute_dictionaries_to_speckle(component_instance)
          end
          att = dictionaries.any? ? { dictionaries: dictionaries } : {}
          BlockInstance.new(
            units: units,
            is_sketchup_group: false,
            name: component_instance.name == '' ? nil : component_instance.name,
            render_material: if component_instance.material.nil?
                               nil
                             else
                               RenderMaterial.from_material(component_instance.material)
                             end,
            transform: Other::Transform.from_transformation(component_instance.transformation, units),
            block_definition: BlockDefinition.from_definition(component_instance.definition, units, component_defs,
                                                              preferences, &convert),
            sketchup_attributes: att,
            application_id: component_instance.guid
          )
        end
        # rubocop:enable Metrics/MethodLength

        # Creates a component instance from a block
        # @param sketchup_model [Sketchup::Model] sketchup model to check block definitions.
        # @param block [Object] block object that represents Speckle block.
        # @param layer [Sketchup::Layer] layer to add {Sketchup::Edge} into it.
        # @param entities [Sketchup::Entities] entities collection to add {Sketchup::Edge} into it.
        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Metrics/MethodLength
        # rubocop:disable Metrics/ParameterLists
        # rubocop:disable Metrics/CyclomaticComplexity
        # rubocop:disable Metrics/PerceivedComplexity
        def self.to_native(sketchup_model, block, layer, entities, model_preferences, &convert)
          # is_group = block.key?("is_sketchup_group") && block["is_sketchup_group"]
          # something about this conversion is freaking out if nested block geo is a group
          # so this is set to false always until I can figure this out
          is_group = false
          # is_group = block['is_sketchup_group']
          block_definition = block['@blockDefinition'] || block['blockDefinition']
          definition = BlockDefinition.to_native(
            sketchup_model,
            block_definition['@geometry'],
            layer,
            block_definition['name'],
            block_definition['always_face_camera'].nil? ? false : block_definition['always_face_camera'],
            model_preferences,
            block_definition['sketchup_attributes'],
            block_definition['applicationId'],
            &convert
          )

          instance_name = block['name'].nil? || block['name'].empty? ? block['id'] : block['name']
          t_arr = block['transform'].is_a?(Hash) ? block['transform']['value'] : block['transform']
          transform = Other::Transform.to_native(t_arr, block['units'])
          instance = if is_group
                       # rubocop:disable SketchupSuggestions/AddGroup
                       group = entities.add_group(definition.entities.to_a)
                       group.layer = layer
                       group
                       # rubocop:enable SketchupSuggestions/AddGroup
                     else
                       instance = entities.add_instance(definition, transform)
                       instance.layer = layer
                       instance
                     end

          # erase existing instances after creation and before rename because you can't have definitions
          #  without instances
          find_and_erase_existing_instance(definition, instance_name, block['applicationId'])
          puts("Failed to create instance for speckle block instance #{block['id']}") if instance.nil?
          instance.transformation = transform if is_group
          instance.material = Other::RenderMaterial.to_native(sketchup_model, block['renderMaterial'])
          instance.name = instance_name
          unless block['sketchup_attributes'].nil?
            SketchupModel::Dictionary::DictionaryHandler
              .attribute_dictionaries_to_native(instance, block['sketchup_attributes']['dictionaries'])
          end
          instance
        end
        # rubocop:enable Metrics/AbcSize
        # rubocop:enable Metrics/MethodLength
        # rubocop:enable Metrics/ParameterLists
        # rubocop:enable Metrics/CyclomaticComplexity
        # rubocop:enable Metrics/PerceivedComplexity

        # takes a component definition and finds and erases the first instance with the matching name
        # (and optionally the applicationId)
        def self.find_and_erase_existing_instance(definition, name, app_id = '')
          definition.instances.find { |ins| ins.name == name || ins.guid == app_id }&.erase!
        end
      end
    end
  end
end
