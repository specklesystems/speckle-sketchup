# frozen_string_literal: true

require_relative '../base'

module SpeckleConnector
  module SpeckleObjects
    module Relations
      # Sketchup layer (tag) tree relation.
      class Layer < Base
        SPECKLE_TYPE = 'Objects.Relations.Layer'

        def initialize(name:, visible:, color: nil, layers_and_folders: [], application_id: nil)
          super(
            speckle_type: SPECKLE_TYPE,
            total_children_count: 0,
            application_id: application_id,
            id: nil
          )
          self[:name] = name
          self[:color] = color
          self[:visible] = visible
          self[:layers] = layers_and_folders if layers_and_folders.any?
        end

        # @param folder [Sketchup::LayerFolder] sketchup layer folder that might contains other folders and layers.
        def self.from_folder(folder)
          layers = folder.layers.collect { |layer| from_layer(layer) }
          sub_folders = folder.folders.collect { |sub_folder| from_folder(sub_folder) }
          Layer.new(
            name: folder.display_name,
            visible: folder.visible?,
            layers_and_folders: layers + sub_folders,
            application_id: folder.persistent_id
          )
        end

        # @param layer [Sketchup::Layer] sketchup layer (tag) that objects can be assigned..
        def self.from_layer(layer)
          Layer.new(
            name: layer.display_name,
            visible: layer.visible?,
            color: SpeckleObjects::Others::Color.to_speckle(layer.color),
            application_id: layer.persistent_id
          )
        end
      end
    end
  end
end
