# frozen_string_literal: true

require_relative '../artifacts/vocab'
require_relative '../speckle_objects/geometry/length'

module SpeckleConnector3
  module Converters
    # Extracts the model's scenes (pages) into {Artifacts::CameraView} rows for the
    # optional `{base}.envelope.camera_views.parquet` artefact. SketchUp's camera
    # space is inches — eye/target/ortho-height go through the SAME
    # `length_to_speckle` conversion as geometry vertices so the viewpoints land in
    # the geometry's coordinate space; direction/up are already normalized unit
    # vectors (unitless) and ship raw.
    module CameraViews
      SOG = SpeckleConnector3::SpeckleObjects::Geometry

      module_function

      # One row per page that saves camera state (`use_camera?`). `view` is a dense
      # 0..N-1 ordinal over the emitted rows; `ord` keeps the page's position in
      # the scene-tab order. `is_default` marks the selected page.
      # @param model [Sketchup::Model, nil] the model whose pages to extract
      # @param units [String] speckle model units (e.g. 'm', 'mm')
      # @return [Array<Artifacts::CameraView>] empty when there are no scenes
      def from_model(model, units)
        return [] if model.nil?

        pages = model.pages
        views = []
        pages.each_with_index do |page, ord|
          camera = page.use_camera? ? page.camera : nil
          next if camera.nil?

          views << from_page(views.length, ord, page, camera, page == pages.selected_page, units)
        end
        views
      end

      # Projection scalars are exclusive: fov (VERTICAL, degrees) + lens_mm for
      # perspective, ortho_height for ortho. near/far stay nil — SketchUp does not
      # expose clip distances.
      # rubocop:disable Metrics/ParameterLists
      def from_page(view, ord, page, camera, is_default, units)
        perspective = camera.perspective?
        Artifacts::CameraView.new(
          view: view, name: page.name, is_default: is_default, ord: ord,
          pos: point_to_speckle(camera.eye, units),
          forward: unit_vector(camera.direction),
          up: unit_vector(camera.up),
          target: point_to_speckle(camera.target, units),
          units: units,
          is_ortho: !perspective,
          fov: perspective ? vertical_fov(camera) : nil,
          lens_mm: perspective ? camera.focal_length.to_f : nil,
          ortho_height: perspective ? nil : SOG.length_to_speckle(camera.height, units),
          aspect: camera_aspect(camera),
          near: nil, far: nil
        )
      end
      # rubocop:enable Metrics/ParameterLists

      # `Camera#fov` is degrees, but measures frustum HEIGHT or WIDTH per
      # `fov_is_height?`. The bundle spec mandates VERTICAL fov: a width fov is
      # converted through the authored aspect ratio, or written null when the
      # camera follows the view aspect (no fixed ratio to convert with).
      def vertical_fov(camera)
        fov = camera.fov.to_f
        return fov unless camera.respond_to?(:fov_is_height?) && !camera.fov_is_height?

        aspect = camera_aspect(camera)
        return nil if aspect.nil?

        Math.atan(Math.tan(fov * Math::PI / 360.0) / aspect) * 360.0 / Math::PI
      end

      # `Camera#aspect_ratio` returns 0.0 for "use view aspect" -> null per spec.
      def camera_aspect(camera)
        aspect = camera.aspect_ratio.to_f
        aspect > 0 ? aspect : nil
      end

      def point_to_speckle(point, units)
        [
          SOG.length_to_speckle(point.x, units),
          SOG.length_to_speckle(point.y, units),
          SOG.length_to_speckle(point.z, units)
        ]
      end

      # A normalized Geom::Vector3d -> a plain unitless [x, y, z] triple.
      def unit_vector(vector)
        [vector.x.to_f, vector.y.to_f, vector.z.to_f]
      end
    end
  end
end
