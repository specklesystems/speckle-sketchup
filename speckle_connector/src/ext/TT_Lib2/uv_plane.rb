#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require_relative 'core.rb'

module SpeckleConnector
  # Helper class for planar UV mapping.
  #
  # Map induvidual faces:
  #  model = Sketchup.active_model
  #  face = model.entities.find { |e| e.is_a?( Sketchup::Face ) }
  #  uv_plane = TT::UV_Plane.new( ORIGIN, Z_AXIS.reverse, model.materials.current )
  #  uv_plane.project( face, true )
  #
  # Map faces in entity or array collection:
  #  model = Sketchup.active_model
  #  uv_plane = TT::UV_Plane.new( ORIGIN, Z_AXIS.reverse, model.materials.current )
  #  uv_plane.project_to_entities( model.entities, true )
  #
  # @since 2.5.0
  class TT::UV_Plane

    attr_reader(:origin, :normal, :xaxis, :width, :height)
    attr_accessor(:material)


    # Creates a new UV Plane.
    #
    # @param [Geom::Point3d] origin
    # @param [Geom::Vector3d] normal
    # @param [Sketchup::Material] material
    #
    # @since 2.5.0
    def initialize(origin, normal, material = nil)
      @material = material
      if @material.nil? || @material.texture.nil?
        @width  = 10
        @height = 10
      else
        @width  = @material.texture.width
        @height = @material.texture.height
      end

      @origin = origin.clone
      @normal = normal.clone
      @plane = [@origin, @normal]

      @xaxis = @normal.axes.x

      update()
    end


    # Returns an array representing the UV plane.
    #
    # @return [Array<Geom::Point3d,Geom::Vector3d>]
    # @since 2.4.0
    def to_a
      return [origin, normal]
    end


    # Sets the origin of where on the plane the UV mapping should start.
    #
    # @param [Geom::Point3d] point
    #
    # @return [Geom::Point3d]
    # @since 2.4.0
    def origin=(point)
      @origin = point
      update()
      @origin.dup
    end


    # Returns the center point of the first UV tile.
    #
    # @return [Geom::Point3d]
    # @since 2.5.0
    def center
      x = @xaxis
      y = yaxis()
      pt = @origin.offset( x, @width / 2.0 )
      pt.offset!( y, @height / 2.0 )
      pt
    end


    # Centers the UV Plane around +point+.
    #
    # @param [Geom::Point3d] point
    #
    # @return [Geom::Point3d]
    # @since 2.5.0
    def center=(point)
      x = @xaxis
      y = yaxis()
      pt = point.offset( x.reverse, @width / 2.0 )
      pt.offset!( y.reverse, @height / 2.0 )
      @origin = pt
      update()
      @origin.dup
    end


    # Sets the normal of the UV plane.
    #
    # @param [Geom::Vector3d] vector
    #
    # @return [Geom::Vector3d]
    # @since 2.4.0
    def normal=(vector)
      @normal = vector
      @xaxis = @normal.axes.x
      update()
      @normal.dup
    end


    # Sets the orientation of the UV mapping on the UV plane. If +vector+ is +nil+
    # the xaxis is determined by SketchUp.
    #
    # @param [Geom::Vector3d] vector
    #
    # @return [Geom::Vector3d]
    # @since 2.5.0
    def xaxis=(vector=nil)
      @xaxis = (vector.nil?) ? @normal.axes.x : vector
      update()
      @xaxis.dup
    end


    # Sets the normal of the UV plane.
    #
    # @param [Length] length
    #
    # @return [Length]
    # @since 2.5.0
    def width=(length)
      @width = length
      update()
      @width.dup
    end


    # Sets the normal of the UV plane.
    #
    # @param [Length] length
    #
    # @return [Length]
    # @since 2.5.0
    def height=(length)
      @height = length
      update()
      @height.dup
    end


    # Projects a texture material from the UV plane onto the face. Material will
    # applied even if it's not a textured material.
    #
    # @param [Sketchup::Face] face
    # @param [Boolean] on_front
    # @param [Boolean] on_back
    #
    # @return [Boolean] +true+ if material had a texture
    # @since 2.4.0
    def project(face, on_front=true, on_back=false)
      # Special case for untextured materials
      if @material.nil? || @material.materialType == 0
        face.material = @material if on_front
        face.back_material = @material if on_back
        return false
      end

      # The UV mapping co-ords to feed position_material.
      uv_points = []

      # Can't rely on the vertex positions, since a face might have only tree
      # and four sets are required to correctly map a distorted texture.
      # And the point can't be co-linear either.
      #
      # Instead, generate four points on the plane of the target face.
      # 3  4
      #
      # 1  2
      pts = []
      pts << face.vertices.first.position               # 1
      pts << pts.first.offset( face.normal.axes.x, 10 ) # 2
      pts << pts.first.offset( face.normal.axes.y, 10 ) # 3
      pts << pts.last.offset(  face.normal.axes.x, 10 ) # 4

      # Now project each of the point to the UV plane in order to obtain
      # the UV coordinates relative to the UV origin.
      pts.each { |p1|
        # Get UV coordinates.
        p2 = p1.project_to_plane(@plane)
        uv = get_UV( p2 )
        # Add the points to the pool.
        uv_points << p1
        uv_points << uv
      }
      face.position_material( @material, uv_points, on_front )
      face.position_material( @material, uv_points, !on_back )
      true
    end


    # Projects a texture material from the UV plane onto the faces in the given
    # collection of entities.
    #
    # @param [Sketchup::Entities,Sketchup::Selection,Array<Sketchup::Entity>] entities
    # @param [Boolean] on_front
    # @param [Boolean] on_back
    #
    # @return [Nil]
    # @since 2.4.0
    def project_to_entities(entities, on_front=true, on_back=false)
      for e in entities
        next unless e.is_a?(Sketchup::Face)
        project( e, on_front )
      end
      nil
    end


    # Calculates the UV coordinates for the given 3d point. The point should be on
    # the UV plane.
    #
    # Ref:
    # http://mathforum.org/library/drmath/view/51727.html
    #
    # Thanks to Chris Thomson for the SU solution.
    # http://forums.sketchucation.com/viewtopic.php?f=180&t=28484&p=247275#p247271
    #
    # @param [Geom::Point3d] point3d
    #
    # @return [Geom::Point3d]
    # @since 2.4.0
    def get_UV( point3d )
      point2d = point3d.transform(@to_local)
      u = point2d.x / @width
      v = point2d.y / @height
      return [u, v, 1.0]
    end


    # Returns an array of Point3d objects representing the segment boundary of one
    # UV tile. Can be used for +pick_helper.pick_segment+.
    #
    # @return [Array<Geom::Point3d>]
    # @since 2.5.0
    def frame_segments
      y = yaxis()
      pts = []
      pts << @origin
      pts << pts.last.offset( @xaxis, @width )
      pts << pts.last.offset( y, @height )
      pts << pts.first.offset( y, @height )
      pts << pts.first
      pts
    end

    private

    # Updates the cached transformation for the UV Plane. Called when the
    # orientation or position of the plane changes.
    #
    # @return [Geom::Transformation]
    # @since 2.4.0
    def update
      x = @xaxis
      y = yaxis()
      @to_local = Geom::Transformation.axes(@origin, x, y, @normal).inverse
    end


    # @return [Geom::Vector3d]
    # @since 2.5.0
    def yaxis
      @normal * @xaxis
    end

  end # module TT::UV_Plane
end
