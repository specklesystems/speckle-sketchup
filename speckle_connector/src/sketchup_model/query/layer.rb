# frozen_string_literal: true

module SpeckleConnector
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
        end
      end
    end
  end
end
