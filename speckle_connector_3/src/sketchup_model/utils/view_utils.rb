# frozen_string_literal: true

require_relative '../../sketchup_model/query/entity'

module SpeckleConnector3
  # Operations related to {SketchupModel}.
  module SketchupModel
    # Works directly with/on SketchUp Entities of different kinds (Groups, Faces, Edges, ...).
    module Utils
      # View related utils
      class ViewUtils
        def self.highlight_entities(sketchup_model, entity_ids)
          sketchup_model.selection.clear

          # Flat entities to select entities on card
          flat_entities = SketchupModel::Query::Entity.flat_entities(sketchup_model.entities)

          flat_entities.each do |entity|
            next unless entity_ids.include?(entity.persistent_id.to_s)

            sketchup_model.selection.add(entity.instances) if entity.is_a?(Sketchup::ComponentDefinition)
            sketchup_model.selection.add(entity)
          end

          sketchup_model.active_view.zoom(sketchup_model.selection)
        end
      end
    end
  end
end
