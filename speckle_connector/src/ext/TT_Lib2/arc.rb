#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require_relative 'core.rb'

# Collection of Arc methods.
#
# @since 2.0.0
module SpeckleConnector
  module TT::Arc

    # Checks if a given +Curve+ is an +ArcCurve+ and not a polygon.
    #
    # Check for polygon requires SketchUp 7.1M1 or newer. Older SketchUp
    # versions will not check for this property.
    #
    # @param [Sketchup::Curve] curve
    # @since 2.0.0
    def self.is?( curve )
      return false if curve.respond_to?( :is_polygon? ) && curve.is_polygon?
      curve.is_a?(Sketchup::ArcCurve)
    end

    # Checks if a given +Curve+ makes an circle and is not a polygon.
    #
    # Check for polygon requires SketchUp 7.1M1 or newer. Older SketchUp
    # versions will not check for this property.
    #
    # SketchUp has a bug where an ArcCurve some times has 720 degrees angle
    # instead of 360. This method handles this.
    #
    # @param [Sketchup::Curve] curve
    # @since 2.0.0
    def self.circle?( curve )
      return false unless self.is?( curve )
      return ((curve.end_angle - curve.start_angle).radians >= 360) ? true : false
    end

    # Based on Chris Fullmers "Exploded Arc Centerpoint Finder".
    # Calculates the centre points of an arc given two edges.
    #
    # @param [Sketchup::Edge] e1
    # @param [Sketchup::Edge] e2
    #
    # @return [Geom::Point3d, nil]
    # @since 2.0.0
    def self.exploded_center(e1, e2)
      # Two edges representing an arc must have the same length and can not
      # be parallel.
      return nil if e1.length != e2.length
      v1 = e1.line[1]
      v2 = e2.line[1]
      return nil if v1.parallel?( v2 )
      # Get mid-point of edges from where intersecting lines will origin.
      m1 = Geom.linear_combination( 0.5, e1.start.position, 0.5, e1.end.position )
      m2 = Geom.linear_combination( 0.5, e2.start.position, 0.5, e2.end.position )
      # Get the vectors for the intersecting lines
      z_axis = v1 * v2
      line1 = [m1, v1 * z_axis]
      line2 = [m2, v2 * z_axis]
      # Return the center
      Geom.intersect_line_line(line1, line2)
    end

  end # module TT::Arc
end
