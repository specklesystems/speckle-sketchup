#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require_relative 'core.rb'
require_relative 'json.rb'

# Javascript helper module.
#
# @since 2.5.0
module SpeckleConnector
  module TT::Javascript

    # Query to whether it's a Group or ComponentInstance
    #
    # @param [Object] object
    #
    # @return [String]
    # @since 2.5.0
    def self.to_js(object, format=false)
      if object.is_a?( TT::JSON )
        object.to_s(format)
      elsif object.is_a?( Hash )
        TT::JSON.new(object).to_s(format)
      elsif object.is_a?( Symbol ) # 2.5.0
        object.inspect.inspect
      elsif object.nil?
        'null'
      elsif object.is_a?( Array ) # 2.7.0
        data = object.map { |x| self.to_js(x, format) }
        "[#{data.join(',')}]"
      elsif object.is_a?( Geom::Point3d ) # 2.7.0
        "new Point3d( #{object.to_a.join(', ')} )"
      elsif object.is_a?( Geom::Vector3d ) # 2.7.0
        "new Vector3d( #{object.to_a.join(', ')} )"
      else
        # (!) Filter out accepted objects.
        # (!) Convert unknown into strings - then inspect.
        object.inspect
      end
    end

  end # module TT::Javascript
end
