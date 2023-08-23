#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require_relative 'core.rb'
require_relative 'entities.rb'

module SpeckleConnector
  # Collection of Selection methods.
  #
  # @since 2.0.0
  module TT::Selection

    # Returns a boundingbox for all the given entities.
    #
    # @param [Sketchup::Entities] entities
    #
    # @return [Geom::BoundingBox]
    # @since 2.1.0
    def self.bounds
      TT::Entities.bounds( Sketchup.active_model.selection )
    end

  end # module TT::Selection
end
