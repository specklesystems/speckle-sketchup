#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require_relative 'core.rb'

# Collection of Length methods.
#
# @since 2.7.0
module SpeckleConnector
  module TT::Length

    # @param [Length] length
    # @param [Length] snap
    #
    # @return [Length]
    # @since 2.7.0
    def self.snap( length, snap )
      return length.to_l if snap.zero?
      diff = length % snap
      if diff > snap / 2.0
        new_length = length - diff + snap
      else
        new_length = length - diff
      end
      new_length.to_l
    end

  end # module TT::Length
end
