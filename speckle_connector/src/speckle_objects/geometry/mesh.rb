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

        # @return [Array<Geom::Point3d>] points that construct mesh.
        attr_accessor :vertices

        # @return [Array] polygons
        attr_accessor :polygons

        # @return [String] speckle units.
        attr_reader :units

        # @param units [String] units of the speckle mesh.
        # @param render_material [Other::RenderMaterial, nil] render material of the speckle mesh.
        # @param vertices [Array] vertices of the speckle mesh.
        # @param faces [Array] faces of the speckle mesh.
        # @param sketchup_attributes [Hash] additional information about speckle mesh.
        # rubocop:disable Metrics/ParameterLists
        def initialize(units:, render_material:, vertices:, faces:, sketchup_attributes:, application_id: nil)
          super(
            speckle_type: SPECKLE_TYPE,
            total_children_count: 0,
            application_id: application_id,
            id: nil
          )
          @vertices = []
          @polygons = []
          @units = units
          self[:units] = units
          self[:renderMaterial] = render_material
          # self[:bbox] = bbox
          self[:'@(31250)vertices'] = vertices
          self[:'@(62500)faces'] = faces
          self[:sketchup_attributes] = sketchup_attributes if sketchup_attributes.any?
        end
        # rubocop:enable Metrics/ParameterLists

        # @param entities [Sketchup::Entities] entities to add
        # rubocop:disable Metrics/MethodLength
        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Metrics/CyclomaticComplexity
        # rubocop:disable Metrics/PerceivedComplexity:
        def self.to_native(state, mesh, layer, entities, &convert_to_native)
          model_preferences = state.user_state.preferences[:model]
          # Get soft? flag of {Sketchup::Edge} object to understand smoothness of edge.
          is_soften = get_soften_setting(mesh, entities)
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
          state, _materials = Other::RenderMaterial.to_native(state, mesh['renderMaterial'],
                                                              layer, entities, &convert_to_native)
          # Find and assign material if exist
          unless mesh['renderMaterial'].nil?
            material_name = mesh['renderMaterial']['name'] || mesh['renderMaterial']['id']
            # Retrieve material from state
            material = state.sketchup_state.materials.by_id(material_name)
          end

          # Add faces from mesh with material and smooth setting
          entities.add_faces_from_mesh(native_mesh, smooth_flags, material, material)
          added_faces = entities.grep(Sketchup::Face).last(native_mesh.polygons.length)
          added_faces.each do |face|
            face.layer = layer
            unless mesh['sketchup_attributes'].nil?
              SketchupModel::Dictionary::DictionaryHandler
                .attribute_dictionaries_to_native(face, mesh['sketchup_attributes']['dictionaries'])
            end
          end
          # Merge only added faces in this scope
          if model_preferences[:merge_coplanar_faces]
            added_faces = Converters::CleanUp.merge_coplanar_faces(added_faces)
          end
          return state, added_faces
        end
        # rubocop:enable Metrics/MethodLength
        # rubocop:enable Metrics/AbcSize
        # rubocop:enable Metrics/CyclomaticComplexity
        # rubocop:enable Metrics/PerceivedComplexity:

        # @param face [Sketchup::Face] face to convert mesh
        # rubocop:disable Style/MultilineTernaryOperator
        # rubocop:disable Metrics/CyclomaticComplexity
        def self.from_face(face, units, model_preferences)
          dictionaries = {}
          if model_preferences[:include_entity_attributes] && model_preferences[:include_face_entity_attributes]
            dictionaries = SketchupModel::Dictionary::DictionaryHandler.attribute_dictionaries_to_speckle(face)
          end
          has_any_soften_edge = face.edges.any?(&:soft?)
          att = dictionaries.any? ? { is_soften: has_any_soften_edge, dictionaries: dictionaries }
                  : { is_soften: has_any_soften_edge }
          speckle_mesh = Mesh.new(
            units: units,
            render_material: face.material.nil? && face.back_material.nil? ? nil : Other::RenderMaterial
                                                          .from_material(face.material || face.back_material),
            # bbox: Geometry::BoundingBox.from_bounds(face.bounds, units),
            vertices: [],
            faces: [],
            sketchup_attributes: att,
            application_id: face.persistent_id
          )
          speckle_mesh.face_to_mesh(face)
          speckle_mesh.update_mesh
          speckle_mesh
        end
        # rubocop:enable Style/MultilineTernaryOperator
        # rubocop:enable Metrics/CyclomaticComplexity

        def face_to_mesh(face)
          mesh = face.loops.count > 1 ? face.mesh : nil
          mesh.nil? ? face_vertices_to_array(face) : mesh_points_to_array(mesh)
          mesh.nil? ? face_indices_to_array(face) : mesh_faces_to_array(mesh)
        end

        # Collects indexed Sketchup vertices into flat array for Speckle use.
        def vertices_to_array(units)
          pts_array = []
          vertices.each do |pt|
            pts_array.push(Geometry.length_to_speckle(pt[0], units),
                           Geometry.length_to_speckle(pt[1], units),
                           Geometry.length_to_speckle(pt[2], units))
          end
          pts_array
        end

        def update_mesh
          # puts "Vertex count on mesh #{vertices.length}"
          self['@(31250)vertices'] = vertices_to_array(units)
          self[:'@(62500)faces'] = polygons
        end

        # Get a flat array of vertices from a list of sketchup vertices
        # @param face [Sketchup::Face] face to get vertices.
        def face_vertices_to_array(face)
          face.vertices.each do |v|
            pt = v.position
            # FIXME: Enable previous line when viewer supports shared vertices
            # vertices.push(pt) unless vertices.any? { |point| point == pt }
            vertices.push(pt)
          end
        end

        # Get a flat array of face indices from a sketchup face
        def face_indices_to_array(face)
          polygons.push(face.vertices.count)
          face.vertices.each do |v|
            pt = v.position
            # FIXME: Enable previous line when viewer supports shared vertices
            # global_vertex_index = vertices.reverse.find_index(pt)
            global_vertex_index = vertices.length - vertices.reverse.find_index(pt) - 1
            polygons.push(global_vertex_index)
          end
        end

        # Get a flat array of vertices from a sketchup polygon mesh
        # @param mesh [Geom::PolygonMesh] mesh to get points.
        def mesh_points_to_array(mesh)
          mesh.points.each do |pt|
            # FIXME: Enable previous line when viewer supports shared vertices
            # vertices.push(pt) unless vertices.any? { |point| point == pt }
            vertices.push(pt)
          end
        end

        # Get an array of face indices from a sketchup polygon mesh
        # @param mesh [Geom::PolygonMesh] mesh to convert into polygons.
        def mesh_faces_to_array(mesh)
          mesh.polygons.each do |poly|
            global_polygon_array = [poly.count]
            poly.each do |index|
              # FIXME: Enable previous line when viewer supports shared vertices
              # global_vertex_index = vertices.reverse.find_index(mesh.points[index.abs - 1])
              global_vertex_index = vertices.length - vertices.reverse.find_index(mesh.points[index.abs - 1]) - 1
              global_polygon_array.push(global_vertex_index)
            end
            polygons.push(*global_polygon_array)
          end
        end

        DEFINITIONS_WILL_BE_HARD_EDGE = %w[
          Walls
          Floors
          Stairs
          Structural Foundations
          Doors
          Windows
        ].freeze

        # @param mesh [Object] speckle mesh object
        # @param entities [Sketchup::Entities] sketchup entities that mesh will be created in it as face.
        def self.get_soften_setting(mesh, entities)
          unless mesh['sketchup_attributes'].nil?
            return mesh['sketchup_attributes']['is_soften'].nil? ? true : mesh['sketchup_attributes']['is_soften']
          end

          return DEFINITIONS_WILL_BE_HARD_EDGE.none? { |def_name| entities.parent.name.include?(def_name) }
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
