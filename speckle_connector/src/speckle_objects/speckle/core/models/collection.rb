# frozen_string_literal: true

require_relative '../../../base'
require_relative '../../../built_elements/view3d'
require_relative '../../../built_elements/revit/direct_shape'
require_relative '../../../../sketchup_model/query/layer'

module SpeckleConnector
  module SpeckleObjects
    module Speckle
      module Core
        module Models
          # Collection object that collect other speckle objects under it's elements.
          class Collection < Base
            SPECKLE_TYPE = 'Speckle.Core.Models.Collection'
            DIRECT_SHAPE = SpeckleObjects::BuiltElements::Revit::DirectShape
            VIEW3D = SpeckleObjects::BuiltElements::View3d

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

            # @param sketchup_model [Sketchup::Model] sketchup model to create collections from it's layers.
            def self.layers(sketchup_model, speckle_state, units, preferences, &convert)
              model_collection = Collection.new(name: 'Sketchup Model', collection_type: 'sketchup model',
                                                application_id: sketchup_model.guid)

              # Direct shapes will pass directly to elements which are already flattened with all children
              model_collection[:elements] += collect_direct_shapes(sketchup_model, units, preferences)

              # Views will pass directly to elements since they don't have any relation with layers and geometries.
              model_collection[:elements] += VIEW3D.from_model(sketchup_model, units) if sketchup_model.pages.any?

              sketchup_model.selection.each do |entity|
                layer_collection = get_or_create_layer_collection(entity, model_collection)
                new_speckle_state, converted_object_with_entity = convert.call(entity, preferences, speckle_state)
                speckle_state = new_speckle_state
                unless converted_object_with_entity.nil?
                  layer_collection[:elements].append(converted_object_with_entity)
                end
              end

              return speckle_state, model_collection
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
                  collection_candidate = Collection.new(name: folder.display_name, collection_type: 'layer')
                  # Before switching collection with the new one, we should add it to current collection's elements
                  collection[:elements].append(collection_candidate)
                end
                collection = collection_candidate
              end

              collection
            end

            def self.collect_direct_shapes(sketchup_model, units, preferences)
              DIRECT_SHAPE.direct_shapes_on_selection(sketchup_model).collect do |entities|
                entity = entities[0]
                path = entities[1..-1]

                direct_shape = DIRECT_SHAPE.from_entity(entity, path, units, preferences)
                [direct_shape, [entity]]
              end
            end
          end
        end
      end
    end
  end
end
