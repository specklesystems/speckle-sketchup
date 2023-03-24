# frozen_string_literal: true

require_relative '../../constants/dict_constants'

module SpeckleConnector
  # Operations related to {SketchupModel}.
  module SketchupModel
    # Definitions to store for entities.
    class Definitions
      def self.from_sketchup_model(model)
        definitions = model.definitions
        definitions = definitions.select do |definition|
          !definition.attribute_dictionaries.nil? &&
            definition.attribute_dictionaries.any? { |dict| dict.name == SPECKLE_BASE_OBJECT }
        end
        Definitions.new(definitions)
      end

      def add_definition(definition)
        old_definition = @definitions_by_guid[definition.guid]
        return self if definition == old_definition

        new_definitions = @definitions.append(definition)
        Definitions.new(new_definitions)
      end

      def initialize(definitions = [])
        @definitions = definitions
        @definitions_by_name = definitions.collect do |definition|
          [definition.name, definition]
        end.to_h.freeze
        @definitions_by_guid = definitions.collect do |definition|
          [definition.guid, definition]
        end.to_h.freeze
        freeze
      end

      def by_guid(guid)
        @definitions_by_guid[guid]
      end

      def by_name(name)
        @definitions_by_name[name]
      end
    end
  end
end
