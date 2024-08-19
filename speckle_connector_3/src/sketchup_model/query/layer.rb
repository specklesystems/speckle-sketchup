# frozen_string_literal: true

module SpeckleConnector3
  module SketchupModel
    # Query operations in sketchup model.
    module Query
      # Queries for layer and it's parents.
      class Layer
        class << self
          # @param layer [Sketchup::Layer] layer to get folder path of the layer
          # @return [Array<Sketchup::Folder>] path of the layer
          def path(layer)
            parent_folders = []
            folder = layer.folder
            until folder.nil?
              parent_folders.append(folder)
              folder = folder.folder
            end
            parent_folders.reverse
          end

          # @param entity [Sketchup::Entity] entity to find path.
          def entity_path(entity, separation = '::')
            path = path(entity.layer)
            full_path = path.append(entity.layer)
            full_path_string = ''
            full_path.each_with_index do |layer, i|
              full_path_string += layer.display_name
              full_path_string += separation unless i == full_path.length - 1
            end
            full_path_string
          end

          # @param string_layer_path [String] string layer path to split.
          def entity_layer_from_path(string_layer_path, separation = '::')
            return string_layer_path if string_layer_path.nil?

            string_layer_path.split(separation).last
          end

          # @param sketchup_model [Sketchup::Model] active model
          # @param layer_name [String] layer name to get the next one if exists.
          def get_increment_layer_name(sketchup_model, layer_name)
            return layer_name if sketchup_model.layers.any? { |l| l.display_name != layer_name }

            counter = 1
            new_layer_name = layer_name
            while true
              new_layer_name = "#{layer_name} (#{counter})"
              layer = sketchup_model.layers.find { |l| l.display_name == new_layer_name }
              break if layer.nil?
              counter += 1
            end
            new_layer_name
          end

          # @param sketchup_model [Sketchup::Model] active model
          # @param layer_name [String] layer name to get the next one if exists.
          def get_last_increment_layer(sketchup_model, layer_name)
            counter = 1
            previous_layer_name = layer_name
            next_layer_name = layer_name
            while true
              layer = sketchup_model.layers.find { |l| l.display_name == next_layer_name }
              break if layer.nil?
              next_layer_name = "#{layer_name} (#{counter})"
              previous_layer_name = counter - 1 == 0 ? layer_name : "#{layer_name} (#{counter - 1})"
              counter += 1
            end
            previous_layer_name
          end
        end
      end
    end
  end
end
