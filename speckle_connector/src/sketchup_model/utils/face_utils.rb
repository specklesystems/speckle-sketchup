# frozen_string_literal: true

require_relative '../../constants/geo_constants'

module SpeckleConnector
  # Operations related to {SketchupModel}.
  module SketchupModel
    # Works directly with/on SketchUp Entities of different kinds (Groups, Faces, Edges, ...).
    module Utils
      # Static methods that work directly with Sketchup::Face objects
      class FaceUtils
        # A method that calculates the faces that are less than n-faces
        # away from the current face. For n=1, you would get the
        # neighbouring faces.
        # @param edge_ary [Array<Sketchup::Edge>] the edges to look for n-adjacent faces
        # @param n_adjacent [Integer] the distance from the edges (in number of faces)
        # @return [Array<Sketchup::Face>] the faces that are n faces away from the given edges
        def self.near_faces(edges_ary, n_adjacent = 1)
          # get all the faces that are not more than a face away to the current face.
          edges_ary = edges_ary.select(&:valid?)
          adj_faces = []
          n_adjacent.times do |_i|
            new_faces = edges_ary.collect(&:faces).flatten.uniq
            adj_faces += new_faces
            edges_ary = new_faces.collect(&:edges).flatten.uniq - edges_ary
          end
          adj_faces.uniq
        end

        # @param face [Sketchup::Face] face to check whether is vertical or not.
        def self.vertical?(face)
          face.normal.perpendicular?(VECTOR_Z)
        end

        # @param face [Sketchup::Face] face to check whether is horizontal or not.
        def self.horizontal?(face)
          face.normal.parallel?(VECTOR_Z)
        end
      end
    end
  end
end
