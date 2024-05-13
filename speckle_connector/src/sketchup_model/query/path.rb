# frozen_string_literal: true

module SpeckleConnector
  module SketchupModel
    # Query operations in sketchup model.
    module Query
      # Queries for entity.
      class Path
        class << self
          # @param sketchup_model [Sketchup::Model] active sketchup model.
          def parent_ids(sketchup_model)
            path = sketchup_model.active_path
            path_objects = path.nil? ? [] : path + path.collect(&:definition)
            path_objects.collect(&:persistent_id)
          end
        end
      end
    end
  end
end
