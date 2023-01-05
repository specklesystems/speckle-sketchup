# frozen_string_literal: true

require 'delegate'

module SpeckleConnector
  module SketchupModel
    module Dictionary
      # Read and write attributes from the groups and other entities that represents Speckle objects on SketchUp model.
      class DictionaryHandler
        DICTIONARY_NAME = 'Speckle_Base_Object'

        # @param entity [Sketchup::Entity] entity to get attribute dictionaries
        def self.attribute_dictionaries_to_speckle(entity)
          dictionaries = {}
          return dictionaries if entity.attribute_dictionaries.nil?

          entity.attribute_dictionaries.each do |att_dict|
            dictionaries[att_dict.name] = att_dict.to_h.to_json unless att_dict.name == 'Speckle_Base_Object'
          end
          dictionaries
        end

        # @param entity [Sketchup::Entity] entity to set attribute dictionaries
        def self.attribute_dictionaries_to_native(entity, dictionaries)
          dictionaries.each do |dict_name, entries|
            JSON.parse(entries).each do |key, value|
              entity.set_attribute(dict_name, key, value)
            end
          end
        end

        # @param entity [Sketchup::Entity] the sketchup entity of Speckle object
        # @param key [Symbol] the name of the attribute
        # @param dictionary_name [String, Symbol] the name of the attribute dictionary
        def self.set_attribute(entity, key, new_value, dictionary_name = self.dictionary_name)
          dictionary = attribute_dictionary(entity, dictionary_name)
          # if value is nil, we first have to assign some value, otherwise
          # it not be recorded into dictionary
          new_value = new_value.to_s if new_value.is_a? Symbol
          old_value = entity.get_attribute(dictionary_name, key)
          if new_value.nil? and not (dictionary && dictionary.keys.include?(key))
            # setting attribute to nil doesn't save the value if the value was not previously set.
            # To solve that, we set the attribute first to a string.
            entity.set_attribute(dictionary_name, key, 'should be nil')
            entity.set_attribute(dictionary_name, key, nil)
          end
          entity.set_attribute(dictionary_name, key, new_value) unless old_value == new_value
        end

        # Read attribute from dictionary for the given entity
        # @param entity [Sketchup::Entity] the sketchup entity to be read from
        # @param key [Symbol] the name of the attribute
        # @param dictionary_name [String, Symbol] the name of the attribute dictionary
        def self.get_attribute(entity, key, dictionary_name = self.dictionary_name)
          entity.get_attribute(dictionary_name, key)
        end

        # @param dictionary_name [String, Symbol] the name of the attribute dictionary
        def self.attribute_dictionary(entity, dictionary_name = self.dictionary_name)
          entity.attribute_dictionary(dictionary_name)
        end

        # @param entity [Sketchup::Entity] the sketchup entity of Speckle object
        # @param dictionary_name [String, Symbol] the name of the attribute dictionary
        def self.set_hash(entity, hash, dictionary_name = self.dictionary_name)
          hash.each { |key, value| set_attribute(entity, key, value, dictionary_name) }
        end

        # @param entity [Sketchup::Entity] the sketchup entity of Speckle object
        # @param key [Symbol] the name of the attribute
        # @param dictionary_name [String, Symbol] the name of the attribute dictionary
        def self.delete_key(entity, key, dictionary_name = self.dictionary_name)
          dictionary = attribute_dictionary(entity, dictionary_name)
          dictionary.delete_key(key)
        end

        # @return [String] the name of the dictionary to read from
        def self.dictionary_name
          DICTIONARY_NAME
        end
      end
    end
  end
end
