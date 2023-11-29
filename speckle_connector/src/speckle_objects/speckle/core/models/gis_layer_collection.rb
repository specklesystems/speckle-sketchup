# frozen_string_literal: true

require_relative 'collection'

module SpeckleConnector
  module SpeckleObjects
    module Speckle
      module Core
        module Models
          # VectorLayerCollection object that collect GIS vector elements under it's elements.
          class GisLayerCollection < Collection
            # @param state [States::State] state of the Speckle application.
            def self.to_native(state, vector_layer_collection, layer_or_folder, entities, &convert_to_native)
              elements = vector_layer_collection['elements']

              elements.each do |element|
                new_state, _converted_entities = convert_to_native.call(state, element, layer_or_folder, entities)
                state = new_state
              end

              return state, []
            end
          end
        end
      end
    end
  end
end
