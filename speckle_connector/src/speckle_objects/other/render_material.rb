# frozen_string_literal: true

require_relative '../../typescript/typescript_object'

module SpeckleConnector
  module SpeckleObjects
    module Other
      # RenderMaterial object definition for Speckle.
      class RenderMaterial < Typescript::TypescriptObject
        SPECKLE_TYPE = 'Objects.Other.RenderMaterial'
        ATTRIBUTE_TYPES = {
          speckle_type: String,
          name: String,
          diffuse: Numeric,
          opacity: Numeric,
          emissive: Numeric,
          metalness: Numeric,
          roughness: Numeric
        }.freeze

        def self.from_material(material)
          rgba = material.color.to_a
          RenderMaterial.new(
            speckle_type: SPECKLE_TYPE,
            name: material.name,
            diffuse: [rgba[3] << 24 | rgba[0] << 16 | rgba[1] << 8 | rgba[2]].pack('l').unpack1('l'),
            opacity: material.alpha,
            emissive: -16_777_216,
            metalness: 0,
            roughness: 1
          )
        end

        private

        def attribute_types
          ATTRIBUTE_TYPES
        end
      end
    end
  end
end
