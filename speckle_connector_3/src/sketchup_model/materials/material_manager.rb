# frozen_string_literal: true

require_relative '../../sketchup_model/query/entity'
require_relative '../../speckle_objects/other/render_material'
require_relative '../../speckle_objects/render_material_proxy'

module SpeckleConnector3
  # Operations related to {SketchupModel}.
  module SketchupModel
    # Material related utilities.
    module Materials
      # Handle materials with its parents (component or group) and children with proxies.
      class MaterialManager
        # @return [Hash{String=>SpeckleObjects::RenderMaterialProxy}] render material proxies.
        attr_reader :render_material_proxies

        def initialize
          @render_material_proxies = {}
        end

        # @param entities [Sketchup::Entities, Array<Sketchup::Entity>] entities to unpack their materials
        def unpack_materials(entities, sketchup_model)
          unpacked_group_meshes_and_entities = []
          entities.each do |entity|
            if entity.is_a?(SpeckleObjects::Geometry::GroupedMesh)
              unpacked_group_meshes_and_entities += entity.faces
            else
              unpacked_group_meshes_and_entities << entity
            end
          end
          flat_entities = SketchupModel::Query::Entity.flat_entities(
            unpacked_group_meshes_and_entities, [Sketchup::ComponentInstance, Sketchup::Group, Sketchup::Face]
          )
          flat_entities.each do |entity|
            material = entity.material
            back_material = nil
            if entity.is_a?(Sketchup::Face)
              back_material = entity.back_material
            end

            if material.nil? && back_material.nil?
              next unless entity.parent.is_a?(Sketchup::ComponentDefinition)
              path = SketchupModel::Query::Entity.path_from_bottom_to_top(entity)
              parent_material = SketchupModel::Query::Entity.parent_material(path.reverse)
              material = parent_material
            end

            unless material.nil?
              if render_material_proxies.has_key?(material.persistent_id.to_s)
                render_material_proxies[material.persistent_id.to_s].add_object_id(entity.persistent_id.to_s)
              else
                convert_material_and_add_to_proxies(material, entity)
              end
            end

            unless back_material.nil?
              if render_material_proxies.has_key?(back_material.persistent_id.to_s)
                render_material_proxies[back_material.persistent_id.to_s]
                  .add_object_id("#{entity.persistent_id.to_s}_back")
              else
                convert_material_and_add_to_proxies(back_material, entity, true)
              end
            end
          end
          render_material_proxies.values
        end

        # @param material [Sketchup::Material]
        def convert_material_and_add_to_proxies(material, entity, is_back_material = false)
          speckle_material = SpeckleObjects::Other::RenderMaterial.from_material(material)
          entity_persistent_id = is_back_material ? "#{entity.persistent_id.to_s}_back" : entity.persistent_id.to_s
          render_material_proxies[material.persistent_id.to_s] = SpeckleObjects::RenderMaterialProxy.new(
            material, speckle_material,
            [entity_persistent_id], application_id: material.persistent_id.to_s
          )
        end
      end
    end
  end
end
