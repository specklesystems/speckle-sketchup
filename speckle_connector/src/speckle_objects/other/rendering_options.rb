# frozen_string_literal: true

require_relative 'color'

module SpeckleConnector
  module SpeckleObjects
    module Others
      # Rendering options for scenes.
      class RenderingOptions
        # @param options [Sketchup::RenderingOptions] rendering options to convert speckle object
        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Metrics/MethodLength
        def self.to_speckle(options)
          {
            BackgroundColor: Color.to_speckle(options['BackgroundColor']),
            BandColor: Color.to_speckle(options['BandColor']),
            ConstructionColor: Color.to_speckle(options['ConstructionColor']),
            DepthQueWidth: options['DepthQueWidth'],
            DisplayColorByLayer: options['DisplayColorByLayer'],
            DisplayDims: options['DisplayDims'],
            DisplayFog: options['DisplayFog'],
            DisplayInstanceAxes: options['DisplayInstanceAxes'],
            DisplaySectionCuts: options['DisplaySectionCuts'],
            DisplaySectionPlanes: options['DisplaySectionPlanes'],
            DisplaySketchAxes: options['DisplaySketchAxes'],
            DisplayText: options['DisplayText'],
            DisplayWatermarks: options['DisplayWatermarks'],
            DrawBackEdges: options['DrawBackEdges'],
            DrawDepthQue: options['DrawDepthQue'],
            DrawGround: options['DrawGround'],
            DrawHidden: options['DrawHidden'],
            DrawHiddenGeometry: options['DrawHiddenGeometry'],
            DrawHiddenObjects: options['DrawHiddenObjects'],
            DrawHorizon: options['DrawHorizon'],
            DrawLineEnds: options['DrawLineEnds'],
            DrawProfilesOnly: options['DrawProfilesOnly'],
            DrawSilhouettes: options['DrawSilhouettes'],
            DrawUnderground: options['DrawUnderground'],
            EdgeColorMode: options['EdgeColorMode'],
            EdgeDisplayMode: options['EdgeDisplayMode'],
            EdgeType: options['EdgeType'],
            ExtendLines: options['ExtendLines'],
            FaceBackColor: Color.to_speckle(options['FaceBackColor']),
            FaceFrontColor: Color.to_speckle(options['FaceFrontColor']),
            FogColor: Color.to_speckle(options['FogColor']),
            FogEndDist: options['FogEndDist'],
            FogStartDist: options['FogStartDist'],
            FogUseBkColor: options['FogUseBkColor'],
            ForegroundColor: Color.to_speckle(options['ForegroundColor']),
            GroundColor: Color.to_speckle(options['GroundColor']),
            GroundTransparency: options['GroundTransparency'],
            HideConstructionGeometry: options['HideConstructionGeometry'],
            HighlightColor: Color.to_speckle(options['HighlightColor']),
            HorizonColor: Color.to_speckle(options['HorizonColor']),
            InactiveFade: options['InactiveFade'],
            InactiveHidden: options['InactiveHidden'],
            InstanceFade: options['InstanceFade'],
            InstanceHidden: options['InstanceHidden'],
            JitterEdges: options['JitterEdges'],
            LineEndWidth: options['LineEndWidth'],
            LineExtension: options['LineExtension'],
            LockedColor: Color.to_speckle(options['LockedColor']),
            MaterialTransparency: options['MaterialTransparency'],
            ModelTransparency: options['ModelTransparency'],
            RenderMode: options['RenderMode'],
            SectionActiveColor: Color.to_speckle(options['SectionActiveColor']),
            SectionCutDrawEdges: options['SectionCutDrawEdges'],
            SectionCutFilled: options['SectionCutFilled'],
            SectionCutWidth: options['SectionCutWidth'],
            SectionDefaultCutColor: Color.to_speckle(options['SectionDefaultCutColor']),
            SectionDefaultFillColor: Color.to_speckle(options['SectionDefaultFillColor']),
            SectionInactiveColor: Color.to_speckle(options['SectionInactiveColor']),
            ShowViewName: options['ShowViewName'],
            SilhouetteWidth: options['SilhouetteWidth'],
            SkyColor: Color.to_speckle(options['SkyColor']),
            Texture: options['Texture'],
            TransparencySort: options['TransparencySort']
          }
        end
        # rubocop:enable Metrics/AbcSize
        # rubocop:enable Metrics/MethodLength
      end
    end
  end
end
