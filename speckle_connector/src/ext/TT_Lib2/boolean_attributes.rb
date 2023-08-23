#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require_relative 'core.rb'

# @example
#   class Foo
#     extend TT::BooleanAttributes
#     battr_accessor :bar
#   end
#
# @since 2.7.0
module SpeckleConnector
  module TT::BooleanAttributes

    # @since 2.7.0
    def battr( symbol, writable = false )
      self.class_eval {
        attr( symbol, writable )
        question = "#{symbol}?".to_sym
        alias_method( question, symbol )
        remove_method( symbol )
      }
    end

    # @since 2.7.0
    def battr_accessor( *args )
      self.class_eval {
        attr_accessor( *args )
        for attribute in args
          question = "#{attribute}?".to_sym
          alias_method( question, attribute )
          remove_method( attribute )
        end
      }
    end

    # @since 2.7.0
    def battr_reader( *args )
      self.class_eval {
        attr_reader( *args )
        for attribute in args
          question = "#{attribute}?".to_sym
          alias_method( question, attribute )
          remove_method( attribute )
        end
      }
    end

  end # class TT::BooleanAttributes
end
