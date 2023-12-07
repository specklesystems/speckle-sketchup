# frozen_string_literal: true

require_relative 'render_material'
require_relative 'transform'
require_relative 'block_definition'
require_relative '../base'
require_relative '../geometry/bounding_box'
require_relative '../other/mapped_block_wrapper'
require_relative '../built_elements/revit/family_instance'
require_relative '../../sketchup_model/dictionary/base_dictionary_handler'
require_relative '../../sketchup_model/dictionary/speckle_schema_dictionary_handler'
require_relative '../../sketchup_model/query/layer'

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
        def initialize(units:, is_sketchup_group:, name:, render_material:, transform:, block_definition:, layer:,
                       sketchup_attributes: {}, speckle_schema: {}, application_id: nil)
          super(
            speckle_type: SPECKLE_TYPE,
            total_children_count: 0,
            application_id: application_id,
            id: nil
          )
          self[:units] = units
          self[:name] = name
          self[:layer] = layer
          self[:is_sketchup_group] = is_sketchup_group
          self[:renderMaterial] = render_material
          self[:transform] = transform
          self[:sketchup_attributes] = sketchup_attributes if sketchup_attributes.any?
          self[:speckle_schema] = speckle_schema if speckle_schema.any?
          # FIXME: Since blockDefinition sends with @ as detached, block basePlane renders on viewer.
          self['@@definition'] = block_definition
        end
        # rubocop:enable Metrics/ParameterLists

        # @param group [Sketchup::Group] group to convert Speckle BlockInstance
        def self.from_group(group, units, preferences, speckle_state, &convert)
          new_speckle_state, block_definition = convert.call(group.definition, preferences, speckle_state,
                                                             group.persistent_id)
          speckle_state = new_speckle_state
          dictionaries = SketchupModel::Dictionary::BaseDictionaryHandler
                         .attribute_dictionaries_to_speckle(group, preferences[:model])
          att = dictionaries.any? ? { dictionaries: dictionaries } : {}
          speckle_schema = SketchupModel::Dictionary::SpeckleSchemaDictionaryHandler.speckle_schema_to_speckle(group)
          block_instance = BlockInstance.new(
            units: units,
            is_sketchup_group: true,
            name: group.name == '' ? nil : group.name,
            render_material: group.material.nil? ? nil : RenderMaterial.from_material(group.material),
            transform: Other::Transform.from_transformation(group.transformation, units),
            block_definition: block_definition,
            layer: SketchupModel::Query::Layer.entity_path(group),
            sketchup_attributes: att,
            speckle_schema: speckle_schema,
            application_id: group.guid
          )
          return speckle_state, block_instance
        end

        # @param component_instance [Sketchup::ComponentInstance] component instance to convert Speckle BlockInstance
        # rubocop:disable Metrics/MethodLength
        def self.from_component_instance(component_instance, units, preferences, speckle_state, path: nil, &convert)
          new_speckle_state, block_definition = convert.call(
            component_instance.definition,
            preferences,
            speckle_state,
            component_instance.persistent_id
          )
          speckle_state = new_speckle_state

          dictionaries = SketchupModel::Dictionary::BaseDictionaryHandler
                         .attribute_dictionaries_to_speckle(component_instance, preferences)
          att = dictionaries.any? ? { dictionaries: dictionaries } : {}
          speckle_schema = SketchupModel::Dictionary::SpeckleSchemaDictionaryHandler
                           .speckle_schema_to_speckle(component_instance)

          if speckle_schema.empty?
            speckle_schema = SketchupModel::Dictionary::SpeckleSchemaDictionaryHandler
                             .speckle_schema_to_speckle(component_instance.definition)
          end

          # transform into global if any path provided
          transformation = component_instance.transformation
          transformation = SketchupModel::Query::Entity.global_transformation(component_instance, path) if path

          block_instance = BlockInstance.new(
            units: units,
            is_sketchup_group: false,
            name: component_instance.name == '' ? nil : component_instance.name,
            render_material: if component_instance.material.nil?
                               nil
                             else
                               RenderMaterial.from_material(component_instance.material)
                             end,
            transform: Other::Transform.from_transformation(transformation, units),
            block_definition: block_definition,
            layer: SketchupModel::Query::Layer.entity_path(component_instance),
            sketchup_attributes: att,
            speckle_schema: speckle_schema,
            application_id: component_instance.persistent_id.to_s
          )

          if speckle_schema
            case speckle_schema['method']
            when 'New Revit Family'
              # duplicate already converted one to attach without speckle schema into mapped block wrapper
              copy_block_instance = block_instance.clone(freeze: true)
              block_instance['@SpeckleSchema'] = SpeckleObjects::Other::MappedBlockWrapper.new(
                category: speckle_schema['category'],
                units: units,
                instance: copy_block_instance,
                application_id: component_instance.persistent_id.to_s
              )
            when 'Family Instance'
              level = speckle_state.speckle_mapper_state.mapper_source
                                   .levels.find { |l| l[:name] == speckle_schema['level'] }
              family = speckle_schema['family']
              type = speckle_schema['family_type']
              block_instance['@SpeckleSchema'] = SpeckleObjects::BuiltElements::Revit::FamilyInstance.new(
                family: family,
                type: type,
                level: level,
                units: units,
                base_point: SpeckleObjects::Geometry::Point
                              .from_vertex(component_instance.bounds.min.transform(transformation), units),
                rotation: calculate_rotation(transformation.to_a),
                application_id: component_instance.persistent_id.to_s
              )
            end
          end

          return speckle_state, block_instance
        end
        # rubocop:enable Metrics/MethodLength

        # Creates a component instance from a block
        # @param state [States::State] state of the application.
        # @param block [Object] block object that represents Speckle block.
        # @param layer [Sketchup::Layer] layer to add {Sketchup::Edge} into it.
        # @param entities [Sketchup::Entities] entities collection to add {Sketchup::Edge} into it.
        def self.to_native(state, block, layer, entities, &convert_to_native)
          # is_group = block.key?("is_sketchup_group") && block["is_sketchup_group"]
          # something about this conversion is freaking out if nested block geo is a group
          # so this is set to false always until I can figure this out
          is_group = false
          # is_group = block['is_sketchup_group']
          # NOTE: nil checks for backward compatibility
          block_definition = block['definition'] || block['blockDefinition'] || block['@blockDefinition']

          state, _definitions = BlockDefinition.to_native(
            state,
            block_definition,
            layer,
            entities,
            &convert_to_native
          )

          definition = state.sketchup_state.sketchup_model
                            .definitions[BlockDefinition.get_definition_name(block_definition)]

          block_layer_name = SketchupModel::Query::Layer.entity_layer_from_path(block['layer'])
          block_layer = state.sketchup_state.sketchup_model.layers.to_a.find { |l| l.display_name == block_layer_name }
          return add_instance_from_definition(state, block, block_layer, layer, entities, definition, is_group,
                                              &convert_to_native)
        end

        def self.get_transform_matrix(block)
          if block['transform'].is_a?(Hash)
            block['transform']['matrix'] || block['transform']['value']
          else
            block['transform']
          end
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

        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Metrics/MethodLength
        # rubocop:disable Metrics/CyclomaticComplexity
        # rubocop:disable Metrics/PerceivedComplexity
        # rubocop:disable Metrics/ParameterLists
        def self.add_instance_from_definition(state, block, block_layer, layer, entities, definition, is_group,
                                              &convert_to_native)
          t_arr = get_transform_matrix(block)
          transform = Other::Transform.to_native(t_arr, block['units'])
          instance = if is_group
                       # rubocop:disable SketchupSuggestions/AddGroup
                       group = entities.add_group(definition.entities.to_a)
                       group.layer = block_layer.nil? ? layer : block_layer
                       group
                       # rubocop:enable SketchupSuggestions/AddGroup
                     else
                       instance = entities.add_instance(definition, transform)
                       instance.layer = block_layer.nil? ? layer : block_layer
                       instance
                     end

          # erase existing instances after creation and before rename because you can't have definitions
          #  without instances
          find_and_erase_existing_instance(definition, block['id'], block['applicationId'])
          puts("Failed to create instance for speckle block instance #{block['id']}") if instance.nil?
          # Transform already applied to instance unless is group
          instance.transformation = transform if is_group
          state, _materials = Other::RenderMaterial.to_native(state, block['renderMaterial'], layer,
                                                              entities, &convert_to_native)

          # Retrieve material from state
          unless block['renderMaterial'].nil?
            material_name = block['renderMaterial']['name'] || block['renderMaterial']['id']
            material = state.sketchup_state.materials.by_id(material_name)
            instance.material = material
          end

          instance.name = block['name'] unless block['name'].nil?
          unless block['sketchup_attributes'].nil?
            SketchupModel::Dictionary::BaseDictionaryHandler
              .attribute_dictionaries_to_native(instance, block['sketchup_attributes']['dictionaries'])
          end
          return state, [instance, definition]
        end
        # rubocop:enable Metrics/AbcSize
        # rubocop:enable Metrics/MethodLength
        # rubocop:enable Metrics/CyclomaticComplexity
        # rubocop:enable Metrics/PerceivedComplexity
        # rubocop:enable Metrics/ParameterLists

        # Instances that created from display value that has no any transform value.
        # Because of this reason their definition created with origin axis. We basically create transformation
        # vector between bounds min to origin, to move definition axis to bounds min. Otherwise they looks weird in
        # sketchup and might be cumbersome when we want to add new entities into definition.
        # @param instance [Sketchup::ComponentInstance] instance to align axis to it's bounds
        def self.align_instance_axes(instance)
          bounds = instance.bounds
          transform = Geom::Transformation.translation(bounds.min.vector_to(Geom::Point3d.new(0, 0, 0)))
          entities = instance.definition.entities
          entities.transform_entities(transform, entities.to_a)
          instance_transform = instance.transformation
          instance.transform!(instance_transform * transform.inverse * instance_transform.inverse)
        end

        def self.calculate_rotation(matrix)
          # Ensure the matrix is a flat array with 16 elements
          unless matrix.is_a?(Array) && matrix.size == 16
            raise ArgumentError, 'Matrix must be an array with 16 elements'
          end

          # Extract the elements of the 2x2 rotation sub-matrix
          cos_theta = matrix[0] # First column, first row
          sin_theta = matrix[1] # Second column, first row

          # Calculate the rotation angle in radians
          theta = Math.atan2(sin_theta, cos_theta)

          # Ensure the angle is between -π and π
          theta -= 2 * Math::PI while theta > Math::PI
          theta += 2 * Math::PI while theta < -Math::PI

          theta
        end
      end
    end
  end
end
