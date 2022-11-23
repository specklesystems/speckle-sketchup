# frozen_string_literal: true

require_relative '../geometry/bounding_box'
require_relative '../other/render_material'
require_relative '../../typescript/typescript_object'
require_relative '../../convertors/clean_up'

module SpeckleConnector
  module SpeckleObjects
    # Geometry objects in the Speckleverse.
    module Geometry
      include Converters::CleanUp

      # Mesh object definition for Speckle.
      class Mesh < Typescript::TypescriptObject
        SPECKLE_TYPE = 'Objects.Geometry.Mesh'
        ATTRIBUTES = {
          speckle_type: String,
          units: String,
          renderMaterial: [NilClass, Other::RenderMaterial],
          bbox: Geometry::BoundingBox,
          '@(31250)vertices': Array,
          '@(62500)faces': Array,
          '@(31250)faceEdgeFlags': Array
        }.freeze

        def self.to_native(sketchup_model, mesh, entities)
          native_mesh = Geom::PolygonMesh.new(mesh['vertices'].count / 3)
          points = []
          mesh['vertices'].each_slice(3) do |pt|
            points.push(Point.to_native(pt[0], pt[1], pt[2], mesh['units']))
          end
          faces = mesh['faces']
          while faces.count > 0
            num_pts = faces.shift
            # 0 -> 3, 1 -> 4 to preserve backwards compatibility
            num_pts += 3 if num_pts < 3
            indices = faces.shift(num_pts)
            native_mesh.add_polygon(indices.map { |index| points[index] })
          end
          material = Other::RenderMaterial.to_native(sketchup_model, mesh['renderMaterial'])
          entities.add_faces_from_mesh(native_mesh, 4, material)
          merge_coplanar_faces(entities)
          native_mesh
        end

        # @param face [Sketchup::Face] face to convert mesh
        def self.from_face(face, units)
          mesh = face.loops.count > 1 ? face.mesh : nil
          Mesh.new(
            speckle_type: SPECKLE_TYPE,
            units: units,
            renderMaterial: face.material.nil? ? nil : Other::RenderMaterial.from_material(face.material),
            bbox: Geometry::BoundingBox.from_bounds(face.bounds, units),
            '@(31250)vertices': mesh.nil? ? face_vertices_to_array(face, units) : mesh_points_to_array(mesh, units),
            '@(62500)faces': mesh.nil? ? face_indices_to_array(face, 0) : mesh_faces_to_array(mesh, -1),
            '@(31250)faceEdgeFlags': mesh.nil? ? face_edge_flags_to_array(face) : mesh_edge_flags_to_array(mesh)
          )
        end

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

        def attribute_types
          ATTRIBUTES
        end
      end
    end
  end
end
