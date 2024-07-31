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
        def unpack_materials(entities)
          flat_entities = SketchupModel::Query::Entity.flat_entities(
            entities, [Sketchup::ComponentInstance, Sketchup::Group, Sketchup::Face]
          )
          flat_entities.each do |entity|
            next if entity.material.nil?

            if render_material_proxies.has_key?(entity.material.persistent_id.to_s)
              render_material_proxies[entity.material.persistent_id.to_s].add_object_id(entity.persistent_id.to_s)
            else
              speckle_material = SpeckleObjects::Other::RenderMaterial.from_material(entity.material)
              render_material_proxies[entity.material.persistent_id.to_s] = SpeckleObjects::RenderMaterialProxy.new(
                entity.material, speckle_material,
                [entity.persistent_id.to_s], application_id: entity.material.persistent_id.to_s
              )
            end
          end
          render_material_proxies.values
        end
      end
    end
  end
end
