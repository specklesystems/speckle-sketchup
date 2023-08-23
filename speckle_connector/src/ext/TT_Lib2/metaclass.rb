#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require_relative 'core.rb'

module SpeckleConnector
  # @example
  #   module Foo
  #     extend TT::MetaClass
  #     cattr :bar
  #   end
  #
  # @since 2.7.0
  module TT::MetaClass

    # @since 2.7.0
    def metaclass
      class << self
        self
      end
    end

    # @since 2.7.0
    def cattr_accessor( *args )
      metaclass.class_eval {
        attr_accessor( *args )
      }
    end
    alias :cattr :cattr_accessor

    # @since 2.7.0
    def cattr_reader( *args )
      metaclass.class_eval {
        attr_reader( *args )
      }
    end

    # @since 2.7.0
    def cattr_writer( *args )
      metaclass.class_eval {
        attr_writer( *args )
      }
    end

    # @since 2.7.0
    def cbattr_accessor( *args )
      metaclass.class_eval {
        attr_accessor( *args )
        for attribute in args
          question = "#{attribute}?".to_sym
          alias_method( question, attribute )
          remove_method( attribute )
        end
      }
    end
    alias :cbattr :cbattr_accessor

    # @since 2.7.0
    def cbattr_reader( *args )
      metaclass.class_eval {
        attr_reader( *args )
        for attribute in args
          question = "#{attribute}?".to_sym
          alias_method( question, attribute )
          remove_method( attribute )
        end
      }
    end

    # @since 2.7.0
    alias :cbattr_writer :cattr_writer

  end # module TT::MetaClass
end
