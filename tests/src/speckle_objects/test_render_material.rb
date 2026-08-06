# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../speckle_connector_3/src/speckle_objects/other/render_material'

module SpeckleConnector3
  module SpeckleObjects
    # Authored PBR channel extraction for the artifact path (ENG-9121) — pure
    # Ruby, the SketchUp Material API is stubbed by shape (respond_to?-based
    # capability detection).
    class RenderMaterialPbrTest < Minitest::Test
      # SketchUp < 2025: no PBR Material API at all.
      class LegacyMaterial; end

      # SketchUp 2025.0+ Material with authorable PBR channels.
      class PbrMaterial
        def initialize(metalness_enabled:, metallic_factor:, roughness_enabled:, roughness_factor:)
          @me = metalness_enabled
          @mf = metallic_factor
          @re = roughness_enabled
          @rf = roughness_factor
        end

        def metalness_enabled?
          @me
        end

        def metallic_factor
          @mf
        end

        def roughness_enabled?
          @re
        end

        def roughness_factor
          @rf
        end
      end

      def test_no_pbr_api_yields_nils
        assert_equal([nil, nil], Other::RenderMaterial.pbr_channels(LegacyMaterial.new))
      end

      def test_enabled_channels_publish_authored_factors
        mat = PbrMaterial.new(metalness_enabled: true, metallic_factor: 0.85,
                              roughness_enabled: true, roughness_factor: 0.2)
        assert_equal([0.85, 0.2], Other::RenderMaterial.pbr_channels(mat))
      end

      def test_disabled_channels_yield_nil_not_defaults
        mat = PbrMaterial.new(metalness_enabled: false, metallic_factor: 0.85,
                              roughness_enabled: false, roughness_factor: 0.2)
        assert_equal([nil, nil], Other::RenderMaterial.pbr_channels(mat))
      end

      def test_mixed_channels
        mat = PbrMaterial.new(metalness_enabled: true, metallic_factor: 1.0,
                              roughness_enabled: false, roughness_factor: 0.4)
        assert_equal([1.0, nil], Other::RenderMaterial.pbr_channels(mat))
      end

      def test_v2_from_material_contract_unchanged
        # The legacy path keeps fixed values — only the artifact path consumes
        # pbr_channels.
        assert_respond_to Other::RenderMaterial, :from_material
      end
    end
  end
end
