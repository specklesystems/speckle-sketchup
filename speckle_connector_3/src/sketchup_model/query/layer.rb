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
        end
      end
    end
  end
end
