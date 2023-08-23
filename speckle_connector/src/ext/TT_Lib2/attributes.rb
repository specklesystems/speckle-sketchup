#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require_relative 'core.rb'

# Collection of AttributeDictionary methods.
#
# @since 2.5.0
module SpeckleConnector
  module TT::Attributes

    # Compare two +AttributeDictionaries+ objects.
    #
    # @param [Sketchup::AttributeDictionaries] dictionaries1
    # @param [Sketchup::AttributeDictionaries] dictionaries2
    #
    # @return [Boolean]
    # @since 2.5.0
    def self.dictionaries_equal?( dictionaries1, dictionaries2 )
      if dictionaries1.nil? || dictionaries2.nil?
        if dictionaries1.nil? && dictionaries2.nil?
          return true
        else
          return false
        end
      end
      for dictionary in dictionaries1
        return false unless d = dictionaries2[ dictionary.name ]
        return false unless self.dictionary_equal?( dictionary, d, false )
      end
      return true
    end


    # Compare two +AttributeDictionary+ objects. By defaults their names must
    # match, but one can set +compare_name+ to +false+ to only compare their
    # content.
    #
    # @param [Sketchup::AttributeDictionary] dictionary1
    # @param [Sketchup::AttributeDictionary] dictionary2
    # @param [Boolean] compare_name
    #
    # @return [Boolean]
    # @since 2.5.0
    def self.dictionary_equal?( dictionary1, dictionary2, compare_name = true )
      if compare_name
        return false unless dictionary1.name == dictionary2.name
      end
      return false unless dictionary1.length == dictionary2.length
      return false unless dictionary1.keys == dictionary2.keys
      for key in dictionary1.keys
        return false unless dictionary1[key] == dictionary2[key]
      end
      return true
    end

  end # module TT::Attributes
end

