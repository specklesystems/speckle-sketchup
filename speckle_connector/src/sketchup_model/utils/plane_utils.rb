# frozen_string_literal: true

module SpeckleConnector
  # Operations related to {SketchupModel}.
  module SketchupModel
    # Works directly with/on SketchUp Entities of different kinds (Groups, Faces, Edges, ...).
    module Utils
      # Static methods to do plane calculations with sketchup geom objects like Point3d and Vector3d.
      class Plane
        LENGTH_TOLERANCE = 1e-8

        # Create plane from 3 points
        # @param origin [Geom::Point3d] the point on the plane that wil become the origin of the local coordinate system
        # @param point_1 [Geom::Point3d] the point that defines first direction
        # @param point_2 [Geom::Point3d] the third point on the plane
        # @return [Plane] the parametrization of the plane that goes through the given points
        def self.from_points(origin, point_1, point_2)
          direction_x = origin.vector_to(point_1).normalize
          direction_x = direction_x.normalize
          normal = direction_x.cross(origin.vector_to(point_2))
          direction_y = direction_x.cross(normal.normalize)
          new(origin: origin, direction_u: direction_x, direction_v: direction_y)
        end

        # @return [Geom::Vector3d] the direction of the u-axis on the plane
        attr_reader :direction_u

        # @return [Geom::Vector3d] the direction of the v-axis on the plane
        attr_reader :direction_v

        # @return [Geom::Point3d] the origin of the local coordinate system on the plane
        attr_reader :origin

        # @param origin [Geom::Point3d] the origin of the coordinate system on the plane
        # @param direction_u [Geom::Vector3d] the direction of the x-axis
        # @param direction_v [Geom::Vector3d] the direction of the y-axis
        def initialize(origin:, direction_u:, direction_v:)
          @origin = origin
          @direction_u = direction_u
          @direction_v = direction_v
        end

        # Get the point object in global coordinates for the point on the plane with local coordinates (u,v).
        # @param coordinate_u [Float] the u-coordinate on the plane
        # @param coordinate_v [Float] the v-coordinate on the plane
        # @return [Geom::Point3d] the point in space that corresponds to the given (u, v) coordinates
        def point_at(coordinate_u, coordinate_v)
          scaled_direction_u = Geom::Vector3d.new(direction_u.x * coordinate_u,
                                                  direction_u.y * coordinate_u,
                                                  direction_u.z * coordinate_u)
          scaled_direction_v = Geom::Vector3d.new(direction_v.x * coordinate_v,
                                                  direction_v.y * coordinate_v,
                                                  direction_v.z * coordinate_v)
          origin + scaled_direction_u + scaled_direction_v
        end

        # Find local (u, v) coordinates of the projection of the given point to the plane
        # @param point [Geom::Point3d] the point that will be projected to the plane
        # @return [(Float, Float)] the local coordinates on the plane that correspond to the projected point
        def plane_coordinates(point)
          origin_to_point = origin.vector_to(point)
          coordinate_u = origin_to_point.dot(direction_u)
          coordinate_v = origin_to_point.dot(direction_v)
          [coordinate_u, coordinate_v]
        end

        # Project a given point to the plane
        # @param point [Geom::Point3d] the point that will be projected to the plane
        # @return [Geom::Point3d] the projected point on the plane
        def project_to_plane(point)
          coordinate_u, coordinate_v = plane_coordinates(point)
          point_at(coordinate_u, coordinate_v)
        end

        # Check if the given point lies on the plane
        # @param point [Geom::Point3d] the point to check
        # @return [Boolean] whether the point lies on the plane
        def on_plane?(point)
          point.distance(project_to_plane(point)).to_m < LENGTH_TOLERANCE
        end
      end
    end
  end
end
