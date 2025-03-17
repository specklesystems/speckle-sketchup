# frozen_string_literal: true

require 'delegate'
require_relative 'dictionary_handler'
require_relative '../../constants/dict_constants'

module SpeckleConnector3
  module SketchupModel
    module Dictionary
      # Read and write attributes for Speckle objects' schema on SketchUp model.
      class SpeckleSchemaDictionaryHandler < DictionaryHandler
        def self.speckle_schema_to_speckle(entity)
          schema = {}
          return schema if entity.attribute_dictionaries.nil?

          schema_dict = entity.attribute_dictionaries.find { |dict| dict.name == dictionary_name }
          return schema if schema_dict.nil?

          schema_dict.to_h
        end

        # @return [String] the name of the dictionary to read from
        def self.dictionary_name
          SPECKLE_MAPPING_TOOL_SCHEMA
        end
      end
    end
  end
end
