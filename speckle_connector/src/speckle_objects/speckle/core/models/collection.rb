# frozen_string_literal: true

require_relative '../../../base'

module SpeckleConnector
  module SpeckleObjects
    module Speckle
      module Core
        module Models
          # Collection object that collect other speckle objects under it's elements.
          class Collection < Base
            SPECKLE_TYPE = 'Speckle.Core.Models.Collection'

            # @param name [String] name of the collection.
            # @param collection_type [String] type of the collection like, layers, categories etc..
            # @param elements [Array<Object>] elements of the collection.
            # @param application_id [String, nil] id of the collection on the model.
            def initialize(name:, collection_type:, elements: [], application_id: nil)
              super(
                speckle_type: SPECKLE_TYPE,
                total_children_count: 0,
                application_id: application_id,
                id: nil
              )
              self[:name] = name
              self[:collectionType] = collection_type
              self[:elements] = elements
            end
          end
        end
      end
    end
  end
end
