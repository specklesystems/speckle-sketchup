# frozen_string_literal: true

require_relative 'layer'
require_relative '../base'

module SpeckleConnector
  module SpeckleObjects
    module Relations
      # Sketchup layers (tag) tree relation. The difference between Layer is, this is the top object that holds
      # properties for all layers or folders, i.e. active layer.
      class Layers < Base
        SPECKLE_TYPE = 'Speckle.Core.Models.Collection'

        def initialize(active:, layers:)
          super(
            speckle_type: SPECKLE_TYPE,
            total_children_count: 0,
            application_id: nil,
            id: nil
          )
          self[:active_layer] = active
          self[:elements] = layers
        end

        def self.element_to_relation(elements)
          elements.collect do |element|
            next unless element['speckle_type'] == SPECKLE_CORE_MODELS_COLLECTION

            is_folder = element['elements'].any? { |e| e['speckle_type'] == SPECKLE_CORE_MODELS_COLLECTION }
            color = element['color'] || element['displayStyle']['color'] unless element['displayStyle'].nil?
            Layer.new(
              name: element['name'],
              visible: element['visible'],
              is_folder: is_folder,
              color: color,
              layers_and_folders: element_to_relation(element['elements'])
            )
          end.compact
        end

        def self.extract_relations(commit_obj)
          return nil unless commit_obj['speckle_type'] == SPECKLE_CORE_MODELS_COLLECTION

          elements = element_to_relation(commit_obj['elements'])

          Layers.new(
            active: commit_obj['active_layer'],
            layers: elements
          )
        end

        def self.to_native(layers_relation, sketchup_model)
          folder = sketchup_model.layers

          SpeckleObjects::Relations::Layer.to_native_layer_folder(layers_relation, folder, sketchup_model)

          active_layer = folder.to_a.find { |layer| layer.display_name == layers_relation['active_layer'] }
          sketchup_model.active_layer = active_layer unless active_layer.nil?
        end

        def self.from_model(sketchup_model)
          # init with headless layers
          headless_layers = sketchup_model.layers.layers.collect do |layer|
            SpeckleObjects::Relations::Layer.from_layer(layer)
          end

          folders = sketchup_model.layers.folders.collect do |folder|
            SpeckleObjects::Relations::Layer.from_folder(folder)
          end

          Layers.new(
            active: sketchup_model.active_layer.display_name,
            layers: headless_layers + folders
          )
        end
      end
    end
  end
end
