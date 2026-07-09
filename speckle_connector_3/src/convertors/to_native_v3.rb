# frozen_string_literal: true

require_relative '../artifacts/bundle_reader'
require_relative '../speckle_objects/geometry/point'
require_relative '../speckle_objects/other/transform'
require_relative '../speckle_objects/other/color'

module SpeckleConnector3
  module Converters
    # Speckle 4.0 receive: rebuilds native SketchUp entities from a parquet artefact
    # bundle. The data reconstruction ({Artifacts::BundleReader}) is host-independent
    # and unit-tested headless; this class is the SketchUp-API layer that turns the
    # reconstructed model into tags, meshes, components, instances, and materials.
    #
    # Mirror of {ToSpeckleV3}; reuses the existing native primitives
    # (Point.to_native / Transform.to_native / Color.from_int / add_faces_from_mesh).
    class ToNativeV3
      POINT = SpeckleConnector3::SpeckleObjects::Geometry::Point
      TRANSFORM = SpeckleConnector3::SpeckleObjects::Other::Transform
      COLOR = SpeckleConnector3::SpeckleObjects::Other::Color

      # @return [Array<Sketchup::Entity>] top-level entities created this receive
      attr_reader :created_top_level

      # @param sketchup_model [Sketchup::Model]
      def initialize(sketchup_model)
        @model = sketchup_model
        @folder_by_path = {}
        @tag_by_path = {}
        @used_tag_names = {}
        @uniq_counter = 0
        @material_by_k = {}
        @definition_by_k = {}
        @created_top_level = []
      end

      # Reads a bundle from `dir` (base name `base`) and builds it into the model.
      # @return [Integer] number of top-level objects created
      def receive(dir, base)
        build(Artifacts::BundleReader.read(dir, base))
      end

      # @return [Array<String>] persistent ids of the created top-level entities
      def created_top_level_ids
        @created_top_level.reject(&:deleted?).map { |e| e.persistent_id.to_s }
      end

      # @param model [Hash] the reconstructed model from {Artifacts::BundleReader}
      def build(model)
        build_materials(model[:materials])
        build_definitions(model)
        model[:objects].each { |obj| build_object(model, obj) }
        model[:objects].length
      end

      private

      # ── tags / folders (from the default scene-view path) ─────────────

      # Resolves (building lazily) the SketchUp tag for an object's scene_path
      # [folder, …, tag]: the last segment is the tag, the rest are nested folders.
      def ensure_tag_path(segments)
        return nil if segments.nil? || segments.empty?

        key = segments.join(" ")
        return @tag_by_path[key] if @tag_by_path.key?(key)

        parent_folder = ensure_folder_path(segments[0..-2])
        tag = @model.layers.add(unique_tag_name(segments))
        tag.folder = parent_folder if parent_folder && tag.respond_to?(:folder=)
        @tag_by_path[key] = tag
      end

      def ensure_folder_path(segments)
        parent = nil
        path = []
        segments.each do |name|
          path << name
          key = path.join(" ")
          parent = (@folder_by_path[key] ||= begin
            folder = @model.layers.add_folder(name)
            folder.folder = parent if parent && folder.respond_to?(:folder=)
            folder
          end)
        end
        parent
      end

      # SketchUp tag names are globally unique, so a bare leaf is used when free; on a
      # collision (e.g. the same family name under different levels) the full path is.
      def unique_tag_name(segments)
        name = @used_tag_names.key?(segments.last) ? segments.join(' :: ') : segments.last
        name = "#{segments.join(' :: ')} (#{@uniq_counter += 1})" while @used_tag_names.key?(name)
        @used_tag_names[name] = true
        name
      end

      # ── materials ─────────────────────────────────────────────────────

      # Bakes each MATERIAL node under its authored name (pre-name bundles fall back
      # to the synthetic `speckle_<k>`), reusing an existing same-named material so
      # repeated receives don't multiply uniquified copies (`Brick Red1`, `Brick Red2`, …).
      def build_materials(materials)
        materials.each do |k, m|
          next if m[:argb].nil?

          name = m[:name].nil? || m[:name].empty? ? "speckle_#{k}" : m[:name]
          existing = @model.materials[name]
          if existing
            @material_by_k[k] = existing
            next
          end

          mat = @model.materials.add(name)
          mat.color = COLOR.from_int(m[:argb])
          mat.alpha = m[:opacity] unless m[:opacity].nil?
          @material_by_k[k] = mat
        end
      end

      # ── definitions ───────────────────────────────────────────────────

      def build_definitions(model)
        model[:definitions].each do |k, info|
          definition = @model.definitions.add(info[:name] || "speckle_def_#{k}")
          info[:geometry_ks].each do |geom_k|
            geometry = model[:geometries][geom_k]
            next if geometry.nil?

            material = @material_by_k[model[:material_by_geom][geom_k]]
            add_geometry(definition.entities, geometry, material, true)
          end
          @definition_by_k[k] = definition
        end
        # nested instances (DEFINES_INSTANCE) — definitions exist now, so wire placements
        model[:definitions].each do |k, info|
          info[:instance_ks].each do |inst_k|
            place_instance(@definition_by_k[k].entities, model[:instances][inst_k])
          end
        end
      end

      # ── objects ───────────────────────────────────────────────────────

      def build_object(model, obj)
        created =
          if obj[:display_instances].any?
            obj[:display_instances].map { |ik| place_instance(@model.entities, model[:instances][ik]) }
          else
            obj[:displays].flat_map do |geom_k|
              geometry = model[:geometries][geom_k]
              next [] if geometry.nil?

              material = @material_by_k[model[:material_by_geom][geom_k]]
              add_geometry(@model.entities, geometry, material, obj[:is_soften] != false)
            end
          end

        tag = ensure_tag_path(obj[:scene_path])
        created.compact.each do |e|
          e.layer = tag if tag && e.respond_to?(:layer=)
          @created_top_level << e
        end
      end

      def place_instance(entities, instance)
        return nil if instance.nil?

        definition = @definition_by_k[instance[:def_ref]]
        return nil if definition.nil?

        entities.add_instance(definition, TRANSFORM.to_native(instance[:transform], instance[:units]))
      end

      # ── geometry ──────────────────────────────────────────────────────

      # Adds a decoded SGEO geometry (mesh or line) to `entities`. Returns the created
      # entities (faces / edge) so the caller can tag them.
      def add_geometry(entities, geometry, material, is_soften)
        case geometry[:type]
        when :mesh then add_mesh(entities, geometry, material, is_soften)
        when :line then [add_line(entities, geometry)]
        when :polyline then add_polyline(entities, geometry)
        else []
        end
      end

      # A curve-family primitive (polyline / arc / circle / curve / …) -> SketchUp
      # edges through its decoded points (SketchUp has no native NURBS).
      def add_polyline(entities, geometry)
        units = geometry[:units]
        points = geometry[:points].map { |x, y, z| POINT.to_native(x, y, z, units) }
        points << points.first if geometry[:closed] && points.length > 2
        return [] if points.length < 2

        entities.add_edges(points)
      end

      def add_mesh(entities, geometry, material, is_soften)
        units = geometry[:units]
        points = geometry[:vertices].each_slice(3).map { |x, y, z| POINT.to_native(x, y, z, units) }
        polygon_mesh = Geom::PolygonMesh.new(points.length)
        faces = geometry[:faces].dup
        until faces.empty?
          count = faces.shift
          polygon_mesh.add_polygon(faces.shift(count).map { |i| points[i] })
        end
        smooth_flags = is_soften ? 4 : 1
        entities.add_faces_from_mesh(polygon_mesh, smooth_flags, material, material)
        entities.grep(Sketchup::Face).last(polygon_mesh.polygons.length)
      end

      def add_line(entities, geometry)
        units = geometry[:units]
        entities.add_line(
          POINT.to_native(*geometry[:start], units),
          POINT.to_native(*geometry[:end], units)
        )
      end
    end
  end
end
