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
          # FIXME: Since blockDefinition sends with @ as detached, block basePlane renders on viewer.
          self['@@definition'] = block_definition
        end
        # rubocop:enable Metrics/ParameterLists

        # @param group [Sketchup::Group] group to convert Speckle BlockInstance
        def self.from_group(group, units, preferences, speckle_state, &convert)
          new_speckle_state, block_definition = convert.call(group.definition, preferences, speckle_state,
                                                             group.persistent_id)
          speckle_state = new_speckle_state
          dictionaries = {}
          if preferences[:model][:include_entity_attributes] && preferences[:model][:include_group_entity_attributes]
            dictionaries = SketchupModel::Dictionary::DictionaryHandler.attribute_dictionaries_to_speckle(group)
          end
          att = dictionaries.any? ? { dictionaries: dictionaries } : {}

          block_instance = BlockInstance.new(
            units: units,
            is_sketchup_group: true,
            name: group.name == '' ? nil : group.name,
            render_material: group.material.nil? ? nil : RenderMaterial.from_material(group.material),
            transform: Other::Transform.from_transformation(group.transformation, units),
            block_definition: block_definition,
            sketchup_attributes: att,
            application_id: group.guid
          )
          return speckle_state, block_instance
        end

        # @param component_instance [Sketchup::ComponentInstance] component instance to convert Speckle BlockInstance
        # rubocop:disable Metrics/MethodLength
        def self.from_component_instance(component_instance, units, preferences, speckle_state, &convert)
          new_speckle_state, block_definition = convert.call(
            component_instance.definition,
            preferences,
            speckle_state,
            component_instance.persistent_id
          )
          speckle_state = new_speckle_state

          dictionaries = {}
          if preferences[:model][:include_entity_attributes] &&
             preferences[:model][:include_component_entity_attributes]
            dictionaries = SketchupModel::Dictionary::DictionaryHandler
                           .attribute_dictionaries_to_speckle(component_instance)
          end
          att = dictionaries.any? ? { dictionaries: dictionaries } : {}

          block_instance = BlockInstance.new(
            units: units,
            is_sketchup_group: false,
            name: component_instance.name == '' ? nil : component_instance.name,
            render_material: if component_instance.material.nil?
                               nil
                             else
                               RenderMaterial.from_material(component_instance.material)
                             end,
            transform: Other::Transform.from_transformation(component_instance.transformation, units),
            block_definition: block_definition,
            sketchup_attributes: att,
            application_id: component_instance.persistent_id.to_s
          )
          return speckle_state, block_instance
        end
        # rubocop:enable Metrics/MethodLength

        # Creates a component instance from a block
        # @param state [States::State] state of the application.
        # @param block [Object] block object that represents Speckle block.
        # @param layer [Sketchup::Layer] layer to add {Sketchup::Edge} into it.
        # @param entities [Sketchup::Entities] entities collection to add {Sketchup::Edge} into it.
        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Metrics/MethodLength
        # rubocop:disable Metrics/CyclomaticComplexity
        # rubocop:disable Metrics/PerceivedComplexity
        # rubocop:disable Metrics/ParameterLists
        def self.to_native(state, block, layer, entities, stream_id, &convert_to_native)
          # is_group = block.key?("is_sketchup_group") && block["is_sketchup_group"]
          # something about this conversion is freaking out if nested block geo is a group
          # so this is set to false always until I can figure this out
          is_group = false
          # is_group = block['is_sketchup_group']
          # NOTE: nil checks for backward compatibility
          block_definition = block['definition'] || block['blockDefinition'] || block['@blockDefinition']
          new_state = BlockDefinition.to_native(
            state,
            block_definition,
            layer,
            entities,
            stream_id,
            &convert_to_native
          )

          definition = new_state.sketchup_state.sketchup_model
                                .definitions[BlockDefinition.get_definition_name(block_definition)]

          t_arr = get_transform_matrix(block)
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
          find_and_erase_existing_instance(definition, block['id'], block['applicationId'])
          puts("Failed to create instance for speckle block instance #{block['id']}") if instance.nil?
          instance.transformation = transform if is_group
          new_state = Other::RenderMaterial.to_native(new_state, block['renderMaterial'],
                                                      layer, entities, stream_id, &convert_to_native)

          # Retrieve material from state
          unless block['renderMaterial'].nil?
            material_name = block['renderMaterial']['name'] || block['renderMaterial']['id']
            material = new_state.sketchup_state.materials.by_id(material_name)
            instance.material = material
          end

          instance.name = block['name'] unless block['name'].nil?
          unless block['sketchup_attributes'].nil?
            SketchupModel::Dictionary::DictionaryHandler
              .attribute_dictionaries_to_native(instance, block['sketchup_attributes']['dictionaries'])
          end
          instance_to_speckle_entity(new_state, instance, block, stream_id)
        end
        # rubocop:enable Metrics/AbcSize
        # rubocop:enable Metrics/MethodLength
        # rubocop:enable Metrics/CyclomaticComplexity
        # rubocop:enable Metrics/PerceivedComplexity
        # rubocop:enable Metrics/ParameterLists

        def self.get_transform_matrix(block)
          if block['transform'].is_a?(Hash)
            block['transform']['matrix'] || block['transform']['value']
          else
            block['transform']
          end
        end

        def self.instance_to_speckle_entity(state, instance, speckle_instance, stream_id)
          return state unless state.user_state.user_preferences[:register_speckle_entity]

          speckle_id = speckle_instance['id']
          speckle_type = speckle_instance['speckle_type']
          children = speckle_instance['__closure'].nil? ? [] : speckle_instance['__closure']
          ent = SpeckleEntities::SpeckleEntity.new(instance, speckle_id, speckle_type, children, [stream_id])
          ent.write_initial_base_data
          new_speckle_state = state.speckle_state.with_speckle_entity(ent)
          state.with_speckle_state(new_speckle_state)
        end

        # takes a component definition and finds and erases the first instance with the matching name
        # (and optionally the applicationId)
        # rubocop:disable Metrics/PerceivedComplexity
        # rubocop:disable Metrics/CyclomaticComplexity
        def self.find_and_erase_existing_instance(definition, upcoming_speckle_id, upcoming_app_id = '')
          definition.instances.find do |ins|
            next if ins.attribute_dictionaries.nil?
            next if ins.attribute_dictionaries.to_a.empty?
            next if ins.attribute_dictionaries.to_a.none? { |dict| dict.name == SPECKLE_BASE_OBJECT }

            dict = ins.attribute_dictionaries.to_a.find { |d| d.name == SPECKLE_BASE_OBJECT }
            speckle_id = dict[:speckle_id]
            application_id = dict[:application_id]
            speckle_id == upcoming_speckle_id || application_id == upcoming_app_id
          end&.erase!
        end
        # rubocop:enable Metrics/PerceivedComplexity
        # rubocop:enable Metrics/CyclomaticComplexity
      end
    end
  end
end
