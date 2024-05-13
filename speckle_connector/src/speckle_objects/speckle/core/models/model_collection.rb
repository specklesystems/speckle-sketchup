# frozen_string_literal: true

require_relative 'collection'
require_relative 'layer_collection'
require_relative '../../../object_reference'
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

            def self.to_native(state, model_collection, layer, entities, &convert_to_native)
              elements = model_collection['@elements'] || model_collection['elements']
              views = model_collection['@Views']
              if views
                views.each do |view|
                  new_state, _converted_entities = convert_to_native.call(state, view, layer, entities)
                  state = new_state
                end
              end

              elements.each do |element|
                new_state, _converted_entities = convert_to_native.call(state, element, layer, entities)
                state = new_state
              end

              active_layer = model_collection['active_layer']
              state.sketchup_state.sketchup_model.active_layer = active_layer unless active_layer.nil?

              return state, []
            end

            def self.from_entities(entities, sketchup_model, state, units, preferences, model_card_id, &convert)
              speckle_state = state.speckle_state
              model_collection = ModelCollection.new(
                name: 'Sketchup Model', active_layer: sketchup_model.active_layer.display_name,
                application_id: sketchup_model.guid
              )

              count = 0
              entities.each do |entity|
                layer_collection = LayerCollection.get_or_create_layer_collection(entity.layer, model_collection)
                new_speckle_state, converted_object_with_entity = convert.call(entity, preferences, speckle_state)
                speckle_state = new_speckle_state
                unless converted_object_with_entity.nil?
                  coll = layer_collection['@elements'] || layer_collection['elements']
                  coll = [] if coll.nil?
                  coll.append(converted_object_with_entity)
                  # test_reference = ObjectReference.new("test_referenced_id", {"test_closure_1" => 0, "test_closure_2" => 0, "test_closure_3" => 0})
                  # layer_collection['@elements'].append(test_reference)
                end
                count += 1
                # User might click the Update button without any selection
                progress = sketchup_model.selection.count == 0 ? nil : count / sketchup_model.selection.count.to_f
                sender_progress_args = {
                  modelCardId: model_card_id,
                  progress: {
                    progress: progress,
                    status: progress == 1 ? 'Completed' : 'Converting'
                  }
                }

                action = Proc.new do
                  state.instant_message_sender.call("sendBinding.emit('setModelProgress', #{sender_progress_args.to_json})")
                end

                state.worker.add_job(Job.new(entity.persistent_id, &action))
                state.worker.do_work(Time.now.to_f, &action)
              end

              return speckle_state, model_collection
            end

            def self.from_sketchup_model(sketchup_model, state, units, preferences, model_card_id, &convert)
              speckle_state = state.speckle_state
              model_collection = ModelCollection.new(
                name: 'Sketchup Model', active_layer: sketchup_model.active_layer.display_name,
                application_id: sketchup_model.guid
              )

              # Direct shapes will pass directly to elements which are already flattened with all children
              model_collection['@elements'] += collect_mapped_entities(speckle_state, sketchup_model, units,
                                                                       preferences, &convert)

              # Views will pass directly to elements since they don't have any relation with layers and geometries.
              model_collection['@elements'] += VIEW3D.from_model(sketchup_model, units) if sketchup_model.pages.any?

              # Add layer collections.
              model_collection['@elements'] += LayerCollection.create_layer_collections(sketchup_model)

              count = 0
              sketchup_model.selection.each do |entity|
                layer_collection = LayerCollection.get_or_create_layer_collection(entity.layer, model_collection)
                new_speckle_state, converted_object_with_entity = convert.call(entity, preferences, speckle_state)
                speckle_state = new_speckle_state
                unless converted_object_with_entity.nil?
                  layer_collection['@elements'] = [] if layer_collection['@elements'].nil?
                  layer_collection['@elements'].append(converted_object_with_entity)
                end

                count += 1
                progress = count / sketchup_model.selection.count.to_f
                sender_progress_args = {
                  modelCardId: model_card_id,
                  progress: {
                    progress: progress,
                    status: progress == 1 ? 'Completed' : 'Converting'
                  }
                }
                state.instant_message_sender.call("sendBinding.emit('setModelProgress', #{sender_progress_args.to_json})")
              end

              return speckle_state, model_collection
            end

            # @param sketchup_model [Sketchup::Model] active model to retrieve and convert mapped entities.
            def self.collect_mapped_entities(speckle_state, sketchup_model, units, preferences, &convert)
              mapped_entities = Mapper.mapped_entities_on_selection(sketchup_model)
              mapped_entities.collect do |entity_with_path|
                Mapper.convert_mapped_entity(speckle_state, entity_with_path, preferences, units, &convert)
              end
            end
          end
        end
      end
    end
  end
end
