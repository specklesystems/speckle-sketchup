# frozen_string_literal: true

require_relative '../../test_helper'
require 'tmpdir'
require_relative '../../../speckle_connector_3/src/artifacts/objects_artifact_pipeline'
require_relative '../../../speckle_connector_3/src/artifacts/sgeo_encoder'

module SpeckleConnector3
  module Artifacts
    # Pure-Ruby tests for the 4.0 artefact producer (no SketchUp runtime needed).
    # Geometry/topology/eav writers are exercised end-to-end; the parquet output is
    # asserted structurally here (full DuckDB round-trip lives in the dev harness).
    class ArtifactsPipelineTest < Minitest::Test
      def test_sgeo_mesh_roundtrip
        verts = [0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0]
        faces = [3, 0, 1, 2]
        blob = SgeoEncoder.encode_mesh(verts, faces, 'm')

        assert_equal('SGEO', blob[0, 4])
        assert_equal(1, blob[4].ord)              # version
        assert_equal(0, blob[5].ord)              # primitive type Mesh
        assert_equal(3, blob[8, 2].unpack1('v'))  # units code: m => 3
        assert_equal(Zlib.crc32(blob[16..]), blob[12, 4].unpack1('V'))
        body = blob[16..]
        assert_equal(3, body[0, 4].unpack1('V'))  # vertex count
        assert_equal(4, body[4, 4].unpack1('V'))  # face stream length
        assert_equal(verts, body[8, 9 * 8].unpack('E*'))
      end

      def test_sgeo_line_units
        blob = SgeoEncoder.encode_line([0.0, 0.0, 0.0], [10.0, 0.0, 0.0], 'ft')
        assert_equal(1, blob[5].ord)             # Line
        assert_equal(6, blob[8, 2].unpack1('v')) # ft => 6
      end

      def test_eav_type_inference_and_parameter_pattern
        props = {
          'Length' => { 'name' => 'Length', 'value' => 0.12, 'units' => 'm', 'internalDefinitionName' => 'LEN' },
          'flag' => true,
          'uuidish' => 'e89b00ed-5ca8-46a2'
        }
        rows = EavExtraction.flatten_properties(props, [['name', 'Bolt']])
        by_path = rows.each_with_object({}) { |r, h| h[r.path] = r }

        assert_equal('Bolt', by_path['name'].value_text)
        len = by_path['properties.Length']
        assert_equal(0.12, len.value_num)
        assert_equal('number', len.type)
        assert_equal('m', len.unit)
        assert_equal('LEN', len.internal_definition_name)
        assert_equal('boolean', by_path['properties.flag'].type)
        assert_equal('true', by_path['properties.flag'].value_text)
        assert_equal('string', by_path['properties.uuidish'].type) # UUID-like rejected from numeric
      end

      def test_full_bundle_produces_valid_parquet_files
        Dir.mktmpdir('speckle-artifacts') do |dir|
          base = 'ver1'
          p = ObjectsArtifactPipeline.new(dir, base)

          arch = p.add_collection('lay:arch', 'Architecture', nil, 'Layer')
          walls = p.add_collection('lay:walls', 'Walls', arch, 'Layer')

          obj = p.intern_object('face-1')
          p.in_collection(obj, walls, 0)
          p.add_properties('face-1', { 'area' => { 'name' => 'area', 'value' => 12.5, 'units' => 'm2' } },
                           [['speckle_type', 'Objects.Geometry.Mesh'], ['units', 'm']])
          blob = SgeoEncoder.encode_mesh([0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0, 1.0, 0.0], [4, 0, 1, 2, 3], 'm')
          g = p.add_geometry('mesh-1', blob)
          p.display(obj, g, 0)
          mat = p.add_material('mat-red', -65_536, 1.0, 0.0, 1.0)
          p.has_material(g, mat)
          p.add_scene_view(SceneView.new(0, 'Default', true, [SceneViewKey.rel(RelKind::IN_COLLECTION)]))
          p.complete

          expected = %w[
            geometries
            eav.objects eav.paths eav.eav eav.types eav.type_eav eav.object_type
            envelope.relations envelope.nodes envelope.meta envelope.rel_types envelope.node_kinds
            envelope.scene_views
          ]
          expected.each do |suffix|
            path = File.join(dir, "#{base}.#{suffix}.parquet")
            assert(File.file?(path), "missing #{suffix}.parquet")
            bytes = File.binread(path)
            assert_equal('PAR1', bytes[0, 4], "#{suffix}: bad header magic")
            assert_equal('PAR1', bytes[-4, 4], "#{suffix}: bad footer magic")
          end
        end
      end
    end
  end
end
