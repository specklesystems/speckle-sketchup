# frozen_string_literal: true

module SpeckleConnector3
  module Artifacts
    # The fixed envelope relation/node vocabulary + scene-view projection types,
    # mirroring the `speckle-bundle-spec` catalog (schema_version 5). These integer
    # codes are a cross-connector contract — never invent new ones here without the
    # matching spec change + a schema_version bump. Retired ids (rels 13, 15-20, 22;
    # node kind 6 COLLECTION, folded into CONTAINER + `subtype`) are kept vacant and
    # never reused; {BundleReader} still accepts them when reading pre-v5 bundles.
    module RelKind
      DISPLAY = 1
      SOLID = 2 # reserved
      SUBELEMENT = 3
      # `ord` is the MEMBER ordinal: DEFINES rows sharing (definition, ord) are one
      # member's geometries and join to DEFINES_MEMBER on the same key.
      DEFINES = 4
      HAS_MATERIAL = 5
      HAS_COLOR = 6
      ON_LEVEL = 7
      DISPLAY_INSTANCE = 8
      DEFINES_INSTANCE = 9
      IN_COLLECTION = 10
      IN_MODEL = 11
      IN_ROOM = 12
      IN_SYSTEM = 14
      CONNECTS_TO = 21
      BOUNDS = 23
      # Member/painting vocabulary (post-v5 additive; replaces the `@speckle.*`
      # member eav stamps and the ord=1 HAS_MATERIAL namespace stamp — both still
      # emitted this release for old consumers).
      PLACES = 24              # member object -> its INSTANCE node (association only, never a render root)
      DEFINES_MEMBER = 25      # DEFINITION -> member object; ord = member ordinal (joins DEFINES on (definition, ord))
      OBJECT_HAS_MATERIAL = 26 # painted object -> MATERIAL node; FILL semantics (geometry-level HAS_MATERIAL wins)
      OBJECT_HAS_COLOR = 27    # object -> COLOR node; FILL semantics (geometry-level HAS_COLOR wins); not emitted by SketchUp
    end

    module NodeKind
      DEFINITION = 1
      INSTANCE = 2
      MATERIAL = 3
      COLOR = 4
      LEVEL = 5
      CONTAINER = 7
    end

    # One ordered key of a scene-view projection. `source` is 'rel' (a RelKind code,
    # stringified) or 'eav' (a bare eav attribute key).
    SceneViewKey = Struct.new(:source, :ref) do
      def self.rel(rel_code)
        new('rel', rel_code.to_s)
      end

      def self.eav(attr_key)
        new('eav', attr_key)
      end
    end

    # A producer-authored scene-explorer projection. `keys` are outermost-first.
    SceneView = Struct.new(:view, :name, :is_default, :keys)

    # One named camera viewpoint (a SketchUp scene/page camera) — a row of the
    # optional `{base}.envelope.camera_views.parquet` artefact. `pos`/`target` are
    # [x, y, z] triples in `units` (model units — same space as the geometry);
    # `forward`/`up` are [x, y, z] NORMALIZED unit vectors (unitless). `fov` is the
    # VERTICAL field of view in degrees and, like `lens_mm`, is perspective-only
    # (nil for ortho); `ortho_height` is ortho-only (in `units`). `target`, `fov`,
    # `lens_mm`, `ortho_height`, `aspect`, `near` and `far` may all be nil.
    CameraView = Struct.new(
      :view, :name, :is_default, :ord,
      :pos, :forward, :up, :target, :units,
      :is_ortho, :fov, :lens_mm, :ortho_height, :aspect, :near, :far,
      keyword_init: true
    )
  end
end
