# frozen_string_literal: true

require_relative '../base'
require_relative '../../typescript/typescript_object'

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
          rgba = material.color.to_a
          RenderMaterial.new(
            name: material.name,
            diffuse: [rgba[3] << 24 | rgba[0] << 16 | rgba[1] << 8 | rgba[2]].pack('l').unpack1('l'),
            opacity: material.alpha,
            emissive: -16_777_216,
            metalness: 0,
            roughness: 1
          )
        end

        # @param sketchup_model [Sketchup::Model] active model on the sketchup.
        def self.to_native(sketchup_model, render_material)
          return if render_material.nil?

          # return material with same name if it exists
          name = render_material['name'] || render_material['id']
          material = sketchup_model.materials[name]
          return material if material

          # create a new sketchup material
          material = sketchup_model.materials.add(name)
          material.alpha = render_material['opacity']
          argb = render_material['diffuse']
          material.color = Sketchup::Color.new((argb >> 16) & 255, (argb >> 8) & 255, argb & 255, (argb >> 24) & 255)
          material
        end
      end
    end
  end
end
