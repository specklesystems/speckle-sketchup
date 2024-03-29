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
        def initialize(name:, visible:, is_folder:, full_path: nil, line_style: nil, color: nil, layers_and_folders: [],
                       application_id: nil)
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
          self[:full_path] =  full_path unless full_path.nil?
          self[:line_style] = line_style unless line_style.nil?
          self[:collectionType] = 'layer'
          self[:elements] = layers_and_folders if layers_and_folders.any?
        end
        # rubocop:enable Metrics/ParameterLists

        # @param speckle_layer [Object] speckle layer object.
        # @param folder [Sketchup::Layers, Sketchup::LayerFolder] folder to create layers in it.
        # @param sketchup_model [Sketchup::Model] sketchup active model.
        def self.to_native_layer(speckle_layer, folder, sketchup_model)
          layer = sketchup_model.layers.add_layer(speckle_layer[:name])
          layer.visible = speckle_layer[:visible] unless speckle_layer[:visible].nil?
          layer.color = SpeckleObjects::Other::Color.to_native(speckle_layer[:color]) if speckle_layer[:color]
          if speckle_layer[:line_style]
            line_style = sketchup_model.line_styles.find { |ls| ls.name == speckle_layer[:line_style] }
            layer.line_style = line_style unless line_style.nil?
          end
          folder.add_layer(layer) if folder.is_a?(Sketchup::LayerFolder)
        end

        # Flat layer conversion.
        def self.to_native_flat_layers(layers_relation, sketchup_model)
          speckle_layers = layers_relation[:elements]

          elements_to_layers(speckle_layers, sketchup_model)
        end

        # Converts elements to layers with it's full path.
        def self.elements_to_layers(elements, sketchup_model)
          elements.each do |element|
            element[:name] = element[:full_path]
            to_native_layer(element, sketchup_model.layers, sketchup_model)
            elements_to_layers(element[:elements], sketchup_model) unless element[:elements].nil?
          end
        end

        # Nested layer conversion with folders.
        def self.to_native_layer_folder(layers_relation, folder, sketchup_model)
          speckle_layers = layers_relation[:elements].select { |layer_or_fol| layer_or_fol[:elements].nil? }

          speckle_layers.each do |speckle_layer|
            to_native_layer(speckle_layer, folder, sketchup_model)
          end

          speckle_folders = layers_relation[:elements].reject { |layer_or_fol| layer_or_fol[:elements].nil? }

          speckle_folders.each do |speckle_folder|
            sub_folder = folder.add_folder(speckle_folder[:name])
            sub_folder.visible = speckle_folder[:visible] unless speckle_folder[:visible].nil?
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
            line_style: layer.line_style.nil? ? nil : layer.line_style.name,
            color: SpeckleObjects::Other::Color.to_speckle(layer.color),
            application_id: layer.persistent_id
          )
        end
      end
    end
  end
end
