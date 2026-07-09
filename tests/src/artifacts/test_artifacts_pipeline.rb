# frozen_string_literal: true

require_relative '../../test_helper'
require 'tmpdir'
require_relative '../../../speckle_connector_3/src/artifacts/objects_artifact_pipeline'
require_relative '../../../speckle_connector_3/src/artifacts/sgeo_encoder'
require_relative '../../../speckle_connector_3/src/artifacts/bundle_reader'

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
          mat = p.add_material('mat-red', 'Brick Red', -65_536, 1.0, 0.0, 1.0)
          p.has_material(g, mat)
          p.add_scene_view(SceneView.new(0, 'Default', true, [SceneViewKey.rel(RelKind::IN_COLLECTION)]))
          p.add_camera_view(CameraView.new(
                              view: 0, name: 'Scene 1', is_default: true, ord: 0,
                              pos: [1.0, 2.0, 3.0], forward: [0.0, 1.0, 0.0], up: [0.0, 0.0, 1.0],
                              target: [1.0, 12.0, 3.0], units: 'm', is_ortho: false,
                              fov: 35.0, lens_mm: 57.0, ortho_height: nil, aspect: nil, near: nil, far: nil
                            ))
          p.complete

          expected = %w[
            geometries
            eav.objects eav.paths eav.eav eav.types eav.type_eav eav.object_type
            envelope.relations envelope.nodes envelope.meta envelope.rel_types envelope.node_kinds
            envelope.scene_views envelope.camera_views
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

      # ENG-8847: the viewer resolves the scene tree via
      # `SELECT id, name, def_ref, subtype FROM nodes WHERE kind = 7` — collections
      # must be CONTAINER (7) rows carrying their discriminator in a real `subtype`
      # column (bundle-spec v5), not COLLECTION (6) rows overloading `units`.
      def test_collections_are_v5_containers_with_subtype_column
        Dir.mktmpdir('speckle-artifacts') do |dir|
          base = 'ver1'
          p = ObjectsArtifactPipeline.new(dir, base)
          folder = p.add_collection('folder-1', 'Site', nil, 'Folder')
          p.add_collection('tag-1', 'Trees', folder, 'Layer')
          p.complete

          meta = ParquetSource.read_hashes(File.join(dir, "#{base}.envelope.meta.parquet"))
          assert_equal(EnvelopeWriter::SCHEMA_VERSION, meta.first['schema_version'])

          nodes = ParquetSource.read_hashes(File.join(dir, "#{base}.envelope.nodes.parquet"))
          containers = nodes.select { |n| n['kind'] == NodeKind::CONTAINER }
          assert_equal(2, containers.length)
          assert_equal(%w[Folder Layer], containers.map { |n| n['subtype'] }.sort)
          assert(containers.all? { |n| n['units'].nil? }, 'subtype must not ride in units')
          assert_empty(nodes.select { |n| n['kind'] == BundleReader::LEGACY_COLLECTION_KIND })
        end
      end

      # ENG-8840: MATERIAL nodes must carry the SketchUp material name in the
      # envelope `name` column and it must survive the produce->read round trip
      # (receive falls back to `speckle_<k>` only when the name is absent).
      def test_material_name_round_trips
        Dir.mktmpdir('speckle-artifacts') do |dir|
          base = 'ver1'
          p = ObjectsArtifactPipeline.new(dir, base)
          p.add_material('mat-red', 'Brick Red', -65_536, 0.5, 0.0, 1.0)
          p.complete

          materials = BundleReader.read(dir, base)[:materials]
          assert_equal(1, materials.length)
          mat = materials.values.first
          assert_equal('Brick Red', mat[:name])
          assert_equal(-65_536, mat[:argb])
          assert_in_delta(0.5, mat[:opacity])
        end
      end

      # ENG-8841: a tag collection carries its colour on the container node's argb
      # and it survives the produce->read round trip; folders stay colourless.
      def test_tag_color_round_trips
        Dir.mktmpdir('speckle-artifacts') do |dir|
          base = 'ver1'
          p = ObjectsArtifactPipeline.new(dir, base)
          folder = p.add_collection('folder-1', 'Site', nil, 'Folder')
          p.add_collection('tag-1', 'Trees', folder, 'Layer', -65_536)
          p.complete

          colls = BundleReader.read(dir, base)[:collections].values
          assert_equal(-65_536, colls.find { |c| c[:name] == 'Trees' }[:argb])
          assert_nil(colls.find { |c| c[:name] == 'Site' }[:argb])
        end
      end

      # ENG-8842: definition description + dictionaries ride the eav table keyed by
      # the definition id and come back as definition_meta (joined by name).
      def test_definition_metadata_round_trips
        Dir.mktmpdir('speckle-artifacts') do |dir|
          base = 'ver1'
          p = ObjectsArtifactPipeline.new(dir, base)
          p.add_properties(
            'def-42', { 'Classifier' => { 'code' => 'XX-1' } },
            [['speckle_type', BundleReader::DEFINITION_PROXY_TYPE], ['name', 'Teddy'], ['description', 'A soft bear']]
          )
          p.complete

          meta = BundleReader.read(dir, base)[:definition_meta]
          assert_equal(['Teddy'], meta.keys)
          assert_equal('A soft bear', meta['Teddy'][:description])
          assert_equal({ 'Classifier' => { 'code' => 'XX-1' } }, meta['Teddy'][:dictionaries])
        end
      end

      # Camera viewpoints round-trip through the frozen bundle-spec `camera_views`
      # schema: one row per view, positions in model units, forward/up unit vectors,
      # perspective/ortho projection scalars mutually exclusive, near/far null.
      def test_camera_views_round_trip
        Dir.mktmpdir('speckle-artifacts') do |dir|
          base = 'ver1'
          p = ObjectsArtifactPipeline.new(dir, base)
          p.add_camera_view(CameraView.new(
                              view: 0, name: 'Persp', is_default: true, ord: 0,
                              pos: [1.5, -2.0, 3.25], forward: [0.0, 1.0, 0.0], up: [0.0, 0.0, 1.0],
                              target: [1.5, 8.0, 3.25], units: 'm', is_ortho: false,
                              fov: 35.0, lens_mm: 57.0, ortho_height: nil, aspect: 1.5, near: nil, far: nil
                            ))
          p.add_camera_view(CameraView.new(
                              view: 1, name: 'Top', is_default: false, ord: 3,
                              pos: [0.0, 0.0, 10.0], forward: [0.0, 0.0, -1.0], up: [0.0, 1.0, 0.0],
                              target: nil, units: 'm', is_ortho: true,
                              fov: nil, lens_mm: nil, ortho_height: 12.5, aspect: nil, near: nil, far: nil
                            ))
          p.complete

          rows = ParquetSource.read_hashes(File.join(dir, "#{base}.envelope.camera_views.parquet"))
          assert_equal(2, rows.length)

          persp = rows[0]
          assert_equal(0, persp['view'])
          assert_equal('Persp', persp['name'])
          assert_equal(true, persp['is_default'])
          assert_equal(0, persp['ord'])
          assert_in_delta(1.5, persp['pos_x'])
          assert_in_delta(-2.0, persp['pos_y'])
          assert_in_delta(3.25, persp['pos_z'])
          assert_in_delta(1.0, persp['forward_y'])
          assert_in_delta(1.0, persp['up_z'])
          assert_in_delta(8.0, persp['target_y'])
          assert_equal('m', persp['units'])
          assert_equal(false, persp['is_ortho'])
          assert_in_delta(35.0, persp['fov'])
          assert_in_delta(57.0, persp['lens_mm'])
          assert_nil(persp['ortho_height'])
          assert_in_delta(1.5, persp['aspect'])
          assert_nil(persp['near'])
          assert_nil(persp['far'])

          ortho = rows[1]
          assert_equal(1, ortho['view'])
          assert_equal(3, ortho['ord'])
          assert_equal(true, ortho['is_ortho'])
          assert_nil(ortho['target_x'])
          assert_nil(ortho['fov'])
          assert_nil(ortho['lens_mm'])
          assert_in_delta(12.5, ortho['ortho_height'])
          assert_nil(ortho['aspect'])
        end
      end

      # camera_views is an OPTIONAL artefact: a bundle with no viewpoints must not
      # ship the file at all (absent means "the model ships no viewpoints").
      def test_camera_views_file_absent_when_no_views_added
        Dir.mktmpdir('speckle-artifacts') do |dir|
          base = 'ver1'
          p = ObjectsArtifactPipeline.new(dir, base)
          p.add_collection('tag-1', 'Trees', nil, 'Layer')
          p.complete

          refute(File.exist?(File.join(dir, "#{base}.envelope.camera_views.parquet")))
        end
      end

      # Pre-v5 bundles (COLLECTION kind 6, subtype overloaded into `units`) must
      # still classify, so old already-published models keep receiving.
      def test_bundle_reader_accepts_legacy_collection_rows
        legacy = { 10 => { 'kind' => 6, 'name' => 'Trees', 'def_ref' => nil, 'units' => 'Layer' } }
        current = { 11 => { 'kind' => 7, 'name' => 'Site', 'def_ref' => nil, 'subtype' => 'Folder' } }
        model = { collections: {}, materials: {}, colors: {}, definitions: {}, instances: {}, node_meta: {} }
        BundleReader.classify_nodes(legacy.merge(current), model)

        assert_equal('Layer', model[:collections][10][:subtype])
        assert_equal('Folder', model[:collections][11][:subtype])
        assert_equal(%w[Site Trees], model[:node_meta].values.map { |m| m[:name] }.sort)
      end
    end
  end
end
