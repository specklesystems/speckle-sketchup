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
            parents(sketchup_model).collect(&:persistent_id)
          end

          # @param sketchup_model [Sketchup::Model] active sketchup model.
          def parents(sketchup_model)
            path = sketchup_model.active_path
            path.nil? ? [] : path
          end

          # @param sketchup_model [Sketchup::Model] active sketchup model.
          def parent_definitions(sketchup_model)
            parents(sketchup_model).collect(&:definition)
          end

          # @param sketchup_model [Sketchup::Model] active sketchup model.
          def parents_with_definitions(sketchup_model)
            parents = parents(sketchup_model)
            parents += parent_definitions(sketchup_model)
            parents
          end

          # @param sketchup_model [Sketchup::Model] active sketchup model.
          def instances(sketchup_model)
            path = sketchup_model.active_path
            return [] if path.nil?

            instances = []
            parent_definitions(sketchup_model).each do |p|
              instances += p.instances.to_a
            end
            instances
          end

          # @param sketchup_model [Sketchup::Model] active sketchup model.
          def instance_ids(sketchup_model)
            instances(sketchup_model).collect(&:persistent_id)
          end

          # @param entity [Sketchup::Entity] entity to get its definition instances
          def entity_definition_instances(entity)
            return [] if entity.parent.is_a?(Sketchup::Model)
            return [] unless entity.is_a?(Sketchup::ComponentDefinition)

            entity.instances
          end

          # @param entities [Sketchup::Entities] entities to get its definition instances
          def entities_definition_instances(entities)
            instances = []
            entities.each { |entity| instances += entity_definition_instances(entity) }
            instances
          end
        end
      end
    end
  end
end
