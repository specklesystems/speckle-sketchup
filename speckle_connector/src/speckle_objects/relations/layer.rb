# frozen_string_literal: true

require_relative '../base'
require_relative '../other/color'

module SpeckleConnector
  module SpeckleObjects
    module Relations
      # Sketchup layer (tag) tree relation.
      class Layer < Base
        SPECKLE_TYPE = 'Speckle.Core.Models.Collection'

        # rubocop:disable Metrics/ParameterLists
        def initialize(name:, visible:, is_folder:, color: nil, layers_and_folders: [], application_id: nil)
          super(
            speckle_type: SPECKLE_TYPE,
            total_children_count: 0,
            application_id: application_id,
            id: nil
          )
          self[:name] = name
          self[:color] = color
          self[:visible] = visible
          self[:is_folder] =  is_folder
          self[:collectionType] = 'layer'
          self[:elements] = layers_and_folders if layers_and_folders.any?
        end
        # rubocop:enable Metrics/ParameterLists

        # @param speckle_layer [Object] speckle layer object.
        # @param folder [Sketchup::Layers, Sketchup::LayerFolder] folder to create layers in it.
        def self.to_native_layer(speckle_layer, folder, sketchup_model)
          layer = sketchup_model.layers.add_layer(speckle_layer['name'])
          layer.visible = speckle_layer['visible'] unless speckle_layer['visible'].nil?
          layer.color = SpeckleObjects::Others::Color.to_native(speckle_layer['color']) if speckle_layer['color']
          folder.add_layer(layer) if folder.is_a?(Sketchup::LayerFolder)
        end

        def self.to_native_layer_folder(speckle_layer_folder, folder, sketchup_model)
          speckle_layers = speckle_layer_folder['elements'].select { |layer_or_fol| layer_or_fol['elements'].nil? }

          speckle_layers.each do |speckle_layer|
            to_native_layer(speckle_layer, folder, sketchup_model)
          end

          speckle_folders = speckle_layer_folder['elements'].reject { |layer_or_fol| layer_or_fol['elements'].nil? }

          speckle_folders.each do |speckle_folder|
            sub_folder = folder.add_folder(speckle_folder['name'])
            sub_folder.visible = speckle_folder['visible'] unless speckle_folder['visible'].nil?
            to_native_layer_folder(speckle_folder, sub_folder, sketchup_model)
          end
        end

        # @param folder [Sketchup::LayerFolder] sketchup layer folder that might contains other folders and layers.
        def self.from_folder(folder)
          layers = folder.layers.collect { |layer| from_layer(layer) }
          sub_folders = folder.folders.collect { |sub_folder| from_folder(sub_folder) }
          Layer.new(
            name: folder.display_name,
            visible: folder.visible?,
            is_folder: true,
            layers_and_folders: layers + sub_folders,
            application_id: folder.persistent_id
          )
        end

        # @param layer [Sketchup::Layer] sketchup layer (tag) that objects can be assigned..
        def self.from_layer(layer)
          Layer.new(
            name: layer.display_name,
            visible: layer.visible?,
            is_folder: false,
            color: SpeckleObjects::Others::Color.to_speckle(layer.color),
            application_id: layer.persistent_id
          )
        end
      end
    end
  end
end
