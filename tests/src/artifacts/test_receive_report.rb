# frozen_string_literal: true

require_relative '../../test_helper'
require 'tmpdir'
require_relative '../../../speckle_connector_3/src/artifacts/objects_artifact_pipeline'
require_relative '../../../speckle_connector_3/src/artifacts/sgeo_encoder'
require_relative '../../../speckle_connector_3/src/artifacts/bundle_reader'
require_relative '../../../speckle_connector_3/src/ui_data/report/receive_report'

module SpeckleConnector3
  module Artifacts
    # ENG-9122: artifact receive must report per-object conversion results in
    # the DUI shape — success rows, skipped/unsupported geometry with reasons,
    # per-object failures — instead of an unconditional empty report. These
    # tests cover the headless halves: BundleReader's skip surfacing and
    # ReceiveReport's row decisions.
    class ReceiveReportTest < Minitest::Test
      REPORT = UiData::Report::ReceiveReport
      STATUS = UiData::Report::ConversionStatus

      MESH_BLOB = SgeoEncoder.encode_mesh(
        [0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0], [3, 0, 1, 2], 'm'
      )
      # Rhino-style raw solid payload: no SGEO magic.
      FOREIGN_BLOB = '3D Geometry File Format ........'.b
      # SGEO magic + version + mesh type byte, then a truncated (empty) body —
      # decodes far enough to fail, i.e. an undecodable SGEO blob.
      CORRUPT_BLOB = ('SGEO' + 1.chr + 0.chr + ("\x00" * 10)).b

      def build_bundle(dir, base)
        p = ObjectsArtifactPipeline.new(dir, base)

        wall = p.intern_object('wall-1')
        p.add_properties('wall-1', {}, [['speckle_type', 'Objects.Geometry.Mesh'], ['units', 'm']])
        p.display(wall, p.add_geometry('mesh-1', MESH_BLOB), 0)

        solid = p.intern_object('solid-1')
        p.add_properties('solid-1', {}, [['speckle_type', 'Objects.Geometry.Brep'], ['units', 'm']])
        p.display(solid, p.add_geometry('brep-1', FOREIGN_BLOB), 0)

        combo = p.intern_object('combo-1')
        p.add_properties('combo-1', {}, [['speckle_type', 'Objects.Geometry.Mesh'], ['units', 'm']])
        p.display(combo, p.intern_geometry_id('mesh-1'), 0)
        p.display(combo, p.add_geometry('bad-mesh-1', CORRUPT_BLOB), 1)

        def_k = p.add_definition('door-def', 'Door')
        p.defines(def_k, p.intern_geometry_id('brep-1'), 0)

        p.complete
        BundleReader.read(dir, base)
      end

      def with_model(&block)
        Dir.mktmpdir('speckle-receive-report') do |dir|
          block.call(build_bundle(dir, 'ver1'))
        end
      end

      def object(model, app_id)
        model[:objects].find { |o| o[:app_id] == app_id }
      end

      def test_bundle_reader_surfaces_skip_reasons_per_geometry
        with_model do |model|
          assert_equal(1, model[:geometries].length, 'only the SGEO mesh decodes')
          reasons = model[:skipped_geometry].values.sort
          assert_equal(2, reasons.length)
          assert_match(/non-SGEO geometry blob/, reasons.first)
          assert_match(/undecodable SGEO blob/, reasons.last)
        end
      end

      def test_fully_converted_object_reports_success
        with_model do |model|
          row = REPORT.object_row(model, object(model, 'wall-1'), [{ id: '41', type: 'Face' }])
          assert_equal(STATUS::SUCCESS, row[:status])
          assert_equal('wall-1', row[:sourceId])
          assert_equal('Mesh', row[:sourceType])
          assert_equal('41', row[:resultId])
          assert_equal('Face', row[:resultType])
          assert_nil(row[:error])
        end
      end

      def test_object_with_only_skipped_geometry_reports_warning_with_reason
        with_model do |model|
          row = REPORT.object_row(model, object(model, 'solid-1'), [])
          assert_equal(STATUS::WARNING, row[:status])
          assert_equal('solid-1', row[:sourceId])
          assert_equal('Brep', row[:sourceType])
          assert_match(/skipped/, row[:error][:message])
          assert_match(/non-SGEO geometry blob/, row[:error][:message])
        end
      end

      def test_partially_converted_object_reports_warning_but_keeps_result
        with_model do |model|
          row = REPORT.object_row(model, object(model, 'combo-1'), [{ id: '7', type: 'Face' }])
          assert_equal(STATUS::WARNING, row[:status])
          assert_equal('7', row[:resultId], 'partial conversion still points at what was baked')
          assert_match(/partially converted/, row[:error][:message])
          assert_match(/undecodable SGEO blob/, row[:error][:message])
        end
      end

      def test_unsupported_primitive_reports_warning
        model = { geometries: { 9 => { type: :unsupported, primitive: 10, units: 'm' } } }
        obj = { app_id: 'box-1', displays: [9], display_instances: [], properties: {} }
        row = REPORT.object_row(model, obj, [])
        assert_equal(STATUS::WARNING, row[:status])
        assert_match(/unsupported primitive '10'/, row[:error][:message])
      end

      def test_missing_instance_placement_reports_warning
        model = { instances: {}, definitions: {} }
        obj = { app_id: 'chair-1', displays: [], display_instances: [3], properties: {} }
        row = REPORT.object_row(model, obj, [])
        assert_equal(STATUS::WARNING, row[:status])
        assert_match(/instance 3 missing from bundle/, row[:error][:message])
      end

      def test_failed_object_reports_error_with_exception
        error = begin
          raise StandardError, 'add_group exploded'
        rescue StandardError => e
          e
        end
        row = REPORT.object_error_row({ app_id: 'wall-9', properties: {} }, error)
        assert_equal(STATUS::ERROR, row[:status])
        assert_equal('wall-9', row[:sourceId])
        assert_match(/add_group exploded/, row[:error][:message])
        refute_nil(row[:error][:stackTrace])
      end

      def test_definition_member_losses_report_under_definition_name
        with_model do |model|
          rows = REPORT.definition_rows(model)
          assert_equal(1, rows.length)
          assert_equal(STATUS::WARNING, rows.first[:status])
          assert_equal('Door', rows.first[:sourceId])
          assert_match(/non-SGEO geometry blob/, rows.first[:error][:message])
        end
      end
    end
  end
end
