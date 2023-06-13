# frozen_string_literal: true

require_relative 'collection'
require_relative 'layer_collection'
require_relative '../../../built_elements/view3d'
require_relative '../../../built_elements/revit/direct_shape'
require_relative '../../../../mapper/mapper'

module SpeckleConnector
  module SpeckleObjects
    module Speckle
      module Core
        module Models
          # ModelCollection object that collect other speckle objects under it's elements.
          class ModelCollection < Collection
            DIRECT_SHAPE = SpeckleObjects::BuiltElements::Revit::DirectShape
            QUERY = SketchupModel::Query
            VIEW3D = SpeckleObjects::BuiltElements::View3d
            SPECKLE_SCHEMA_DICTIONARY_HANDLER = SketchupModel::Dictionary::SpeckleSchemaDictionaryHandler
            def initialize(name:, active_layer:, elements: [], application_id: nil)
              super(
                name: name,
                collection_type: 'sketchup model',
                elements: elements,
                application_id: application_id
              )
              self[:active_layer] = active_layer
            end

            def self.from_sketchup_model(sketchup_model, speckle_state, units, preferences, &convert)
              model_collection = ModelCollection.new(
                name: 'Sketchup Model', active_layer: sketchup_model.active_layer.display_name,
                application_id: sketchup_model.guid
              )

              # Direct shapes will pass directly to elements which are already flattened with all children
              model_collection[:elements] += collect_mapped_entities(sketchup_model, units, preferences, &convert)

              # Views will pass directly to elements since they don't have any relation with layers and geometries.
              model_collection[:elements] += VIEW3D.from_model(sketchup_model, units) if sketchup_model.pages.any?

              # Add layer collections.
              model_collection[:elements] += LayerCollection.create_layer_collections(sketchup_model)

              sketchup_model.selection.each do |entity|
                layer_collection = LayerCollection.get_or_create_layer_collection(entity.layer, model_collection)
                new_speckle_state, converted_object_with_entity = convert.call(entity, preferences, speckle_state)
                speckle_state = new_speckle_state
                unless converted_object_with_entity.nil?
                  layer_collection[:elements] = [] if layer_collection[:elements].nil?
                  layer_collection[:elements].append(converted_object_with_entity)
                end
              end

              return speckle_state, model_collection
            end

            # @param sketchup_model [Sketchup::Model] active model to retrieve and convert mapped entities.
            def self.collect_mapped_entities(sketchup_model, units, preferences, &convert)
              mapped_entities = Mapper.mapped_entities_on_selection(sketchup_model)
              mapped_entities.collect do |entity_with_path|
                convert_mapped_entity(entity_with_path, preferences, units)
              end
            end

            def self.to_native(state, model_collection, layer, entities, &convert_to_native)
              elements = model_collection['elements']

              elements.each do |element|
                new_state, _converted_entities = convert_to_native.call(state, element, layer, entities)
                state = new_state
              end

              active_layer = model_collection['active_layer']
              state.sketchup_state.sketchup_model.active_layer = active_layer unless active_layer.nil?

              return state, []
            end

            def self.convert_mapped_entity(entity_with_path, preferences, units)
              entity = entity_with_path[0]
              path = entity_with_path[1..-1]

              method = SPECKLE_SCHEMA_DICTIONARY_HANDLER.get_attribute(entity, 'method')

              if method.include?('Floor') && entity.is_a?(Sketchup::Face)
                global_transformation = QUERY::Entity.global_transformation(entity, path)
                floor = SpeckleObjects::Geometry::Mesh.from_face(face: entity, units: units,
                                                                 model_preferences: preferences,
                                                                 global_transform: global_transformation)
                return [floor, [entity]]
              end

              direct_shape = DIRECT_SHAPE.from_entity(entity, path, units, preferences)
              return [direct_shape, [entity]]
            end
          end
        end
      end
    end
  end
end
