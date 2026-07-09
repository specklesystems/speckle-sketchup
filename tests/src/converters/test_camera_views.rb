# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../speckle_connector_3/src/convertors/camera_views'

module SpeckleConnector3
  module Converters
    # Pure-Ruby tests for the scenes -> camera_views extraction (no SketchUp
    # runtime): inch->model-unit conversion, vertical-fov normalization,
    # perspective/ortho projection scalars and the page skipping/ordinal rules.
    # SketchUp's Length/Point3d/Vector3d/Camera/Page/Pages are duck-typed stubs.
    class CameraViewsTest < Minitest::Test
      # SketchUp Length: a numeric in inches with unit conversion methods.
      StubLength = Struct.new(:inches) do
        def to_m
          inches * 0.0254
        end
      end

      StubPoint = Struct.new(:x, :y, :z)
      StubVector = Struct.new(:x, :y, :z)

      StubCamera = Struct.new(:perspective, :eye, :target, :direction, :up,
                              :fov, :fov_is_height, :aspect_ratio, :focal_length, :height,
                              keyword_init: true) do
        def perspective?
          perspective
        end

        def fov_is_height?
          fov_is_height
        end
      end

      StubPage = Struct.new(:name, :camera, :use_camera) do
        def use_camera?
          use_camera
        end
      end

      # Sketchup::Pages is enumerable and knows the selected page.
      class StubPages
        include Enumerable
        attr_reader :selected_page

        def initialize(pages, selected_page)
          @pages = pages
          @selected_page = selected_page
        end

        def each(&block)
          @pages.each(&block)
        end
      end

      StubModel = Struct.new(:pages)

      def length_point(x_in, y_in, z_in)
        StubPoint.new(StubLength.new(x_in), StubLength.new(y_in), StubLength.new(z_in))
      end

      def perspective_camera(**overrides)
        StubCamera.new(**{
          perspective: true, eye: length_point(100.0, 0.0, 50.0), target: length_point(100.0, 200.0, 50.0),
          direction: StubVector.new(0.0, 1.0, 0.0), up: StubVector.new(0.0, 0.0, 1.0),
          fov: 35.0, fov_is_height: true, aspect_ratio: 0.0, focal_length: 57.0, height: 0.0
        }.merge(overrides))
      end

      def test_perspective_page_converts_positions_to_model_units
        page = StubPage.new('Scene 1', perspective_camera, true)
        views = CameraViews.from_model(StubModel.new(StubPages.new([page], page)), 'm')

        assert_equal(1, views.length)
        v = views.first
        assert_equal(0, v.view)
        assert_equal('Scene 1', v.name)
        assert_equal(true, v.is_default)
        assert_equal(0, v.ord)
        assert_in_delta(2.54, v.pos[0])  # 100in -> m, same conversion as geometry
        assert_in_delta(1.27, v.pos[2])
        assert_in_delta(5.08, v.target[1]) # 200in -> m
        assert_equal([0.0, 1.0, 0.0], v.forward) # unit vector, NOT unit-converted
        assert_equal([0.0, 0.0, 1.0], v.up)
        assert_equal('m', v.units)
        assert_equal(false, v.is_ortho)
        assert_in_delta(35.0, v.fov)
        assert_in_delta(57.0, v.lens_mm)
        assert_nil(v.ortho_height)
        assert_nil(v.aspect) # 0.0 = "use view aspect" -> null
        assert_nil(v.near)
        assert_nil(v.far)
      end

      def test_width_fov_converts_to_vertical_through_aspect
        camera = perspective_camera(fov: 60.0, fov_is_height: false, aspect_ratio: 2.0)
        page = StubPage.new('Wide', camera, true)
        views = CameraViews.from_model(StubModel.new(StubPages.new([page], page)), 'm')

        expected = Math.atan(Math.tan(60.0 * Math::PI / 360.0) / 2.0) * 360.0 / Math::PI
        assert_in_delta(expected, views.first.fov)
        assert_in_delta(2.0, views.first.aspect)
      end

      def test_width_fov_without_aspect_writes_null
        camera = perspective_camera(fov: 60.0, fov_is_height: false, aspect_ratio: 0.0)
        page = StubPage.new('Wide', camera, true)
        views = CameraViews.from_model(StubModel.new(StubPages.new([page], page)), 'm')

        assert_nil(views.first.fov)
        assert_nil(views.first.aspect)
      end

      def test_ortho_page_writes_height_not_fov_or_lens
        camera = perspective_camera(perspective: false, height: StubLength.new(100.0))
        page = StubPage.new('Top', camera, true)
        views = CameraViews.from_model(StubModel.new(StubPages.new([page], page)), 'm')

        v = views.first
        assert_equal(true, v.is_ortho)
        assert_in_delta(2.54, v.ortho_height) # inches -> model units
        assert_nil(v.fov)
        assert_nil(v.lens_mm)
      end

      def test_skips_pages_without_saved_camera_and_keeps_dense_view_ordinals
        with_cam = StubPage.new('A', perspective_camera, true)
        no_use = StubPage.new('B', perspective_camera, false) # use_camera? false
        nil_cam = StubPage.new('C', nil, true)                 # no camera saved
        last = StubPage.new('D', perspective_camera, true)
        pages = StubPages.new([with_cam, no_use, nil_cam, last], last)
        views = CameraViews.from_model(StubModel.new(pages), 'm')

        assert_equal([0, 1], views.map(&:view))       # dense over emitted rows
        assert_equal([0, 3], views.map(&:ord))        # page (scene-tab) positions
        assert_equal([false, true], views.map(&:is_default)) # only the selected page
      end

      def test_nil_model_yields_no_views
        assert_empty(CameraViews.from_model(nil, 'm'))
      end
    end
  end
end
