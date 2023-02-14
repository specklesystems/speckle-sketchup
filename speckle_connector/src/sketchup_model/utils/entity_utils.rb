# frozen_string_literal: true

module SpeckleConnector
  # Operations related to {SketchupModel}.
  module SketchupModel
    # Works directly with/on SketchUp Entities of different kinds (Groups, Faces, Edges, ...).
    module Utils
      # Static methods that work directly with Sketchup::Entity objects
      class EntityUtils
        def self.parents(entity)
          parents = []
          until entity.parent.nil?
            parents.append(entity.parent.persistent_id) if entity.parent.persistent_id
            entity = entity.parent
          end
          parents
        end
      end
    end
  end
end
