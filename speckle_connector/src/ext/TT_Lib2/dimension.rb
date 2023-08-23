#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require_relative 'core.rb'

# A 2d matrix Array that can be iterated in rows, columns or like a regular +Array+.
#
# *Note*: it does not behave exactly like a regular +Array+. Use the +.to_a+ method
# to get a regular array.
#
# @since 2.5.0

module SpeckleConnector
  class TT::Dimension
    include Enumerable

    # @since 2.5.0
    attr(:width)
    # @since 2.5.0
    attr(:height)


    # @overload new(array, width, height, obj = nil)
    #   @param [Array] array creates an Dimension from an array
    #   @param [Integer] width
    #   @param [Integer] height
    #   @param [Object] obj default value
    # @overload new(width, height, obj = nil)
    #   @param [Integer] width
    #   @param [Integer] height
    #   @param [Object] obj default value
    #
    # @since 2.5.0
    def initialize(*args)
      # Check if the first aruments is an +Array+ - use that to populate the dataset.
      arr = args.first.is_a?(Array) ? args.shift : nil
      # Validate arguments
      if args.length < 2
        raise ArgumentError, 'Missing arguments. Requires width and height.'
      end
      # Extract remaining arguments
      @width, @height, obj = args
      # Create 2-dimensional array
      @d = Array.new(@width * @height, obj)
      # Populate with the given data, if any.
      unless arr.nil?
        unless arr.length == @width * @height
          raise ArgumentError, 'Array length does not match width and height.'
        end
        arr.each_index { |i| @d[i] = arr[i] }
      end
    end

    # @example
    #   dim = Dimension.new([6,7,8,9], 2, 2)
    #   puts dim[2]
    #   -> 8
    #   puts dim[0,1]
    #   -> 8
    #
    # @overload [](index)
    #   @param [Integer] index an Integer between 0 and self.length-1
    # @overload [](row, column)
    #   @param [Integer] row an Integer between 0 and self.width-1
    #   @param [Integer] column an Integer between 0 and self.height-1
    #
    # @return [Object] value at the given index
    #
    # @since 2.5.0
    def [](*args)
      case args.length
      when 1
        return @d[ args.first ]
      when 2
        column, row = args
        return @d[ (row * @width) + column ]
      end
    end

    # @overload []=(index)
    #   @param [Integer] index an Integer between 0 and self.length-1
    # @overload []=(row, column)
    #   @param [Integer] row an Integer between 0 and self.width-1
    #   @param [Integer] column an Integer between 0 and self.height-1
    #
    # @since 2.5.0
    def []=(*args)
      value = args.pop
      case args.length
      when 1
        @d[args.first] = value
      when 2
        column, row = args
        @d[ (row * @width) + column ] = value
      end
    end

    # @param [Integer] index an Integer between +0+ and +self.height-1+
    #
    # @return [Array] row at index
    #
    # @since 2.5.0
    def row(index)
      return @d[index * @width, @width]
    end

    # Sets the row at the given index.
    #
    # @param [Integer] index an Integer between +0+ and +self.height-1+
    # @param [Array] new_row an +Array+ of the size +self.width+
    #
    # @return [Array] the new row
    #
    # @since 2.5.0
    def set_row(index, new_row)
      return @d[index * @width, @width] = new_row
    end

    # @return [Array<Array>] an array containing all the rows
    #
    # @since 2.5.0
    def rows
      arr = []
      0.step(@d.length - 1, @width) { |i|
        arr << @d[i, @width]
      }
      return arr
    end

    # @param [Integer] index an Integer between +0+ and +self.width-1+
    #
    # @return [Array] column at index
    #
    # @since 2.5.0
    def column(index)
      arr = []
      0.upto(@height - 1) { |j|
        arr << @d[index + (j * @width)]
      }
      return arr
    end

    # Sets the column at the given index.
    #
    # @param [Integer] index an Integer between +0+ and +self.width-1+
    # @param [Array] new_column an +Array+ of the size +self.height+
    #
    # @return [Array] the new column
    #
    # @since 2.5.0
    def set_column(index, new_column)
      0.upto(@height - 1) { |j|
        @d[index + (j * @width)] = new_column[j]
      }
    end

    # @return [Array<Array>] an +Array+ containing all the columns
    #
    # @since 2.5.0
    def columns
      arr = []
      0.upto(@width - 1) { |i|
        column = []
        0.upto(@height - 1) { |j|
          column << @d[i + (j * @width)]
        }
        arr << column
      }
      return arr
    end

    # @yield [array, index] an +Array+ representing either a row or a column
    #   depening on +column+
    # @yieldparam [Array] array
    # @yieldparam [optional, Integer] index
    #
    # @param [Boolean] column iterates columns when +true+ or rows
    #   when +false+
    #
    # @since 2.5.0
    def each(column = false, &block)
      if column
        0.upto(@width - 1) { |i|
          0.upto(@height - 1) { |j|
            index = i + (j * @width)
            if block.arity > 1
              yield( @d[index], index )
            else
              yield( @d[index] )
            end
          }
        }
      else
        @d.each { |i| yield(i) }
      end
    end

    # @yield [row, index]
    # @yieldparam [Array] row
    # @yieldparam [optional, Integer] index
    #
    # @since 2.5.0
    def each_row(&block)
      0.step(@d.length - 1, @width) { |i|
        if block.arity > 1
          yield( @d[i, @width], (i / @width) )
        else
          yield( @d[i, @width] )
        end
      }
    end

    # @yield [column, index]
    # @yieldparam [Array] column
    # @yieldparam [optional, Integer] index
    #
    # @since 2.5.0
    def each_column(&block)
      0.upto(@width - 1) { |i|
        column = []
        0.upto(@height - 1) { |j|
          column << @d[i + (j * @width)]
        }
        if block.arity > 1
          yield(column, i)
        else
          yield(column)
        end
      }
    end

    # @return [Integer] the size of the +Dimension+
    #
    # @since 2.5.0
    def length
      return @width * @height
    end
    alias :size :length

    # @return [Array] converts the Dimension to an array.
    #
    # @since 2.5.0
    def to_a(orient_by_columns = false)
      arr = []
      self.each(orient_by_columns) { |value|
        arr << value
      }
      return arr
    end

    # @return [String]
    # @since 2.5.0
    def inspect
      return "#<#{self.class}(#{@width}x#{@height})>"
    end

    # @return [TT::Dimension]
    # @since 2.5.0
    def map
      new_dim = TT::Dimension.new( self.width, self.height )
      self.each_with_index { |value, index|
        new_dim[index] = yield( value )
      }
      new_dim
    end

    # @return [TT::Dimension]
    # @since 2.5.0
    def map!
      @d.map! { |value| yield(value) }
      self
    end

  end # class TT::Dimension
end
