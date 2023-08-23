#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require_relative 'core.rb'

module SpeckleConnector
  # Collection of Group, ComponentInstnace and Image methods.
  #
  # @since 2.1.0
  module TT::UVQ

    # Get UV coordinates from UVQ matrix.
    #
    # Originally named +flatten+ in 2.1.0, renamed +normalize+ in 2.5.0.
    #
    # @param [Array] uvq
    #
    # @return [Array]
    # @since 2.1.0
    def self.normalize(uvq)
      Geom::Point3d.new(uvq.x / uvq.z, uvq.y / uvq.z, 1.0)
    end
    class << self
      alias :flatten :normalize
    end

  end # module TT::UVQ
end
