# frozen_string_literal: true

require_relative 'render_material'
require_relative 'transform'
require_relative 'block_instance'
require_relative '../base'
require_relative '../geometry/point'
require_relative '../geometry/mesh'
require_relative '../geometry/bounding_box'
require_relative '../../sketchup_model/dictionary/dictionary_handler'

module SpeckleConnector
  module SpeckleObjects
    module Other
      # BlockDefinition object definition for Speckle.
      class BlockDefinition < Base
        SPECKLE_TYPE = 'Objects.Other.BlockDefinition'

        # @param geometry [Object] geometric definition of the block.
        # @param name [String] name of the block definition.
        # @param units [String] units of the block definition.
        # @param application_id [String, NilClass] application id of the block definition.
        # rubocop:disable Metrics/ParameterLists
        def initialize(geometry:, name:, units:, always_face_camera:, sketchup_attributes: {},
                       application_id: nil)
          super(
            speckle_type: SPECKLE_TYPE,
            total_children_count: 0,
            application_id: application_id,
            id: nil
          )
          self[:units] = units
          self[:name] = name
          self[:always_face_camera] = always_face_camera
          self[:sketchup_attributes] = sketchup_attributes if sketchup_attributes.any?
          # FIXME: Since geometry sends with @ as detached, block basePlane renders on viewer.
          self['@@geometry'] = geometry
        end
        # rubocop:enable Metrics/ParameterLists

        # @param definition [Sketchup::ComponentDefinition] component definition might be belong to group or component
        #  instance
        # @param units [String] units of the Sketchup model
        # @param definitions [Hash{String=>BlockDefinition}] all converted {BlockDefinition}s on the converter.
        # rubocop:disable Metrics/CyclomaticComplexity
        # rubocop:disable Metrics/PerceivedComplexity
        # rubocop:disable Metrics/MethodLength
        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Metrics/ParameterLists
        def self.from_definition(definition, units, definitions, preferences, speckle_state, parent, &convert)
          guid = definition.guid
          return definitions[guid] if definitions.key?(guid)

          dictionaries = {}
          if preferences[:model][:include_entity_attributes]
            if definition.group?
              if preferences[:model][:include_group_entity_attributes]
                dictionaries = SketchupModel::Dictionary::DictionaryHandler
                               .attribute_dictionaries_to_speckle(definition)
              end
            elsif preferences[:model][:include_component_entity_attributes]
              dictionaries = SketchupModel::Dictionary::DictionaryHandler.attribute_dictionaries_to_speckle(definition)
            end
          end
          att = dictionaries.any? ? { dictionaries: dictionaries } : {}

          # TODO: Solve logic
          geometry = if definition.entities[0].is_a?(Sketchup::Edge) || definition.entities[0].is_a?(Sketchup::Face)
                       new_speckle_state, geo = group_entities_to_speckle(
                         definition, preferences, speckle_state, parent, &convert
                       )
                       speckle_state = new_speckle_state
                       geo
                     else
                       definition.entities.map do |entity|
                         next if entity.is_a?(Sketchup::Edge) && entity.faces.any?

                         new_speckle_state, converted = convert.call(entity, preferences,
                                                                     speckle_state,
                                                                     definition.persistent_id)
                         speckle_state = new_speckle_state
                         converted
                       end
                     end

          # FIXME: Decide how to approach base point of the definition instead origin.
          block_definition = BlockDefinition.new(
            units: units,
            name: definition.name,
            geometry: geometry,
            always_face_camera: definition.behavior.always_face_camera?,
            sketchup_attributes: att,
            application_id: definition.persistent_id.to_s
          )
          return speckle_state, block_definition
        end
        # rubocop:enable Metrics/CyclomaticComplexity
        # rubocop:enable Metrics/PerceivedComplexity
        # rubocop:enable Metrics/MethodLength
        # rubocop:enable Metrics/AbcSize
        # rubocop:enable Metrics/ParameterLists

        def self.get_definition_name(def_obj)
          return def_obj['name'] unless def_obj['name'].nil?

          return "def::#{def_obj['applicationId']}"
        end

        # Finds or creates a component definition from the geometry and the given name
        # @param state [States::State] state of the application.
        # rubocop:disable Metrics/CyclomaticComplexity
        # rubocop:disable Metrics/PerceivedComplexity
        # rubocop:disable Metrics/MethodLength
        # rubocop:disable Metrics/AbcSize
        def self.to_native(state, definition_obj, layer, _entities, &convert_to_native)
          sketchup_model = state.sketchup_state.sketchup_model

          # FIXME: Check later this is a valid check or not. Maybe unnecessary? If necessary document it!
          # Check definitions from sketchup_model with name and application id
          definition_name = get_definition_name(definition_obj)
          application_id = definition_obj['applicationId']
          definition = sketchup_model.definitions[definition_name]
          if definition && (definition.name == definition_name || definition.guid == application_id)
            return state, [definition]
          end

          geometry = definition_obj['geometry'] || definition_obj['@geometry'] || definition_obj['displayValue']

          always_face_camera = definition_obj['always_face_camera'].nil? ? false : definition_obj['always_face_camera']
          sketchup_attributes = definition_obj['sketchup_attributes']
          definition&.entities&.clear!
          definition ||= sketchup_model.definitions.add(definition_name)
          definition.layer = layer

          if geometry.is_a?(Array)
            geometry.each do |obj|
              state = convert_to_native.call(state, obj, layer, definition.entities)
            end
          end
          if geometry.is_a?(Hash) && !definition_obj['speckle_type'].nil?
            state = convert_to_native.call(state, geometry, layer, definition.entities)
          end
          # puts("definition finished: #{name} (#{application_id})")
          # puts("    entity count: #{definition.entities.count}")
          definition.behavior.always_face_camera = always_face_camera
          unless sketchup_attributes.nil?
            SketchupModel::Dictionary::DictionaryHandler
              .attribute_dictionaries_to_native(definition, sketchup_attributes['dictionaries'])
          end
          return state, [definition]
        end
        # rubocop:enable Metrics/CyclomaticComplexity
        # rubocop:enable Metrics/PerceivedComplexity
        # rubocop:enable Metrics/MethodLength
        # rubocop:enable Metrics/AbcSize

        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Metrics/MethodLength
        # rubocop:disable Metrics/CyclomaticComplexity
        # rubocop:disable Metrics/PerceivedComplexity
        def self.group_entities_to_speckle(definition, preferences, speckle_state, parent, &convert)
          orphan_edges = definition.entities.grep(Sketchup::Edge).filter { |edge| edge.faces.none? }
          lines = orphan_edges.collect do |orphan_edge|
            new_speckle_state, converted = convert.call(orphan_edge, preferences, speckle_state, parent)
            speckle_state = new_speckle_state
            converted
          end

          nested_blocks = definition.entities.grep(Sketchup::ComponentInstance).collect do |component_instance|
            new_speckle_state, converted = convert.call(component_instance, preferences, speckle_state, parent)
            speckle_state = new_speckle_state
            converted
          end

          nested_groups = definition.entities.grep(Sketchup::Group).collect do |group|
            new_speckle_state, converted = convert.call(group, preferences, speckle_state, parent)
            speckle_state = new_speckle_state
            converted
          end

          if preferences[:model][:combine_faces_by_material]
            mesh_groups = {}
            definition.entities.grep(Sketchup::Face).collect do |face|
              new_speckle_state = group_meshes_by_material(
                face, mesh_groups, speckle_state, preferences, parent, &convert
              )
              speckle_state = new_speckle_state
            end
            # Update mesh overwrites points and polygons into base object.
            mesh_groups.each { |_, mesh| mesh.first.update_mesh }

            return speckle_state, lines + nested_blocks + nested_groups + mesh_groups.values
          else
            meshes = []
            definition.entities.grep(Sketchup::Face).collect do |face|
              new_speckle_state, converted = convert.call(face, preferences, speckle_state, parent)
              meshes.append(converted)
              speckle_state = new_speckle_state
            end

            return speckle_state, lines + nested_blocks + nested_groups + meshes
          end
        end
        # rubocop:enable Metrics/AbcSize
        # rubocop:enable Metrics/MethodLength
        # rubocop:enable Metrics/CyclomaticComplexity
        # rubocop:enable Metrics/PerceivedComplexity

        # rubocop:disable Metrics/ParameterLists
        def self.group_meshes_by_material(face, mesh_groups, speckle_state, preferences, parent, &convert)
          # convert material
          mesh_group_id = get_mesh_group_id(face, preferences[:model])
          new_speckle_state, converted = convert.call(face, preferences, speckle_state, parent)
          mesh_groups[mesh_group_id] = converted unless mesh_groups.key?(mesh_group_id)
          mesh_group = mesh_groups[mesh_group_id]
          mesh_group[0].face_to_mesh(face)
          mesh_group[1].append(face)
          new_speckle_state
        end
        # rubocop:enable Metrics/ParameterLists

        # Mesh group id helps to determine how to group faces into meshes.
        # @param face [Sketchup::Face] face to get mesh group id.
        def self.get_mesh_group_id(face, model_preferences)
          if model_preferences[:include_entity_attributes] &&
             model_preferences[:include_face_entity_attributes] &&
             attribute_dictionary?(face)
            return face.persistent_id.to_s
          end

          material = face.material || face.back_material
          return 'none' if material.nil?

          return material.entityID.to_s
        end

        def self.attribute_dictionary?(face)
          any_attribute_dictionary = !(face.attribute_dictionaries.nil? || face.attribute_dictionaries.first.nil?)
          return any_attribute_dictionary unless any_attribute_dictionary

          # If there are any attribute dictionary, then make sure that they are not ignored ones.
          all_attribute_dictionary_ignored = face.attribute_dictionaries.all? do |dict|
            ignored_dictionaries.include?(dict.name)
          end
          !all_attribute_dictionary_ignored
        end

        def self.ignored_dictionaries
          [
            'Speckle_Base_Object'
          ]
        end
      end
    end
  end
end
