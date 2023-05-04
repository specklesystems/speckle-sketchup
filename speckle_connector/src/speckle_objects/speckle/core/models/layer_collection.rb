# frozen_string_literal: true

require_relative 'collection'
require_relative '../../../../sketchup_model/query/layer'
require_relative '../../../other/color'

module SpeckleConnector
  module SpeckleObjects
    module Speckle
      module Core
        module Models
          # LayerCollection object that collect other speckle objects under it's elements.
          class LayerCollection < Collection
            SPECKLE_TYPE = 'Speckle.Core.Models.Collection'
            def initialize(name:, visible:, color: nil, elements: [], application_id: nil)
              super(
                name: name,
                collection_type: 'layer',
                elements: elements,
                application_id: application_id
              )
              self[:visible] = visible
              self[:color] = color unless color.nil?
            end

            # @param entity [Sketchup::Entity] entity to get it's layer collection.
            # @param collection [Array] collection to search elements for entity's layer.
            def self.get_or_create_layer_collection(entity, collection)
              folder_path = SpeckleConnector::SketchupModel::Query::Layer.path(entity.layer)
              entity_layer_path = folder_path + [entity.layer]
              entity_layer_path.each do |folder|
                collection_candidate = collection[:elements].find do |el|
                  next if el.is_a?(Array)

                  el[:speckle_type] == SPECKLE_TYPE && el[:collectionType] == 'layer' &&
                    el[:name] == folder.display_name
                end
                if collection_candidate.nil?
                  color = folder.respond_to?(:color) ? SpeckleObjects::Others::Color.to_speckle(folder.color) : nil
                  collection_candidate = LayerCollection.new(
                    name: folder.display_name,
                    visible: folder.visible?,
                    color: color
                  )
                  # Before switching collection with the new one, we should add it to current collection's elements
                  collection[:elements].append(collection_candidate)
                end
                collection = collection_candidate
              end

              collection
            end
          end
        end
      end
    end
  end
end
