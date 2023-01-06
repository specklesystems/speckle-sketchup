# frozen_string_literal: true

require_relative '../base'
require_relative '../geometry/bounding_box'
require_relative '../other/render_material'
require_relative '../../convertors/clean_up'
require_relative '../../sketchup_model/dictionary/dictionary_handler'

module SpeckleConnector
  module SpeckleObjects
    # Geometry objects in the Speckleverse.
    module Geometry
      # Mesh object definition for Speckle.
      class Mesh < Base
        SPECKLE_TYPE = 'Objects.Geometry.Mesh'

        # @param units [String] units of the speckle mesh.
        # @param render_material [Other::RenderMaterial, nil] render material of the speckle mesh.
        # @param bbox [Geometry::BoundingBox] bounding box speckle object of the speckle mesh.
        # @param vertices [Array] vertices of the speckle mesh.
        # @param faces [Array] faces of the speckle mesh.
        # @param face_edge_flags [Array] face edge flags of the speckle mesh.
        # @param sketchup_attributes [Hash] additional information about speckle mesh.
        # rubocop:disable Metrics/ParameterLists
        def initialize(units:, render_material:, bbox:, vertices:, faces:, face_edge_flags:, sketchup_attributes:)
          super(
            speckle_type: SPECKLE_TYPE,
            total_children_count: 0,
            application_id: nil,
            id: nil
          )
          self[:units] = units
          self[:renderMaterial] = render_material
          self[:bbox] = bbox
          self[:'@(31250)vertices'] = vertices
          self[:'@(62500)faces'] = faces
          self[:'@(31250)faceEdgeFlags'] = face_edge_flags
          self[:sketchup_attributes] = sketchup_attributes if sketchup_attributes.any?
        end
        # rubocop:enable Metrics/ParameterLists

        # @param entities [Sketchup::Entities] entities to add
        # rubocop:disable Metrics/MethodLength
        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Metrics/CyclomaticComplexity
        def self.to_native(sketchup_model, mesh, layer, entities, model_preferences)
          # Get soft? flag of {Sketchup::Edge} object to understand smoothness of edge.
          is_soften = get_soften_setting(mesh)
          smooth_flags = is_soften ? 4 : 1
          # Get native points to add polygon into native mesh.
          points = get_native_points(mesh)
          # Initialize native PolygonMesh object later to add polygon inside it.
          native_mesh = Geom::PolygonMesh.new(mesh['vertices'].count / 3)
          faces = mesh['faces']
          while faces.count > 0
            num_pts = faces.shift
            # 0 -> 3, 1 -> 4 to preserve backwards compatibility
            num_pts += 3 if num_pts < 3
            indices = faces.shift(num_pts)
            native_mesh.add_polygon(indices.map { |index| points[index] })
          end
          material = Other::RenderMaterial.to_native(sketchup_model, mesh['renderMaterial'])
          entities.add_faces_from_mesh(native_mesh, smooth_flags, material)
          added_faces = entities.grep(Sketchup::Face).last(native_mesh.polygons.length)
          added_faces.each do |face|
            face.layer = layer
            unless mesh['sketchup_attributes'].nil?
              SketchupModel::Dictionary::DictionaryHandler
                .attribute_dictionaries_to_native(face, mesh['sketchup_attributes']['dictionaries'])
            end
          end
          # Merge only added faces in this scope
          Converters::CleanUp.merge_coplanar_faces(added_faces) if model_preferences[:merge_coplanar_faces]
          native_mesh
        end
        # rubocop:enable Metrics/MethodLength
        # rubocop:enable Metrics/AbcSize
        # rubocop:enable Metrics/CyclomaticComplexity

        # @param face [Sketchup::Face] face to convert mesh
        # rubocop:disable Style/MultilineTernaryOperator
        # rubocop:disable Metrics/CyclomaticComplexity
        # rubocop:disable Metrics/PerceivedComplexity
        def self.from_face(face, units, model_preferences)
          dictionaries = {}
          if model_preferences[:include_entity_attributes]
            dictionaries = SketchupModel::Dictionary::DictionaryHandler.attribute_dictionaries_to_speckle(face)
          end
          mesh = face.loops.count > 1 ? face.mesh : nil
          has_any_soften_edge = face.edges.any?(&:soft?)
          att = dictionaries.any? ? { is_soften: has_any_soften_edge, dictionaries: dictionaries }
                  : { is_soften: has_any_soften_edge }
          Mesh.new(
            units: units,
            render_material: face.material.nil? && face.back_material.nil? ? nil : Other::RenderMaterial
                                                          .from_material(face.material || face.back_material),
            bbox: Geometry::BoundingBox.from_bounds(face.bounds, units),
            vertices: mesh.nil? ? face_vertices_to_array(face, units) : mesh_points_to_array(mesh, units),
            faces: mesh.nil? ? face_indices_to_array(face, 0) : mesh_faces_to_array(mesh, -1),
            face_edge_flags: mesh.nil? ? face_edge_flags_to_array(face) : mesh_edge_flags_to_array(mesh),
            sketchup_attributes: att
          )
        end
        # rubocop:enable Style/MultilineTernaryOperator
        # rubocop:enable Metrics/CyclomaticComplexity
        # rubocop:enable Metrics/PerceivedComplexity

        # get a flat array of vertices from a list of sketchup vertices
        def self.face_vertices_to_array(face, units)
          pts_array = []
          face.vertices.each do |v|
            pt = v.position
            pts_array.push(Geometry.length_to_speckle(pt[0], units),
                           Geometry.length_to_speckle(pt[1], units),
                           Geometry.length_to_speckle(pt[2], units))
          end
          pts_array
        end

        # get a flat array of vertices from a sketchup polygon mesh
        def self.mesh_points_to_array(mesh, units)
          pts_array = []
          mesh.points.each do |pt|
            pts_array.push(
              Geometry.length_to_speckle(pt[0], units),
              Geometry.length_to_speckle(pt[1], units),
              Geometry.length_to_speckle(pt[2], units)
            )
          end
          pts_array
        end

        # get a flat array of face indices from a sketchup face
        def self.face_indices_to_array(face, offset)
          face_array = [face.vertices.count]
          face_array.push(*face.vertices.count.times.map { |index| index + offset })
          face_array
        end

        # get an array of face indices from a sketchup polygon mesh
        def self.mesh_faces_to_array(mesh, offset = 0)
          faces = []
          mesh.polygons.each do |poly|
            faces.push(
              poly.count, *poly.map { |index| index.abs + offset }
            )
          end
          faces
        end

        def self.face_edge_flags_to_array(face)
          face.outer_loop.edges.map(&:soft?)
        end

        def self.mesh_edge_flags_to_array(mesh)
          edge_flags = []
          mesh.polygons.each do |poly|
            edge_flags.push(
              *poly.map(&:negative?)
            )
          end
          edge_flags
        end

        def self.get_soften_setting(mesh)
          if mesh['sketchup_attributes'].nil?
            true
          else
            mesh['sketchup_attributes']['is_soften'].nil? ? true : mesh['sketchup_attributes']['is_soften']
          end
        end

        def self.get_native_points(mesh)
          points = []
          mesh['vertices'].each_slice(3) do |pt|
            points.push(Point.to_native(pt[0], pt[1], pt[2], mesh['units']))
          end
          points
        end
      end
    end
  end
end
