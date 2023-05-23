# frozen_string_literal: true

require_relative 'color'
require_relative '../base'

module SpeckleConnector
  module SpeckleObjects
    module Other
      # RenderMaterial object definition for Speckle.
      class RenderMaterial < Base
        SPECKLE_TYPE = 'Objects.Other.RenderMaterial'

        # @param name [String] name of the render material.
        # @param diffuse [Numeric] diffuse value of the render material.
        # @param opacity [Numeric] opacity value of the render material.
        # @param emissive [Numeric] emissive value of the render material.
        # @param metalness [Numeric] metalness value of the render material.
        # @param roughness [Numeric] roughness value of the render material.
        # @param sketchup_attributes [Hash] sketchup_attributes of the render material.
        # @param application_id [Hash] application id of the render material.
        # rubocop:disable Metrics/ParameterLists
        def initialize(name:, diffuse:, opacity:, emissive:, metalness:, roughness:,
                       sketchup_attributes: {}, application_id: nil)
          super(
            speckle_type: SPECKLE_TYPE,
            total_children_count: 0,
            application_id: application_id,
            id: nil
          )
          self[:name] = name
          self[:diffuse] = diffuse
          self[:opacity] = opacity
          self[:emissive] = emissive
          self[:metalness] = metalness
          self[:roughness] = roughness
          self[:sketchup_attributes] = sketchup_attributes
        end
        # rubocop:enable Metrics/ParameterLists

        # @param material [Sketchup::Material] material on the Sketchup.
        def self.from_material(material)
          RenderMaterial.new(
            name: material.name,
            diffuse: Other::Color.to_int(material.color),
            opacity: material.alpha,
            emissive: -16_777_216,
            metalness: 0,
            roughness: 1
          )
        end

        # @param state [States::State] state of the application.
        def self.to_native(state, render_material, _layer, _entities, &_convert_to_native)
          return state, [] if render_material.nil?

          sketchup_model = state.sketchup_state.sketchup_model
          materials = state.sketchup_state.materials

          # return material with same name if it exists
          name = render_material['name'] || render_material['id']
          material = materials.by_id(name)
          return state, [material] if material

          # create a new sketchup material
          material = sketchup_model.materials.add(name)
          material.alpha = render_material['opacity']
          argb = render_material['diffuse']
          material.color = Color.from_int(argb)
          new_sketchup_state = state.sketchup_state.with_materials(materials.add_material(name, material))
          return state.with_sketchup_state(new_sketchup_state), [material]
        end
      end
    end
  end
end
