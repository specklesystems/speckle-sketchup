#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require_relative 'core.rb'
require_relative 'point3d.rb'
require_relative 'progressbar.rb'

# Collection of Edge methods.
#
# @since 2.5.0
module SpeckleConnector
  module TT::Edge

    # @param [Array<Geom::Point3d, Geom::Vector3d>, Array<Geom::Point3d, Geom::Point3d>] line
    # @param [Sketchup::Edge] edge
    #
    # @return [Geom::Point3d|Nil]
    # @since 2.5.0
    def self.intersect_line_edge(line, edge)
      point = Geom.intersect_line_line(line, edge.line)
      return nil if point.nil?
      return point if self.point_on_edge?(point, edge)
      return nil
    end


    # @param [Geom::Point3d] point
    # @param [Sketchup::Edge] edge
    #
    # @return [Boolean]
    # @since 2.5.0
    def self.point_on_edge?(point, edge)
      a = edge.start.position
      b = edge.end.position
      TT::Point3d.between?(a, b, point, true)
    end

  end # module TT::Edge


  # Collection of methods to manipulate sets of edges.
  #
  # @since 2.5.0
  module TT::Edges

    # @param [Sketchup::Edge] edge1
    # @param [Sketchup::Edge] edge2
    #
    # @return [Sketchup::Vertex|Nil]
    # @since 2.5.0
    def self.common_vertex(edge1, edge2)
      for v1 in edge1.vertices
        for v2 in edge2.vertices
          return v1 if v1 == v2
        end
      end
      nil
    end


    # Find continous sets of edges not part of faces. The result is an array of
    # more arrays. Each sub-array contains a set of sorted edges.
    #
    # Sub-arrays may contains arrays of only one edge.
    #
    # @param [Array<Sketchup::Entity>] entities
    #
    # @return [Array<Array<Sketchup::Edge>>] An +Array+ of Arrays.
    # @since 2.5.0
    def self.find_curves( entities, progress_in_ui=false )
      cache = {} # Use Hash for quick lookups
      entities.each { |e|
        next unless e.is_a?( Sketchup::Edge ) && e.faces.empty?
        cache[e] = e
      }
      if progress_in_ui && progress_in_ui.is_a?( TT::Progressbar )
        progress = progress_in_ui
      else
        progress = TT::Progressbar.new( cache, 'Finding curves' )
      end
      curves = []
      until cache.empty?
        curve = {} # Use Hash for quick lookups
        stack = [ cache.keys.first ]
        until stack.empty?
          # Fetch the next edges in the stack and add to the curve
          edge = stack.shift
          curve[edge] = edge
          cache.delete(edge)
          progress.next if progress_in_ui
          # Find next edges
          for v in edge.vertices
            vert_edges = v.edges
            next if vert_edges.size != 2
            for e in vert_edges
              stack << e unless curve.key?(e)
            end
          end
        end # until stack.empty?
        curves << self.sort( curve )
      end # until cache.empty?
      curves
    end


    # Finds all sets of edges forming a curve not connected to any other geometry.
    # Returns an array of sorted curves. (Curve = array of edges)
    #
    # @param [Array<Sketchup::Entity>] entities
    #
    # @return [Array<Array<Sketchup::Edge>>] An +Array+ of Arrays.
    # @since 2.5.0
    def self.find_isolated_curves(entities)
      source = entities.to_a
      curves = []
      until source.empty?
        entity = source.shift
        next unless entity.is_a?( Sketchup::Edge )
        connected = entity.all_connected
        source -= connected
        next unless connected.all? { |e| e.is_a?(Sketchup::Edge) }
        sorted_edges = self.sort( connected )
        curves << sorted_edges unless sorted_edges.nil?
      end
      return curves
    end


    # Attempts to merge colinear edges into one edge. Makes use of SketchUp's own
    # healing feature.
    # Based on repair_broken_lines.rb by Carlo Roosen 2004
    #
    # If +progress_in_ui+ is true then a +TT::Progressbar+ object is used to
    # give UI feedback to the user about the process.
    #
    # If +progress_in_ui+ is a +TT::Progressbar+ object then that is used instead
    # and +.next+ is called for each entity.
    #
    # @param [Array<Sketchup::Entity>] entities
    # @param [Boolean|TT::Progressbar] progress_in_ui
    #
    # @return [Integer] Number of splits repaired.
    # @since 2.5.0
    def self.repair_splits( entities, progress_in_ui=false )
      temp_edges = []
      return 0 if entities.length == 0

      parent = entities[0].parent.entities

      if progress_in_ui && progress_in_ui.is_a?( TT::Progressbar )
        progress = progress_in_ui
      else
        progress = TT::Progressbar.new( entities, 'Repairing split edges' )
      end
      for e in entities.to_a
        next unless e.is_a?(Sketchup::Edge)

        progress.next if progress_in_ui

        for vertex in e.vertices
          next unless vertex.edges.length == 2
          # (?) Like coplanar faces - can one compare vectors like this? Or do one
          # have to check if all vertices lie on the same line?
          v1 = vertex.edges[0].line[1]
          v2 = vertex.edges[1].line[1]
          next unless v1.parallel?(v2)
          # To repair a broken edge a temporary edge is placed at their shared vertex.
          # This temporary edge is then later erased which causes the two edges to
          # merge.
          pt1 = vertex.position
          pt2 = pt1.clone
          pt2.x += rand(1000) / 100.0
          pt2.y += rand(1000) / 100.0
          pt2.z += rand(1000) / 100.0
          temp_edge = parent.add_line( pt1, pt2 )
          temp_edges << temp_edge unless temp_edge.nil?
        end
      end

      parent.erase_entities(temp_edges) unless temp_edges.empty?

      temp_edges.size
    end


    # Sorts the given set of edges from start to end. If the edges form a loop
    # an arbitrary start is picked.
    #
    # @todo Comment source
    #
    # @param [Array<Sketchup::Edge>] edges
    #
    # @return [Array<Sketchup::Edge>] Sorted set of edges.
    # @since 2.5.0
    def self.sort( edges )
      if edges.is_a?( Hash )
        self.sort_from_hash( edges )
      elsif edges.is_a?( Enumerable )
        lookup = {}
        for edge in edges
          lookup[edge] = edge
        end
        self.sort_from_hash( lookup )
      else
        raise ArgumentError, '"edges" argument must be a collection of edges.'
      end
    end


    # Sorts the given set of edges from start to end. If the edges form a loop
    # an arbitrary start is picked.
    #
    # @param [Hash] edges Sketchup::Edge as keys
    #
    # @return [Array<Sketchup::Edge>] Sorted set of edges.
    # @since 2.5.0
    def self.sort_from_hash( edges )
      # Get starting edge - then trace the connected edges from either end.
      start_edge = edges.keys.first

      # Find the next left and right edge
      vertices = start_edge.vertices

      left = []
      for e in vertices.first.edges
        left << e if e != start_edge && edges[e]
      end

      right = []
      for e in vertices.last.edges
        right << e if e != start_edge && edges[e]
      end

      return nil if left.size > 1 || right.size > 1 # Check for forks
      left = left.first
      right = right.first

      # Sort edges from start to end
      sorted = [start_edge]

      # Right
      edge = right
      until edge.nil?
        sorted << edge
        connected = []
        for v in edge.vertices
          for e in v.edges
            connected << e if edges[e] && !sorted.include?(e)
          end
        end
        return nil if connected.size > 1 # Check for forks
        edge = connected.first
      end

      # Left
      unless sorted.include?( left ) # Fix: 2.6.0
        edge = left
        until edge.nil?
          sorted.unshift( edge )
          connected = []
          for v in edge.vertices
            for e in v.edges
              connected << e if edges[e] && !sorted.include?(e)
            end
          end
          return nil if connected.size > 1 # Check for forks
          edge = connected.first
        end
      end

      sorted
    end


    # @note The first vertex will also appear last if the curve forms a loop.
    #
    # Takes a sorted set of edges and returns a sorted set of vertices. Use
    # +TT::Edges.sort+ to sort a set of edges.
    #
    # @param [Array<Sketchup::Edge>] curve Set of sorted edge.
    #
    # @return [Array<Sketchup::Vertex>] Sorted set of vertices.
    # @since 2.5.0
    def self.sort_vertices(curve)
      return curve[0].vertices if curve.size <= 1
      vertices = []
      # Find the first vertex.
      common = self.common_vertex( curve[0], curve[1] ) # (?) Errorcheck?
      vertices << curve[0].other_vertex( common )
      # Now the rest can be added.
      curve.each { |edge|
        vertices << edge.other_vertex(vertices.last) # (?) Errorcheck?
      }
      return vertices
    end

  end # module TT::Edges


  # Collection of methods to find and repair small gaps and stray edges.
  #
  # @since 2.5.0
  module TT::Edges::Gaps

    # Pair with the results of +TT::Edges::Gaps.find+.
    #
    # @param [Sketchup::Entities] entities +Entities+ collection where the vertex belong to.
    # @param [Sketchup::Vertex] vertex
    # @param [Hash] result The returned hash from +TT::Edges::Gaps.find+.
    # @param [Length] epsilon The max distance for which the gap can be closed.
    #
    # @return [Boolean] Returns +true+ if the gap was closed.
    # @since 2.5.0
    def self.close( entities, vertex, result, epsilon )
      # 1. Closest projected open end
      data = result[:vertex_projected]
      if data[:dist] && data[:dist][0] + data[:dist][1] < epsilon
        pt1 = data[:point]
        pt2 = data[:point2]
        entities.add_line( vertex.position, pt1 )
        entities.add_line( pt1, pt2 )
        return true
      end
      # 2. Closest edge
      data = result[:edge]
      if data[:dist] && data[:dist] < epsilon
        entities.add_line( vertex.position, data[:point] )
        return true
      end
      # 3. Closest open vertex
      data = result[:vertex]
      if data[:dist] && data[:dist] < epsilon
        entities.add_line( vertex.position, data[:point] )
        return true
      end
      false
    end


    # Tries to connect all open ended edges to other edges if the distance is less
    # than +epsilon+. If an open-ended edge can't be connected it'll erase it if
    # its length is less than +epsilon+.
    #
    # If +progress_in_ui+ is true then a +TT::Progressbar+ object is used to
    # give UI feedback to the user about the process.
    #
    # If +progress_in_ui+ is a +TT::Progressbar+ object then that is used instead
    # and +.next+ is called for each entity.
    #
    # @param [Sketchup::Entities|Array<Sketchup::Entity>] entities Entities to process.
    # @param [Length] epsilon The max distance for which the gap can be closed.
    # @param [Boolean] erase_small_edges If +true+ it will erase all stray edges shorter than +epsilon+.
    # @param [Boolean|TT::Progressbar] progress_in_ui
    #
    # @return [Integer] Returns the number of fixes done.
    # @since 2.5.0
    def self.close_all( entities, epsilon, erase_small_edges=false, progress_in_ui=false )
      fixes = 0
      return fixes if entities.length == 0
      context = entities[0].parent.entities
      edges = entities.select { |e| e.is_a?( Sketchup::Edge ) }
      small_edges = []
      end_vertices = self.find_end_vertices( edges )
      if progress_in_ui && progress_in_ui.is_a?( TT::Progressbar )
        progress = progress_in_ui
      else
        progress = TT::Progressbar.new( end_vertices, 'Closing open ends' )
      end
      for v in end_vertices
        progress.next if progress_in_ui
        result = self.find(v, end_vertices, edges)
        closed = self.close( context, v, result, epsilon )
        fixes += 1 if closed
        if !closed && erase_small_edges
          edge = v.edges.first
          if edge.length < epsilon
            small_edges << edge
            fixes += 1
          end
        end
      end # for
      Sketchup.status_text  = 'Erasing small edges...' if progress_in_ui
      if erase_small_edges && !small_edges.empty?
        context.erase_entities( small_edges )
      end
      fixes
    end


    # Finds possible connections for +vertex+ within the set of +open_ends+ and
    # +edges+.
    #
    # The returned hash contains three keys:
    # * +:vertex_projected+ - the closest connection by extending two edges towards each other.
    # * +:vertex+ - the closest open-end vertex
    # * +:edge+ - the closest edge
    #
    # Each value contains another hash with the following keys:
    # * +:dist+ the distance from +vertex+ to +:point+
    # * +:point+ the point which +vertex+ can be extended to.
    # * +:point2+ Only availible to +:vertex_projected+. The origin of the end vertex
    #   of the other edge. In this case +:point+ is the intersecting point where
    #   the two edges meet.
    #
    # @param [Sketchup::Vertex] vertex The open-end vertex to find connections for.
    # @param [Array<Sketchup::Vertex>] open_ends Set of availible open-end vertices.
    # @param [Array<Sketchup::Edge>] edges Set of edges to connect to.
    #
    # @return [Hash] Returns a hash with possible connection options.
    # @since 2.5.0
    def self.find( vertex, open_ends, edges )
      origin = vertex.position
      edge = vertex.edges.first
      other = edge.other_vertex( vertex ).position
      vector = origin.vector_to( other )
      line = edge.line

      ends = open_ends - [ vertex, edge.other_vertex( vertex ) ]
      end_edges = ends.map { |v| v.edges.first }

      distances = {}
      ends.each { |v|
        distances[v] = origin.distance( v.position )
      }

      # 1. Closest projected open end
      projected_vertices = {}
      projected_vertices_pt = {}
      for v in ends
        e = v.edges.first
        pt = Geom::intersect_line_line( line, e.line )
        next if pt.nil?

        direction = origin.vector_to(pt)
        next unless direction.valid?
        next if direction.samedirection?(vector)

        projected_vertices[v] = [
          origin.distance( pt ),
          pt.distance( v.position )
        ]
        projected_vertices_pt[v] = pt
      end
      closest_projected_vertex = projected_vertices.keys.min { |a,b|
        va = projected_vertices[a]
        vb = projected_vertices[b]
        if va[0] == vb[0]
          va[1] <=> vb[1]
        else
          va[0] <=> vb[0]
        end
      }
      pt = projected_vertices_pt[closest_projected_vertex]
      tmp = projected_vertices[closest_projected_vertex]
      dist = (tmp.nil?) ? nil : tmp[0]
      result = {}
      result[:vertex_projected] = { :dist => tmp, :point => pt, :point2 => closest_projected_vertex }

      # 3. Closest open vertex
      closest_open_vertex = ends.min { |a,b|
        distances[a] <=> distances[b]
      }
      pt = (closest_open_vertex) ? closest_open_vertex.position : nil
      dist = distances[closest_open_vertex]
      result[:vertex] = { :dist => dist, :point => pt }

      # 2. Closest edge
      edge_distances = {}
      edge_distances_pt = {}
      for e in edges
        next if e == edge
        pt = Geom::intersect_line_line( line, e.line )
        next if pt.nil?
        #next if pt == other
        pt1, pt2 = e.vertices.map { |v| v.position }
        next unless TT::Point3d.between?( pt1, pt2, pt, true )
        v = origin.vector_to(pt)
        next unless v.valid?
        next if v.samedirection?(vector)
        edge_distances[e] = origin.distance( pt )
        edge_distances_pt[e] = pt
      end
      closest_edge = edge_distances.keys.min { |a,b|
        edge_distances[a] <=> edge_distances[b]
      }
      pt = edge_distances_pt[closest_edge]
      dist = edge_distances[closest_edge]
      result[:edge] = { :dist => dist, :point => pt }

      result
    end # def


    # Finds all open-ended edges in +entities+ and returns an array of vertices
    # for each open end.
    #
    # @param [Sketchup::Entities|Array<Sketchup::Entity>] entities
    #
    # @return [Array<Sketchup::Vertex>]
    # @since 2.5.0
    def self.find_end_vertices( entities )
      vertices = []
      for e in entities
        next unless e.is_a?( Sketchup::Edge )
        open_ends =  e.vertices.select { |v| v.edges.length == 1 }
        vertices.concat( open_ends )
      end
      vertices
    end

  end # module TT::Edges::Gaps
end
