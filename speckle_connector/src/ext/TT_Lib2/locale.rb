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
  # @since 2.4.0
  module TT::Locale

    # Some locale settings uses the comma as decimal separator. .to_f does not
    # account for this, so all commas must be coverted to periods.
    #
    # @param [String] string
    #
    # @return [Float]
    # @since 2.4.0
    def self.string_to_float(string)
      # Dirty hack to get the current locale's decimal separator, which is then
      # replaced in the string to a period which is what the .to_f method expects.
      @decimal_separator ||= self.decimal_separator
      string.tr(@decimal_separator, '.').to_f
    end


    # Returns a string with the decimal separator in the user's locale and
    # in the precision of the model units.
    #
    # @param [Float] float
    # @param [Integer] precision (Added: 2.7.0)
    #
    # @return [String]
    # @since 2.4.0
    def self.float_to_string( float, precision = nil )
      @decimal_separator ||= self.decimal_separator
      if precision
        sprintf( "%.#{precision}f", float ).tr!( '.', @decimal_separator )
      else
        float.to_s.tr!( '.', @decimal_separator )
      end
    end


    # Formats the given float to a string with the user's locale decimal delmitor
    # and with the precision given in the model's option for lengths.
    #
    # @param [Float] float
    # @param [Sketchup::Model] model
    #
    # @return [String]
    # @since 2.4.0
    def self.format_float(float, model)
      @decimal_separator ||= self.decimal_separator
      precision = model.options['UnitsOptions']['LengthPrecision']
      num = sprintf("%.#{precision}f", float)
      if num.to_f != float
        num = "~ #{num}"
      end
      num.tr!('.', @decimal_separator)
      num
    end


    # Casts +string+ to +type+s class.
    #
    # @param [String] string
    # @param [Mixed] type Class or an instance of an class.
    # @param [String] array_split
    #
    # @return [Mixed]
    # @since 2.4.0
    def self.cast_string(string, type, array_split = ',')
      type = type.new if type.class == Class
      if string == 'null'
        value = nil
      elsif type.is_a?( Integer )
        value = string.to_i
      elsif type.is_a?( Float ) && !type.is_a?( Length )
        value = self.string_to_float(string)
      elsif type.is_a?( Length )
        value = string.to_l
      elsif type.is_a?( TrueClass ) || type.is_a?( FalseClass )
        value = ( string.downcase == 'true' ) ? true : false
      elsif type.is_a?( Array )
        value = string.split( array_split )
      else
        value = string
      end
      value
    end


    # Hack to determine if the user's locale uses comma or periodas decimal
    # separator. Makes the assumption that if it's not period, then is is
    # comma. Yields incorrect result if the user has some other obscure
    # separator.
    #
    # @return [String]
    # @since 2.4.0
    def self.decimal_separator
      # If this raises an error the decimal separator is not '.'
      '1.2'.to_l
      return '.'
    rescue
      return ','
    end


    # @note Currently makes the assumption that locales with comma as decimal
    #       uses semi-colon and locales with period as decimal uses comma.
    #
    # @return [String]
    # @since 2.6.0
    def self.list_separator
      ( self.decimal_separator == '.' ) ? ',' : ';'
    end

  end # module TT::Locale
end
