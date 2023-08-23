#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require_relative 'core.rb'

module SpeckleConnector
  # Allows version comparisons based on a major, minor and revision system.
  #
  # @since 2.6.0
  class TT::Version

    include Comparable

    # @since 2.6.0
    attr_reader :major, :minor, :revision

    # @since 2.6.0
    def <=>( version )
      if @major > version.major
        return 1
      end
      if @major == version.major
        if @minor > version.minor
          return 1
        end
        if @minor == version.minor
          return @revision <=> version.revision
        end
      end
      return -1
    end

    # @overload new( major, minor, revision )
    #   @param [Integer] major
    #   @param [Integer] minor
    #   @param [Integer] revision
    # @overload new( version_array )
    #   @param [Array] version_array
    # @overload new( version_string )
    #   @param [String] version_string Parse strings such as '1.2.3', '1.2' and '1'
    # @overload new( float_version )
    #   @param [Float] float_version Float value of 1.2 become major: 1, minor: 2
    # @overload new( version )
    #   @param [TT::Version] version
    #
    # @since 2.6.0
    def initialize( *args )
      # Validate argument size.
      if args.size == 1
        version = args[0]
      elsif args.size < 4
        version = args
      else
        raise ArgumentError, 'Wrong number of arguments.'
      end

      # Extract version into from known types into an array.
      if version.is_a?( String )
        version = version.split('.')

      elsif version.is_a?( Integer )
        version = [ version, 0,0 ]

      elsif version.is_a?( Float )
        major, minor = version.to_s.split('.')
        version = [ major, minor, 0 ]

      elsif version.is_a?( self.class )
        version = version.to_a

      end

      # Validate the processed version info.
      if version.is_a?( Array )
        # Validate array size.
        unless version.size > 0 && version.size < 4
          raise ArgumentError, 'Invalid version format.'
        end
        # Ensure everything to be an integer value.
        version.map! { |string| string.to_i }
        # All missing version info is set to zero.
        major, minor, revision = version
        major = 0 if major.nil?
        minor = 0 if minor.nil?
        revision = 0 if revision.nil?
      else
        raise ArgumentError, 'Invalid argument type.'
      end

      @major = major
      @minor = minor
      @revision = revision
    end

    # @return [TT::Version]
    # @since 2.6.0
    def major=( value )
      unless value.is_a?( Integer ) || value.respond_to?( :to_i )
        raise ArgumentError, 'Argument can not be converted into an Integer.'
      end
      @major = value.to_i
      self
    end

    # @return [TT::Version]
    # @since 2.6.0
    def minor=( value )
      unless value.is_a?( Integer ) || value.respond_to?( :to_i )
        raise ArgumentError, 'Argument can not be converted into an Integer.'
      end
      @minor = value.to_i
      self
    end

    # @return [TT::Version]
    # @since 2.6.0
    def revision=( value )
      unless value.is_a?( Integer ) || value.respond_to?( :to_i )
        raise ArgumentError, 'Argument can not be converted into an Integer.'
      end
      @revision = value.to_i
      self
    end

    # @return [String]
    # @since 2.6.0
    def inspect
      "<#{self.class}::#{@major}.#{@minor}.#{@revision}>"
    end

    # @return [Array]
    # @since 2.6.0
    def to_a
      [ @major, @minor, @revision ]
    end

    # @return [String]
    # @since 2.6.0
    def to_s
      "#{@major}.#{@minor}.#{@revision}"
    end

  end # class TT::Version
end
