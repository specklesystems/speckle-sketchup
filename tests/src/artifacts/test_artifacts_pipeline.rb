# frozen_string_literal: true

require_relative '../../test_helper'
require 'tmpdir'
require_relative '../../../speckle_connector_3/src/artifacts/objects_artifact_pipeline'
require_relative '../../../speckle_connector_3/src/artifacts/sgeo_encoder'
require_relative '../../../speckle_connector_3/src/artifacts/sgeo_decoder'
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

      def test_sgeo_mesh_hard_edges_flag
        verts = [0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0]
        faces = [3, 0, 1, 2]

        soft = SgeoEncoder.encode_mesh(verts, faces, 'm')
        hard = SgeoEncoder.encode_mesh(verts, faces, 'm', hard_edges: true)

        # Inverted polarity: default/unset = legacy soften; bit 11 set = hard.
        assert_equal(0, soft[6, 2].unpack1('v') & SgeoEncoder::FLAG_HARD_EDGES)
        refute_equal(0, hard[6, 2].unpack1('v') & SgeoEncoder::FLAG_HARD_EDGES)

        decoded_soft = SgeoDecoder.decode(soft)
        decoded_hard = SgeoDecoder.decode(hard)
        refute(decoded_soft[:hard_edges])
        assert(decoded_hard[:hard_edges])
        # The flag is header-only: bodies stay identical.
        assert_equal(decoded_soft[:vertices], decoded_hard[:vertices])
        assert_equal(decoded_soft[:faces], decoded_hard[:faces])
      end

      def test_sgeo_hard_edges_distinct_blobs_for_identity
        verts = [0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0]
        faces = [3, 0, 1, 2]
        # Softness lives in the hashed bytes: hard/soft variants of the same mesh
        # must never collapse to one blob (content-hash identity, ENG-9124 principle).
        refute_equal(SgeoEncoder.encode_mesh(verts, faces, 'm'),
                     SgeoEncoder.encode_mesh(verts, faces, 'm', hard_edges: true))
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

      # ENG-8841 -> rel 29: a tag's colour rides a NODE_HAS_COLOR edge to a COLOR
      # node and survives the produce->read round trip; folders stay colourless.
      def test_tag_color_round_trips_via_rel29
        Dir.mktmpdir('speckle-artifacts') do |dir|
          base = 'ver1'
          p = ObjectsArtifactPipeline.new(dir, base)
          folder = p.add_collection('folder-1', 'Site', nil, 'Folder')
          trees = p.add_collection('tag-1', 'Trees', folder, 'Layer')
          p.node_has_color(trees, p.add_color(-65_536))
          p.complete

          colls = BundleReader.read(dir, base)[:collections].values
          assert_equal(-65_536, colls.find { |c| c[:name] == 'Trees' }[:argb])
          assert_nil(colls.find { |c| c[:name] == 'Site' }[:argb])
        end
      end

      # Rel 29 (NODE_HAS_COLOR) is the SOLE carrier: the CONTAINER row's argb (the
      # pre-rel-29 overload) is no longer written, and same-coloured tags intern
      # to one COLOR node.
      def test_tag_color_rel29_edge_replaces_container_argb
        Dir.mktmpdir('speckle-artifacts') do |dir|
          base = 'ver1'
          p = ObjectsArtifactPipeline.new(dir, base)
          trees = p.add_collection('tag-1', 'Trees', nil, 'Layer')
          p.node_has_color(trees, p.add_color(-65_536))
          shrubs = p.add_collection('tag-2', 'Shrubs', nil, 'Layer')
          p.node_has_color(shrubs, p.add_color(-65_536))
          p.complete

          nodes = ParquetSource.read_hashes(File.join(dir, "#{base}.envelope.nodes.parquet"))
          container = nodes.find { |n| n['kind'] == NodeKind::CONTAINER && n['name'] == 'Trees' }
          assert_nil(container['argb']) # the argb overload is dead on send

          color_nodes = nodes.select { |n| n['kind'] == NodeKind::COLOR }
          assert_equal(1, color_nodes.length) # interned: one COLOR node per distinct argb
          assert_equal(-65_536, color_nodes.first['argb'])

          rels = ParquetSource.read_hashes(File.join(dir, "#{base}.envelope.relations.parquet"))
          edges = rels.select { |r| r['rel'] == RelKind::NODE_HAS_COLOR }
          assert_equal(2, edges.length)
          edge = edges.find { |r| r['src'] == container['id'] }
          refute_nil(edge)
          assert_equal(color_nodes.first['id'], edge['dst'])
        end
      end

      # Old bundles carried the tag colour as an argb on the CONTAINER row (no rel
      # 29): the reader still resolves it, and when a bundle carries both (other
      # producers' transitional output) the rel-29 edge wins over a stale argb.
      def test_tag_color_container_argb_fallback_and_rel29_precedence
        nodes = {
          10 => { 'kind' => NodeKind::CONTAINER, 'name' => 'Trees', 'subtype' => 'Layer', 'argb' => -1 },
          11 => { 'kind' => NodeKind::CONTAINER, 'name' => 'Shrubs', 'subtype' => 'Layer', 'argb' => -16_711_936 },
          20 => { 'kind' => NodeKind::COLOR, 'argb' => -65_536 }
        }
        model = { collections: {}, materials: {}, colors: {}, definitions: {}, instances: {}, node_meta: {},
                  geometries: {}, material_by_geom: {}, material_by_inst: {}, member_tag_paths: {},
                  instance_meta: {} }
        BundleReader.classify_nodes(nodes, model)
        BundleReader.wire_relations([{ 'rel' => RelKind::NODE_HAS_COLOR, 'src' => 10, 'dst' => 20 }], model, {}, {}, [])

        assert_equal(-65_536, model[:collections][10][:argb])      # edge wins over the stale argb
        assert_equal(-16_711_936, model[:collections][11][:argb])  # argb-only (old bundle) unchanged
      end

      # ENG-8842: definition description + dictionaries ride the TYPE tables keyed
      # by the definition id (its type_key) and come back as definition_meta —
      # joined by the stamped definition node k, with the name join kept for
      # pre-stamp bundles. Definitions are types, not scene objects: the objects
      # table stays empty.
      def test_definition_metadata_round_trips
        Dir.mktmpdir('speckle-artifacts') do |dir|
          base = 'ver1'
          p = ObjectsArtifactPipeline.new(dir, base)
          p.add_type_properties(
            'def-42', { 'Classifier' => { 'code' => 'XX-1' } },
            [['speckle_type', BundleReader::DEFINITION_PROXY_TYPE], ['name', 'Teddy'],
             ['description', 'A soft bear'], ['@speckle.definition_k', 3]]
          )
          p.complete

          meta = BundleReader.read(dir, base)[:definition_meta]
          assert_equal([3, 'Teddy'], meta.keys.sort_by(&:to_s))
          assert_same(meta['Teddy'], meta[3]) # one entry, both join keys
          assert_equal('A soft bear', meta[3][:description])
          assert_equal({ 'Classifier' => { 'code' => 'XX-1' } }, meta[3][:dictionaries])
          assert_empty(ParquetSource.read_hashes(File.join(dir, "#{base}.eav.objects.parquet")))
        end
      end

      # Pre-type-split bundles carried definition metadata as an eav pseudo-object
      # row-set — those already-published models must keep resolving.
      def test_legacy_eav_keyed_definition_metadata_still_resolves
        Dir.mktmpdir('speckle-artifacts') do |dir|
          base = 'ver1'
          p = ObjectsArtifactPipeline.new(dir, base)
          p.add_properties(
            'def-42', { 'Classifier' => { 'code' => 'XX-1' } },
            [['speckle_type', BundleReader::DEFINITION_PROXY_TYPE], ['name', 'Teddy'],
             ['description', 'A soft bear'], ['@speckle.definition_k', 3]]
          )
          p.complete

          meta = BundleReader.read(dir, base)[:definition_meta]
          assert_equal('A soft bear', meta[3][:description])
          assert_equal({ 'Classifier' => { 'code' => 'XX-1' } }, meta[3][:dictionaries])
        end
      end

      # The full star schema: placements link through object_type to the shared
      # type_eav row-set, written exactly once however many placements (and
      # add_type_properties calls) there are — and the link order is free: objects
      # may link before the type's rows land (entity pass vs post-loop).
      def test_definition_attributes_ride_type_tables
        Dir.mktmpdir('speckle-artifacts') do |dir|
          base = 'ver1'
          p = ObjectsArtifactPipeline.new(dir, base)
          root = [['speckle_type', BundleReader::DEFINITION_PROXY_TYPE], ['name', 'Door-A'],
                  ['@speckle.definition_k', 5]]
          p.intern_object('inst-201')
          p.add_object_type('inst-201', 'def-100') # link BEFORE rows exist
          p.intern_object('inst-202')
          p.add_object_type('inst-202', 'def-100')
          p.add_type_properties('def-100', { 'props' => { 'height' => 2100 } }, root)
          p.add_type_properties('def-100', { 'props' => { 'height' => 2100 } }, root) # no-op
          p.complete

          read = ->(t) { ParquetSource.read_hashes(File.join(dir, "#{base}.eav.#{t}.parquet")) }
          assert_equal(%w[inst-201 inst-202], read.call('objects').map { |r| r['application_id'] }.sort)

          types = read.call('types')
          assert_equal(['def-100'], types.map { |r| r['type_key'] })
          type_index = types.first['type_index']

          links = read.call('object_type')
          assert_equal([type_index] * 2, links.map { |r| r['type_index'] })
          assert_equal(read.call('objects').map { |r| r['object_index'] }.sort,
                       links.map { |r| r['object_index'] }.sort)

          type_rows = read.call('type_eav')
          assert_equal(4, type_rows.length, 'type rows must be written exactly once')
          assert(type_rows.all? { |r| r['type_index'] == type_index })

          meta = BundleReader.read(dir, base)[:definition_meta]
          assert_equal({ 'props' => { 'height' => 2100.0 } }, meta[5][:dictionaries])
        end
      end

      # Numeric-looking metadata strings ("1000") are stored typed by the eav
      # inference (value_double) but must come back as Strings — a Float
      # description/name crashes the SketchUp setters on receive.
      def test_numeric_looking_metadata_round_trips_as_string
        Dir.mktmpdir('speckle-artifacts') do |dir|
          base = 'ver1'
          p = ObjectsArtifactPipeline.new(dir, base)
          p.add_type_properties(
            'def-1', {},
            [['speckle_type', BundleReader::DEFINITION_PROXY_TYPE], ['name', '101'],
             ['description', '1000'], ['@speckle.definition_k', 3]]
          )
          p.add_properties(
            'inst-1', {},
            [['speckle_type', BundleReader::INSTANCE_PROXY_TYPE], ['name', '2.5'], ['@speckle.instance_k', 7]]
          )
          p.complete

          model = BundleReader.read(dir, base)
          assert_equal('1000', model[:definition_meta][3][:description])
          assert(model[:definition_meta].key?('101'), 'name join key must be the authored string')
          assert_equal('2.5', model[:instance_meta][7][:name])
        end
      end

      # SketchUp's advanced-attribute dictionaries are string-typed — the panel
      # ignores non-String values. A Price authored as "1" gets query-typed to
      # value_double 1.0 by the eav inference and must come back as the authored
      # string "1" (definition set via type_eav, instance set via eav).
      def test_advanced_attribute_values_round_trip_as_strings
        Dir.mktmpdir('speckle-artifacts') do |dir|
          base = 'ver1'
          p = ObjectsArtifactPipeline.new(dir, base)
          p.add_type_properties(
            'def-1', { 'SU_DefinitionSet' => { 'Price' => '1', 'Size' => 'a' } },
            [['speckle_type', BundleReader::DEFINITION_PROXY_TYPE], ['name', 'Box'], ['@speckle.definition_k', 3]]
          )
          p.add_properties(
            'inst-1', { 'SU_InstanceSet' => { 'Owner' => '42' }, 'MyDict' => { 'count' => '42' } },
            [['speckle_type', BundleReader::INSTANCE_PROXY_TYPE], ['@speckle.instance_k', 7]]
          )
          p.complete

          model = BundleReader.read(dir, base)
          assert_equal({ 'Price' => '1', 'Size' => 'a' },
                       model[:definition_meta][3][:dictionaries]['SU_DefinitionSet'])
          assert_equal({ 'Owner' => '42' }, model[:instance_meta][7][:dictionaries]['SU_InstanceSet'])
          # non-SU dictionaries keep the query-typed value
          assert_equal(42.0, model[:instance_meta][7][:dictionaries]['MyDict']['count'])
        end
      end

      # Nested-instance metadata round-trips via the `@speckle.instance_k` stamp:
      # the eav row-set is keyed by the member's own persistent id and joined back
      # to the INSTANCE node by its dense id.
      def test_instance_metadata_round_trips
        Dir.mktmpdir('speckle-artifacts') do |dir|
          base = 'ver1'
          p = ObjectsArtifactPipeline.new(dir, base)
          p.add_properties(
            'inst-9', { 'MyDict' => { 'serial' => 'A-77' } },
            [['speckle_type', BundleReader::INSTANCE_PROXY_TYPE], ['name', 'Chair A'], ['@speckle.instance_k', 7]]
          )
          p.complete

          meta = BundleReader.read(dir, base)[:instance_meta]
          assert_equal([7], meta.keys)
          assert_equal('Chair A', meta[7][:name])
          assert_equal({ 'MyDict' => { 'serial' => 'A-77' } }, meta[7][:dictionaries])
        end
      end

      # HAS_MATERIAL src spans two id namespaces (spec rel 5: geometry|instance,
      # ENG-8849) that overlap numerically — the reader must route INSTANCE-sourced
      # edges (placement painting) and geometry-sourced edges into separate maps,
      # or colliding ids paint objects with unrelated materials.
      def test_instance_and_geometry_materials_route_to_separate_maps
        Dir.mktmpdir('speckle-artifacts') do |dir|
          base = 'ver1'
          p = ObjectsArtifactPipeline.new(dir, base)
          def_k = p.add_definition('def-1', 'Box')                     # node 0
          inst_k = p.add_instance('inst-1', def_k, [1.0, 0, 0, 0, 0, 1.0, 0, 0, 0, 0, 1.0, 0, 0, 0, 0, 1.0], 'm')
          mat_geo = p.add_material('mat-geo', 'Skin', -2_000_000, 1.0, 0.0, 1.0)
          mat_inst = p.add_material('mat-inst', 'Paint', -65_536, 1.0, 0.0, 1.0)
          blob = SgeoEncoder.encode_mesh([0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0], [3, 0, 1, 2], 'm')
          p.add_geometry('mesh-0', blob)
          geom = p.add_geometry('mesh-1', blob + 'x')                  # geometry 1 == inst_k numerically
          assert_equal(inst_k, geom, 'test setup: ids must collide')
          p.has_material(geom, mat_geo)
          p.has_material(inst_k, mat_inst, instance: true)
          p.complete

          model = BundleReader.read(dir, base)
          assert_equal({ geom => mat_geo }, model[:material_by_geom])
          assert_equal({ inst_k => mat_inst }, model[:material_by_inst])
        end
      end

      # Pre-stamp bundles (no ord discriminator): an UNPAINTED instance whose node
      # id collides with a painted geometry must not steal that material — the
      # ambiguous id defaults to geometry. An instance-sourced edge whose id
      # cannot be a geometry is still recovered as placement paint.
      def test_legacy_material_edges_default_ambiguous_ids_to_geometry
        Dir.mktmpdir('speckle-artifacts') do |dir|
          base = 'ver1'
          p = ObjectsArtifactPipeline.new(dir, base)
          def_k = p.add_definition('def-1', 'Box')                     # node 0
          inst_a = p.add_instance('inst-a', def_k, [1.0, 0, 0, 0, 0, 1.0, 0, 0, 0, 0, 1.0, 0, 0, 0, 0, 1.0], 'm') # node 1
          inst_b = p.add_instance('inst-b', def_k, [1.0, 0, 0, 0, 0, 1.0, 0, 0, 0, 0, 1.0, 0, 0, 0, 0, 1.0], 'm') # node 2
          mat = p.add_material('mat-skin', 'Skin', -2_000_000, 1.0, 0.0, 1.0)
          mat_paint = p.add_material('mat-paint', 'Paint', -65_536, 1.0, 0.0, 1.0)
          blob = SgeoEncoder.encode_mesh([0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0], [3, 0, 1, 2], 'm')
          p.add_geometry('mesh-0', blob)
          geom = p.add_geometry('mesh-1', blob + 'x')                  # geometry 1 == inst_a
          p.has_material(geom, mat)                                    # legacy: no stamp
          p.has_material(inst_b, mat_paint)                            # legacy instance edge, id not a geometry
          p.complete

          model = BundleReader.read(dir, base)
          assert_equal({ geom => mat }, model[:material_by_geom], 'ambiguous id stays geometry-scoped')
          assert_equal({ inst_b => mat_paint }, model[:material_by_inst], 'unambiguous instance edge recovered')
          refute(model[:material_by_inst].key?(inst_a), 'colliding unpainted instance must not steal the material')
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

          # BundleReader exposes the same rows (scene-tab order) for receive.
          reader_views = BundleReader.read(dir, base)[:camera_views]
          assert_equal(%w[Persp Top], reader_views.map { |r| r['name'] })
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
          assert_equal([], BundleReader.read(dir, base)[:camera_views])
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

      # Post-v5 member vocabulary (rels 24/25/26): member carrier objects join back
      # to their definition content through DEFINES_MEMBER's (definition, ord) key
      # and PLACES — no `@speckle.*` stamps — and placement paint rides
      # OBJECT_HAS_MATERIAL resolved to the placement. This is the stamp-less
      # future-bundle shape; the fallback test below covers the stamped past.
      def test_member_rels_round_trip_without_stamps
        Dir.mktmpdir('speckle-artifacts') do |dir|
          base = 'ver1'
          p = ObjectsArtifactPipeline.new(dir, base)
          trees = p.add_collection('tag-trees', 'Trees', nil, 'Layer')
          p.add_scene_view(SceneView.new(0, 'Default', true, [SceneViewKey.rel(RelKind::IN_COLLECTION)]))

          def_k = p.add_definition('def-1', 'Planter')
          blob = SgeoEncoder.encode_mesh([0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0], [3, 0, 1, 2], 'm')
          geom_k = p.add_geometry('member-mesh', blob)
          p.defines(def_k, geom_k, 0)
          mesh_member_k = p.intern_object('member-mesh-obj')
          p.in_collection(mesh_member_k, trees, 0)
          p.defines_member(def_k, mesh_member_k, 0)

          nested_def_k = p.add_definition('def-2', 'Shrub')
          inst_k = p.add_instance('member-inst', nested_def_k, [1.0] + [0.0] * 4 + [1.0] + [0.0] * 4 + [1.0] + [0.0] * 4 + [1.0], 'm')
          p.defines_instance(def_k, inst_k, 1)
          inst_member_k = p.intern_object('member-inst-obj')
          p.in_collection(inst_member_k, trees, 0)
          p.places(inst_member_k, inst_k)
          p.defines_member(def_k, inst_member_k, 1)
          mat_k = p.add_material('mat-green', 'Leaf', -16_711_936, 1.0, nil, nil)
          p.object_has_material(inst_member_k, mat_k)

          top_obj_k = p.intern_object('planter-1')
          top_inst_k = p.add_instance('planter-1', def_k, [1.0] + [0.0] * 4 + [1.0] + [0.0] * 4 + [1.0] + [0.0] * 4 + [1.0], 'm')
          p.display_instance(top_obj_k, top_inst_k, 0)
          p.object_has_material(top_obj_k, mat_k)
          p.complete

          rels = ParquetSource.read_hashes(File.join(dir, "#{base}.envelope.relations.parquet"))
          dm = rels.select { |r| r['rel'] == RelKind::DEFINES_MEMBER }
          assert_equal([[def_k, mesh_member_k, 0], [def_k, inst_member_k, 1]],
                       dm.map { |r| [r['src'], r['dst'], r['ord']] }.sort)
          defines_ords = rels.select { |r| r['rel'] == RelKind::DEFINES }.to_h { |r| [r['ord'], r['dst']] }
          assert_equal(geom_k, defines_ords[0]) # DEFINES ord aligns with DEFINES_MEMBER ord
          assert_equal([[inst_member_k, inst_k]],
                       rels.select { |r| r['rel'] == RelKind::PLACES }.map { |r| [r['src'], r['dst']] })

          model = BundleReader.read(dir, base)
          app_ids = model[:objects].map { |o| o[:app_id] }
          assert_includes(app_ids, 'planter-1')
          refute_includes(app_ids, 'member-mesh-obj', 'member carriers must not become scene objects')
          refute_includes(app_ids, 'member-inst-obj')
          assert_equal(['Trees'], model[:member_tag_paths][geom_k], 'tag path joined via (definition, ord), no stamp')
          assert_equal(mat_k, model[:material_by_inst][inst_k], 'rel-26 paint resolved via PLACES')
          assert_equal(mat_k, model[:material_by_inst][top_inst_k], 'rel-26 paint resolved via DISPLAY_INSTANCE')
          assert_equal(['Trees'], model[:instance_meta][inst_k][:scene_path])
        end
      end

      # Pre-rel-24/25 bundles carry only the `@speckle.geometry_k` /
      # `@speckle.instance_k` eav stamps — the fallback path must behave exactly
      # as before the vocabulary landed.
      def test_member_stamp_fallback_still_works
        Dir.mktmpdir('speckle-artifacts') do |dir|
          base = 'ver1'
          p = ObjectsArtifactPipeline.new(dir, base)
          trees = p.add_collection('tag-trees', 'Trees', nil, 'Layer')
          p.add_scene_view(SceneView.new(0, 'Default', true, [SceneViewKey.rel(RelKind::IN_COLLECTION)]))

          def_k = p.add_definition('def-1', 'Planter')
          blob = SgeoEncoder.encode_mesh([0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0], [3, 0, 1, 2], 'm')
          geom_k = p.add_geometry('member-mesh', blob)
          p.defines(def_k, geom_k, 0)
          mesh_member_k = p.intern_object('member-mesh-obj')
          p.in_collection(mesh_member_k, trees, 0)
          p.add_properties('member-mesh-obj', {}, [['@speckle.geometry_k', geom_k]])
          p.complete

          model = BundleReader.read(dir, base)
          refute_includes(model[:objects].map { |o| o[:app_id] }, 'member-mesh-obj')
          assert_equal(['Trees'], model[:member_tag_paths][geom_k])
        end
      end
    end
  end
end
