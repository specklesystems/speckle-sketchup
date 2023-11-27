# frozen_string_literal: true

# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/PerceivedComplexity

module SpeckleConnector
  module Converters
    # CleanUp is a plugin developed by [Thomas Thomassen](https://github.com/thomthom).
    module CleanUp
      # Removes coplanar entities from the given entities.
      # @param entities [Sketchup::Entities] entities to remove edges between that make entities coplanar.
      # @note Merging coplanar faces idea originated from [CleanUp](https://github.com/thomthom/cleanup) plugin
      # which is developed by [Thomas Thomassen](https://github.com/thomthom).
      def self.merge_coplanar_faces(entities)
        edges = []
        faces = entities.collect { |entity| entity if entity.is_a? Sketchup::Face }.compact
        faces.each { |face| face.edges.each { |edge| edges << edge } }
        edges.uniq!
        edges.each { |edge| remove_edge_have_coplanar_faces(edge, faces, false) }
        # Remove remaining orphan edges
        edges.reject(&:deleted?).select { |edge| edge.faces.empty? }.each(&:erase!)
        merged_faces(faces)
      end

      def self.merged_faces(faces)
        faces.reject(&:deleted?)
      end

      # Detect edges to remove by checking following controls respectively;
      #  - Upcoming Sketchup entity is Sketchup::Edge or not.
      #  - Whether edge has 2 face or not.
      #  - Whether faces are duplicated or not.
      #  - Whether edges safe to merge or not.
      #  - Whether faces have same material or not.
      #  - Whether UV texture map is aligned between faces or not.
      #  - Finally, if faces are coplanar by correcting these checks, then removes edge from Sketchup.active_model.
      # @param edge [Sketchup::Edge] edge to check.
      # @param faces [Array<Sketchup::Face>] scoped faces to check 'edge.faces' both (first and second)
      #  belongs to this faces or not. If any of this faces does not involve this scoped faces, then do not delete.
      # @param ignore_materials [Boolean] whether ignore materials or not.
      # Returns true if the given edge separating two coplanar faces.
      # Return false otherwise.
      def self.remove_edge_have_coplanar_faces(edge, faces, ignore_materials)
        return false unless edge.valid? && edge.is_a?(Sketchup::Edge)
        return false unless edge.faces.size == 2

        face_1, face_2 = edge.faces

        return false unless face_1.normal.samedirection?(face_2.normal)

        return false if face_duplicate?(face_1, face_2)
        # Check for troublesome faces which might lead to missing geometry if merged.
        return false unless edge_safe_to_merge?(edge)

        # Check materials match.
        unless ignore_materials
          return false unless (face_1.material == face_2.material) && (face_1.back_material == face_2.back_material)

          # Verify UV mapping match.
          return false if !face_1.material.nil? && !continuous_uv?(face_1, face_2, edge) && face_1.material.texture.nil?
        end
        # Check faces are coplanar or not.
        return false unless faces_coplanar?(face_1, face_2)

        edge.erase!
        true
      end

      # Determines if two faces are overlapped.
      def self.face_duplicate?(face_1, face_2, overlapping: false)
        return false if face_1 == face_2

        v_1 = face_1.outer_loop.vertices
        v_2 = face_2.outer_loop.vertices
        return true if (v_1 - v_2).empty? && (v_2 - v_1).empty?

        if overlapping && (v_2 - v_1).empty?
          edges = (face_2.outer_loop.edges - face_1.outer_loop.edges)
          unless edges.empty?
            point = edges[0].start.position.offset(edges[0].line[1], 0.01)
            return true if face_1.classify_point(point) <= 4
          end
        end
        false
      end

      # Checks the given edge for potential problems if the connected faces would
      # be merged.
      def self.edge_safe_to_merge?(edge)
        edge.faces.all? { |face| face_safe_to_merge?(face) }
      end

      # Returns true if the two faces connected by the edge has continuous UV mapping.
      # UV's are normalized to 0.0..1.0 before comparison.
      def self.continuous_uv?(face_1, face_2, edge)
        tw = Sketchup.create_texture_writer
        uvh_1 = face_1.get_UVHelper(true, true, tw)
        uvh_2 = face_2.get_UVHelper(true, true, tw)
        p_1 = edge.start.position
        p_2 = edge.end.position
        uv_equal?(uvh_1.get_front_UVQ(p_1), uvh_2.get_front_UVQ(p_1)) &&
          uv_equal?(uvh_1.get_front_UVQ(p_2), uvh_2.get_front_UVQ(p_2)) &&
          uv_equal?(uvh_1.get_back_UVQ(p_1), uvh_2.get_back_UVQ(p_1)) &&
          uv_equal?(uvh_1.get_back_UVQ(p_2), uvh_2.get_back_UVQ(p_2))
      end

      # Normalize UV's to 0.0..1.0 and compare them.
      def self.uv_equal?(uvq_1, uvq_2)
        uv_1 = uvq_1.to_a.map { |n| n % 1 }
        uv_2 = uvq_2.to_a.map { |n| n % 1 }
        uv_1 == uv_2
      end

      # Validates that the given face can be merged with other faces without causing
      # problems.
      def self.face_safe_to_merge?(face)
        stack = face.outer_loop.edges
        edge = stack.shift
        direction = edge.line[1]
        until stack.empty?
          edge = stack.shift
          return true unless edge.line[1].parallel?(direction)
        end
        false
      end

      # Determines if two faces are coplanar.
      def self.faces_coplanar?(face_1, face_2)
        vertices = face_1.vertices + face_2.vertices
        plane = Geom.fit_plane_to_points(vertices)
        vertices.all? { |v| v.position.on_plane?(plane) }
      end
    end
  end
end

# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/PerceivedComplexity
