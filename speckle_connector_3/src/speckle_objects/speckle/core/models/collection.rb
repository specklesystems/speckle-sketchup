# frozen_string_literal: true

require_relative '../../../base'
require_relative '../../../../constants/type_constants'

module SpeckleConnector3
  module SpeckleObjects
    module Speckle
      module Core
        module Models
          # Collection object that collect other speckle objects under it's elements.
          class Collection < Base
            # @param name [String] name of the collection.
            # @param collection_type [String] type of the collection like, layers, categories etc..
            # @param elements [Array<Object>] elements of the collection.
            # @param application_id [String, nil] id of the collection on the model.
            def initialize(name:, collection_type:, elements: [], application_id: nil)
              super(
                speckle_type: SPECKLE_CORE_MODELS_COLLECTION,
                application_id: application_id,
                id: nil
              )
              self[:name] = name
              self[:collectionType] = collection_type
              self['@elements'] = elements
            end

            def self.to_native(state, collection, layer, entities, &convert_to_native)
              # Always iterate as layer collection with V3
              LayerCollection.to_native(state, collection, layer, entities, &convert_to_native)
            end
          end
        end
      end
    end
  end
end
