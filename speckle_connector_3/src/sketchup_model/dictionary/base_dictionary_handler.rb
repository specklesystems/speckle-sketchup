# frozen_string_literal: true

require 'delegate'
require_relative 'dictionary_handler'
require_relative '../../constants/dict_constants'

module SpeckleConnector3
  module SketchupModel
    module Dictionary
      # Read and write attributes for Speckle objects on SketchUp model.
      class BaseDictionaryHandler < DictionaryHandler
        IGNORED_DICTIONARY_NAMES = [
          SPECKLE_BASE_OBJECT,
          'IFC 4',
          'IFC 2x3'
        ].freeze

        # @param entity [Sketchup::Entity] entity to get attribute dictionaries
        def self.attribute_dictionaries_to_speckle(entity)
          dictionaries = {}
          return dictionaries if entity.attribute_dictionaries.nil?

          entity.attribute_dictionaries.each do |att_dict|
            dict_name = att_dict == '' ? 'empty_dictionary_name' : att_dict.name
            dictionaries[dict_name] = att_dict.to_h unless IGNORED_DICTIONARY_NAMES.include?(att_dict.name)
          end
          dictionaries
        end

        # @param entity [Sketchup::Entity] entity to get attribute dictionaries
        # @note v2 logic
        def self.attribute_dictionaries_to_speckle_by_settings(entity, model_preferences)
          dictionaries = {}
          return dictionaries unless model_preferences[INCLUDE_ENTITY_ATTRIBUTES]

          klass = get_entity_setting_type(entity)
          return dictionaries unless model_preferences[ENTITY_KEYS_FOR_INCLUDING_ATTRIBUTES[klass]]
          return dictionaries if entity.attribute_dictionaries.nil?

          entity.attribute_dictionaries.each do |att_dict|
            dict_name = att_dict == '' ? 'empty_dictionary_name' : att_dict.name
            dictionaries[dict_name] = att_dict.to_h unless IGNORED_DICTIONARY_NAMES.include?(att_dict.name)
          end
          dictionaries
        end

        # @param entity [Sketchup::Entity] entity to set attribute dictionaries
        # rubocop:disable Metrics/CyclomaticComplexity
        def self.attribute_dictionaries_to_native(entity, dictionaries)
          return if dictionaries.nil?

          classification_to_native(entity, dictionaries) if entity.is_a?(Sketchup::ComponentDefinition)

          dictionaries.each do |dict_name, entries|
            next unless entries.is_a?(Hash)

            dict_name = dict_name == 'empty_dictionary_name' ? '' : dict_name
            entries.each do |key, value|
              set_attribute(entity, key, value, dict_name)
            rescue StandardError => e
              puts("Failed to write key: #{key} value: #{value} to dictionary #{dict_name}")
              puts(e)
            end
          end
        end
        # rubocop:enable Metrics/CyclomaticComplexity

        # Classification is ComponentDefinition specific, so they can be added only definition by add_classification
        # method.
        # @param definition_entity [Sketchup::ComponentDefinition] definition to add callback
        def self.classification_to_native(definition_entity, dictionaries)
          applied_schema_types = dictionaries['AppliedSchemaTypes']
          return if applied_schema_types.nil?

          applied_schema_types.each do |key, value|
            definition_entity.add_classification(key, value)
          end
        end

        # @return [String] the name of the dictionary to read from
        def self.dictionary_name
          SPECKLE_BASE_OBJECT
        end

        # Gets entity type for including entity attributes setting.
        # @param entity [Sketchup::Entity] entity to find setting entity.
        # @return [Sketchup::Face, Sketchup::Edge, Sketchup::Group, Sketchup::ComponentInstance]
        def self.get_entity_setting_type(entity)
          klass = entity.class
          if entity.is_a?(Sketchup::ComponentDefinition)
            klass = if entity.group?
                      Sketchup::Group
                    else
                      Sketchup::ComponentInstance
                    end
          end
          klass
        end
      end
    end
  end
end
