#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require_relative 'core.rb'
require_relative 'instance.rb'

# Collection of Face methods.
#
# @since 2.0.0

module SpeckleConnector
  module TT::Image

    # Returns the material for the given +Image+.
    #
    # @param [Sketchup::Image] image
    #
    # @return [Sketchup::Material]
    # @since 2.0.0
    def self.material(image)
      definition = TT::Instance.definition(image)
      face = definition.entities.grep(Sketchup::Face).first
      face.material
    end

  end # module TT::Image
end
