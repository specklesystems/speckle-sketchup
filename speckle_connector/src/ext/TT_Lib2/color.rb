#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require_relative 'core.rb'

# Collection of Color methods.
#
# @since 2.5.0
module SpeckleConnector
  module TT::Color

    # Safely clones a Sketchup::Color object. Sketchup::Color.clone appear to
    # be bugged and prone to crash SU.
    #
    # @param [Sketchup::Color] color
    #
    # @return [Sketchup::Color]
    # @since 2.5.0
    def self.clone(color)
      Sketchup::Color.new( *color.to_a )
    end

  end # module TT::Instance
end
