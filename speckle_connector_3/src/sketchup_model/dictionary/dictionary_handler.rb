# frozen_string_literal: true

require 'delegate'
require_relative '../../constants/dict_constants'

module SpeckleConnector3
  module SketchupModel
    module Dictionary
      # Read and write attributes from the groups and other entities that represents Speckle objects on SketchUp model.
      class DictionaryHandler
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

        # @param entity [Sketchup::Entity] the sketchup entity of Speckle object
        # @param dictionary_name [String, Symbol] the name of the attribute dictionary to remove
        def self.remove_dictionary(entity, dictionary_name = self.dictionary_name)
          entity.attribute_dictionaries.delete(dictionary_name)
        end

        # @param dict [Sketchup::AttributeDictionary] attribute dictionary to get complete hash.
        def self.dict_to_h(dict)
          hash = {}
          hash.merge!(dict.to_h)
          unless dict.attribute_dictionaries.nil?
            dict.attribute_dictionaries.each do |sub_dict|
              sub_hash = dict_to_h(sub_dict)
              hash[sub_dict.name] = sub_hash
            end
          end
          hash
        end

        # @return [String] the name of the dictionary to read from
        def self.dictionary_name
          raise NotImplementedError 'Implement this in subclass'
        end
      end
    end
  end
end
