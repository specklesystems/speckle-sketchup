# frozen_string_literal: true

require_relative '../base'
require_relative '../geometry/bounding_box'
require_relative '../other/render_material'
require_relative '../../mapper/mapper'
require_relative '../../sketchup_model/query/entity'
require_relative '../../convertors/clean_up'
require_relative '../../sketchup_model/dictionary/base_dictionary_handler'
require_relative '../../sketchup_model/dictionary/speckle_schema_dictionary_handler'
require_relative '../../sketchup_model/dictionary/dictionary_handler'
require_relative '../../sketchup_model/utils/plane_utils'
require_relative '../../sketchup_model/query/layer'

module SpeckleConnector3
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
        # @param vertices [Array] vertices of the speckle mesh.
        # @param faces [Array] faces of the speckle mesh.
        # @param sketchup_attributes [Hash] additional information about speckle mesh.
        # rubocop:disable Metrics/ParameterLists
        def initialize(units:, vertices:, faces:,
                       sketchup_attributes:, layer:, speckle_schema: {}, application_id: nil)
          super(
            speckle_type: SPECKLE_TYPE,
            application_id: application_id,
            id: nil
          )
          @vertices = []
          @polygons = []
          @units = units
          self[:units] = units
          self[:layer] = layer
          # self[:renderMaterial] = render_material
          self[:'@(31250)vertices'] = vertices
          self[:'@(62500)faces'] = faces
          self[:sketchup_attributes] = sketchup_attributes if sketchup_attributes.any?
          self['@SpeckleSchema'] = speckle_schema if speckle_schema.any?
        end
        # rubocop:enable Metrics/ParameterLists

        # Checks 4 points are planar or not.
        def self.check_4_points_planar(points)
          plane = SketchupModel::Utils::Plane.from_points(points[0], points[1], points[2])
          plane.on_plane?(points[3])
        end

        # Add quad mesh to sketchup native mesh by checking planarity.
        # @param native_mesh [Geom::Mesh] sketchup mesh to convert them later faces.
        # @param polygon_points [Array<Geom::Point3d>] sketchup points to add them with polygon to mesh.
        def self.add_quad_mesh(native_mesh, polygon_points)
          is_planar = check_4_points_planar(polygon_points)
          if is_planar
            native_mesh.add_polygon(polygon_points)
          else
            native_mesh.add_polygon([polygon_points[0], polygon_points[1], polygon_points[2]])
            native_mesh.add_polygon([polygon_points[0], polygon_points[2], polygon_points[3]])
          end
          is_planar
        end

        # @param entities [Sketchup::Entities] entities to add
        # rubocop:disable Metrics/MethodLength
        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Metrics/CyclomaticComplexity
        # rubocop:disable Metrics/PerceivedComplexity:
        def self.to_native(state, mesh, layer, entities, &convert_to_native)
          # model_preferences = state.user_state.preferences[:model]
          # Get soft? flag of {Sketchup::Edge} object to understand smoothness of edge.
          is_soften = get_soften_setting(mesh, entities)
          smooth_flags = is_soften ? 4 : 1
          # Get native points to add polygon into native mesh.
          points = get_native_points(mesh)
          # Initialize native PolygonMesh object later to add polygon inside it.
          native_mesh = Geom::PolygonMesh.new(mesh['vertices'].count / 3)
          faces = mesh['faces']
          has_any_non_planar_quad_mesh = false
          while faces.count > 0
            num_pts = faces.shift
            # 0 -> 3, 1 -> 4 to preserve backwards compatibility
            num_pts += 3 if num_pts < 3
            indices = faces.shift(num_pts)
            polygon_points = indices.map { |index| points[index] }
            # Quad mesh
            if num_pts == 4
              is_planar = add_quad_mesh(native_mesh, polygon_points)
              has_any_non_planar_quad_mesh = true unless is_planar
            else
              native_mesh.add_polygon(polygon_points)
            end
          end
          state, _materials = Other::RenderMaterial.to_native(state, mesh['renderMaterial'], layer,
                                                              entities, &convert_to_native)
          # Find and assign material if exist
          unless mesh['renderMaterial'].nil?
            material_name = mesh['renderMaterial']['name'] || mesh['renderMaterial']['id'] ||
                            mesh['renderMaterial']['diffuse'].to_s
            # Retrieve material from state
            material = state.sketchup_state.materials.by_id(material_name)
          end

          # Add faces from mesh with material and smooth setting
          entities.add_faces_from_mesh(native_mesh, smooth_flags, material, material)
          added_faces = entities.grep(Sketchup::Face).last(native_mesh.polygons.length)
          mesh_layer_name = SketchupModel::Query::Layer.entity_layer_from_path(mesh['layer'])
          mesh_layer = state.sketchup_state.sketchup_model.layers.to_a.find { |l| l.display_name == mesh_layer_name }
          # Merge only added faces in this scope
          # if model_preferences[:merge_coplanar_faces]
          #   added_faces = Converters::CleanUp.merge_coplanar_faces(added_faces)
          # end
          added_faces.each do |face|
            face.layer = mesh_layer unless mesh_layer.nil?
            # Smooth edges if they already soft
            # FIXME: Below line should be reconsidered. It might be a good to know here mesh comes from NURBS or not.
            face.edges.each { |edge| edge.smooth = true if edge.soft? } if has_any_non_planar_quad_mesh
            unless mesh['sketchup_attributes'].nil?
              SketchupModel::Dictionary::BaseDictionaryHandler
                .attribute_dictionaries_to_native(face, mesh['sketchup_attributes']['dictionaries'])
            end
          end

          return state, added_faces
        end
        # rubocop:enable Metrics/MethodLength
        # rubocop:enable Metrics/AbcSize
        # rubocop:enable Metrics/CyclomaticComplexity
        # rubocop:enable Metrics/PerceivedComplexity:

        # @param face [Sketchup::Face] face to convert mesh
        # @param units [String] model units to send Speckle.
        # @param model_preferences [Hash{Symbol=>Boolean}] model preferences to check include attributes or not.
        # @param global_transform [Geom::Transformation, nil] global transformation value of face if it is not included
        #  into any component.
        # rubocop:disable Style/MultilineTernaryOperator
        # rubocop:disable Metrics/ParameterLists
        def self.from_face(speckle_state:, face:, units:, model_preferences:, global_transform: nil, parent_material: nil)
          dictionaries = SketchupModel::Dictionary::BaseDictionaryHandler
                         .attribute_dictionaries_to_speckle(face, model_preferences)
          has_any_soften_edge = face.edges.any?(&:soft?)
          att = dictionaries.any? ? { is_soften: has_any_soften_edge, dictionaries: dictionaries }
                  : { is_soften: has_any_soften_edge }
          speckle_schema = Mapper.to_speckle(speckle_state, face, units, global_transformation: global_transform)
          material = face.material || face.back_material || parent_material
          speckle_mesh = Mesh.new(
            units: units,
            # render_material: material.nil? ? nil : Other::RenderMaterial.from_material(material),
            vertices: [], faces: [], sketchup_attributes: att,
            layer: SketchupModel::Query::Layer.entity_path(face),
            speckle_schema: speckle_schema,
            application_id: face.persistent_id.to_s
          )
          speckle_mesh.face_to_mesh(face, global_transform)
          speckle_mesh.update_mesh
          speckle_mesh
        end
        # rubocop:enable Style/MultilineTernaryOperator

        # Create single mesh from multiple faces.
        # This function takes the material of the first face in the list.
        def self.from_faces(speckle_state:, faces:, units:, model_preferences:,
                            global_transform: nil, parent_material: nil)
          mesh = from_face(speckle_state: speckle_state, face: faces.first, units: units,
                           model_preferences: model_preferences, global_transform: global_transform,
                           parent_material: parent_material)
          faces[1..-1].each { |f| mesh.face_to_mesh(f, global_transform) }
          mesh.update_mesh
          mesh
        end
        # rubocop:enable Metrics/ParameterLists

        # @param global_transform [Geom::Transformation, nil] global transformation value of face if it is not included
        #  into any component. So it's mesh will be transformed into global coordinates to represent it correctly in
        #  Speckle viewer or other connectors.
        def face_to_mesh(face, global_transform = nil)
          mesh = face.loops.count > 1 ? face.mesh : nil
          if global_transform.nil?
            mesh.nil? ? face_vertices_to_array(face) : mesh_points_to_array(mesh)
            mesh.nil? ? face_indices_to_array(face) : mesh_faces_to_array(mesh)
          else
            mesh_points_to_array(face.mesh, global_transform)
            mesh_faces_to_array(face.mesh, global_transform)
          end
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
        def mesh_points_to_array(mesh, global_transform = nil)
          mesh.transform!(global_transform) unless global_transform.nil?
          mesh.points.each do |pt|
            # FIXME: Enable previous line when viewer supports shared vertices
            # vertices.push(pt) unless vertices.any? { |point| point == pt }
            vertices.push(pt)
          end
        end

        # Get an array of face indices from a sketchup polygon mesh
        # @param mesh [Geom::PolygonMesh] mesh to convert into polygons.
        def mesh_faces_to_array(mesh, global_transform = nil)
          mesh.transform!(global_transform) unless global_transform.nil?
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

        # Mesh group id helps to determine how to group faces into meshes.
        # @param face [Sketchup::Face] face to get mesh group id.
        def self.get_mesh_group_id(face, model_preferences, parent_material = nil)
          if model_preferences[:include_entity_attributes] &&
             model_preferences[:include_face_entity_attributes] &&
             attribute_dictionary?(face)
            return face.persistent_id.to_s
          end

          material = face.material || face.back_material || parent_material
          layer_name = face.layer.display_name
          return layer_name if material.nil?

          return material.persistent_id.to_s + layer_name
        end

        def self.attribute_dictionary?(face)
          any_attribute_dictionary = !(face.attribute_dictionaries.nil? || face.attribute_dictionaries.first.nil?)
          return any_attribute_dictionary unless any_attribute_dictionary

          # If there are any attribute dictionary, then make sure that they are not ignored ones.
          all_attribute_dictionary_ignored = face.attribute_dictionaries.all? do |dict|
            ignored_dictionaries.include?(dict.name)
          end
          !all_attribute_dictionary_ignored
        end

        def self.ignored_dictionaries
          [
            'Speckle_Base_Object'
          ]
        end
      end
    end
  end
end
