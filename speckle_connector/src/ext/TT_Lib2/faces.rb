#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require_relative 'core.rb'
require_relative 'geom3d.rb'
require_relative 'uvq.rb'

# Collection of Face methods.
#
# @since 2.0.0
module SpeckleConnector
	module TT::Face

		# Returns all vertices in the face's outer loop that isn't connecting colinear
		# edges.
		#
		# @param [Sketchup::Face] face
		#
		# @return [Array<Sketchup::Vertex>]
		# @since 2.5.0
		def self.corners(face)
			corners = []
			# We only check the outer loop, ignoring interior lines.
			face.outer_loop.edgeuses.each { |eu|
				# Ignore vertices that's between co-linear edges.
				v1 = eu.edge.line[1]
				v2 = eu.next.edge.line[1]
				if v1.valid? && v2.valid? && !v1.parallel?( v2 )
					#unless v1.parallel?( v2 )
					#unless eu.edge.line[1].parallel?( eu.next.edge.line[1] )
					# Find which vertex is shared between the two edges.
					# (?) TT::Edges.common_vertex( eu.edge, eu.next.edge )
					if eu.edge.start.used_by?(eu.next.edge)
						corners << eu.edge.start
					else
						corners << eu.edge.end
					end
				end
			}
			return corners
		end


		# @param [Sketchup::Face] face
		#
		# @return [Boolean] Returns true if the face has four corners.
		# @since 2.5.0
		def self.is_quad?( face )
			face.is_a?( Sketchup::Face ) &&
				self.corners( face ).length == 4
		end


		# @param [Sketchup::Face] face
		# @param [Sketchup::TextureWriter] texture_writer
		# @param [Boolean] front_to_back
		#
		# @return [Boolean] Returns true if the face has four corners.
		# @since 2.5.0
		def self.mirror_material(face, texture_writer, front_to_back=true)
			# Get the material to mirror
			material = (front_to_back) ? face.material : face.back_material
			# Plain colour and Default is simply mirrored
			if material.nil? || material.materialType < 1
				if front_to_back
					face.back_material = material
				else
					face.material = material
				end
				return
			end
			# Get four Point3d samples from the face's plane.
			# We take one point from the face and offset that in X and Y
			# on the face's plane. This ensures we get enough data.
			# Previously I sampled data from vertices, which lead to problems
			# for triangles with distorted textures. Distorted textures require
			# four UV points.
			samples = []
			samples << face.vertices[0].position			 # 0,0 | Origin
			samples << samples[0].offset(face.normal.axes.x) # 1,0 | Offset Origin in X
			samples << samples[0].offset(face.normal.axes.y) # 0,1 | Offset Origin in Y
			samples << samples[1].offset(face.normal.axes.y) # 1,1 | Offset X in Y
			# Arrays containing 3D and UV points.
			xyz = []
			uv = []
			uvh = face.get_UVHelper(true, true, texture_writer)
			samples.each { |position|
				# XYZ 3D coordinates
				xyz << position
				# UV 2D coordinates
				if front_to_back
					uvq = uvh.get_front_UVQ(position)
				else
					uvq = uvh.get_back_UVQ(position)
				end
				uv << TT::UVQ.normalize(uvq)
			}
			# Position texture.
			pts = []
			(0..3).each { |i|
				pts << xyz[i]
				pts << uv[i]
			}
			face.position_material(material, pts, !front_to_back)
			nil
		end

	end # module TT::Face


	# Collection of methods for sets of faces.
	#
	# @since 2.5.0
	module TT::Faces

		# @param [Sketchup::Face] face1
		# @param [Sketchup::Face] face2
		#
		# @return [Boolean]
		# @since 2.5.0
		def self.coplanar?(face1, face2)
			TT::Geom3d.planar_points?( face1.vertices + face2.vertices )
		end

	end # module TT::Faces
end
