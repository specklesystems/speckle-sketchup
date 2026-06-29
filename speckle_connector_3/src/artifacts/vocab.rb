# frozen_string_literal: true

module SpeckleConnector3
  module Artifacts
    # The fixed envelope relation/node vocabulary + scene-view projection types,
    # mirroring the SDK's `EnvelopeWriter.RelKind` / `NodeKind` / `SceneView`.
    # These integer codes are a cross-connector contract — never invent new ones
    # here without the matching SDK change + a schema_version bump.
    module RelKind
      DISPLAY = 1
      SOLID = 2
      SUBELEMENT = 3
      DEFINES = 4
      HAS_MATERIAL = 5
      HAS_COLOR = 6
      ON_LEVEL = 7
      DISPLAY_INSTANCE = 8
      DEFINES_INSTANCE = 9
      IN_COLLECTION = 10
      IN_MODEL = 11
      IN_ROOM = 12
      IN_SPACE = 13
      IN_SYSTEM = 14
      IN_NETWORK = 15
      IN_LINE = 16
      IN_GROUP = 17
      IN_ASSEMBLY = 18
      IN_SUBASSEMBLY = 19
      XREF = 20
      CONNECTS_TO = 21
      HOSTED_ON = 22
    end

    module NodeKind
      DEFINITION = 1
      INSTANCE = 2
      MATERIAL = 3
      COLOR = 4
      LEVEL = 5
      COLLECTION = 6
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
  end
end
