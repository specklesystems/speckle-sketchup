# frozen_string_literal: true

module SpeckleConnector3
  module SketchupModel
    # Query operations in sketchup model.
    module Query
      # Queries for entity.
      class Entity
        class << self
          # Creates flat list for entities that defined in classes property. It searches from top to bottom to collect
          # entities.
          # @param entities_to_flat [Sketchup::Entities] entities to flat their children, grandchildren and so on..
          # @param classes [Array<Class>] objects types to collect as flat list.
          # @return [Array<Sketchup::Entity>]
          def flat_entities(entities_to_flat,
                            classes = [Sketchup::Edge, Sketchup::Face, Sketchup::ComponentInstance,
                                       Sketchup::Group, Sketchup::ComponentDefinition])
            entities = []
            entities_to_flat.each do |entity|
              entities.append(entity) if classes.include?(entity.class)
              if entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
                entities.append(entity.definition) if classes.include?(Sketchup::ComponentDefinition)
                entities += flat_entities(entity.definition.entities, classes)
              end
            end
            entities
          end

          # Create array for each entity with their path.
          # @param entities_to_flat [Sketchup::Entities, Array<Sketchup::Entity>] entities to flat with their path.
          # @param classes [Array<Class>] classes to flat. Put class into this array if you want to find their paths.
          # @param path [Array<Object>] path for entity that we are in.
          # @return [Array<Object>] entity with it's path as flat array. See example.
          # @example
          #   path[0] is entity itself
          #   path[1..-1] rest as path from top to bottom
          def flat_entities_with_path(entities_to_flat,
                                      classes = [Sketchup::Edge, Sketchup::Face, Sketchup::ComponentInstance,
                                                 Sketchup::Group, Sketchup::ComponentDefinition],
                                      path = [])
            entities = []
            entities_to_flat.each do |entity|
              # Collect object itself
              entities.append([entity] + path) if classes.include?(entity.class)
              # entities[entity] = path if classes.include?(entity.class) && entities[entity].nil?

              # Skip unless entity is a container entity like group or component.
              next unless entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)

              # Add entity definition also with it's path.
              entities[entity.definition] = path if classes.include?(Sketchup::ComponentDefinition)
              # Collect sub-objects if object is a container at the same time.
              sub_entities = flat_entities_with_path(entity.definition.entities.to_a,
                                                     classes, path + [entity])
              entities += sub_entities
            end
            entities
          end

          # Calculates global transformation of entity by multiplying path entries from bottom to top by reversing path.
          # @param entity [Sketchup::Entity] entity to find global transformation.
          # @param path [Array<Object>] path that parents of entity that has transformation value to calculate global
          #  transformation of the entity.
          # @return [Geom::Transformation] global transformation of the entity.
          def global_transformation(entity, path)
            # If entity is face, use Identity
            global = entity.respond_to?(:transformation) ? entity.transformation : Geom::Transformation.new
            path.reverse.each do |local|
              global = local.transformation * global if local.respond_to?(:transformation)
            end
            global
          end

          # Global transformation search for entity that lies on only one instance.
          # @param entity [Sketchup::Entity] entity to find global transformation.
          def global_transformation_from_bottom(entity)
            # If entity is face, use Identity
            transformation = entity.respond_to?(:transformation) ? entity.transformation : Geom::Transformation.new
            parent = parent_or_model(entity)
            until parent.is_a?(Sketchup::Model) || parent.nil?
              transformation = parent.transformation * transformation
              parent = parent_or_model(parent)
            end
            transformation
          end

          # Parent search for entity from bottom to top. It is not ideal if entity lives in different instances.
          def parent_or_model(entity)
            parent = entity.parent
            return parent if parent.is_a?(Sketchup::Model)

            instances = parent.instances
            if instances.length > 1
              puts 'Parent has more than one instance'
              instances.each(&:make_unique)
              instances = instances.select { |instance| instance.definition.entities.include?(entity) }
            end
            instances.first
          end

          # Finds first material of parents from bottom to top.
          def parent_material(path)
            material = nil
            path.reverse.each do |local|
              material = local.material if local.respond_to?(:material)
              return material unless material.nil?
            end
            material
          end
        end
      end
    end
  end
end
