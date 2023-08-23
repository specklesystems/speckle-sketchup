#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require_relative 'core.rb'
require_relative 'javascript.rb'

# Sortable Hash that preserves the insertion order.
# Prints out JSON strings of the content.
#
# Based of Bill Kelly's InsertOrderPreservingHash
#
# @see http://www.ruby-forum.com/topic/166075#728764
#
# @since 2.4.0
module SpeckleConnector
  class TT::JSON
    include Enumerable

    # @since 2.4.0
    def initialize(*args, &block)
      if args.size == 1 && args[0].is_a?(Hash)
        @h = args[0].dup
        @ordered_keys = @h.keys
      else
        @h = Hash.new(*args, &block)
        @ordered_keys = []
      end
    end

    # @since 2.4.0
    def initialize_copy(source)
      super
      @h = @h.dup
      @ordered_keys = @ordered_keys.dup
    end

    # @since 2.4.0
    def []=(key, val)
      @ordered_keys << key unless @h.has_key? key
      @h[key] = val
    end

    # @since 2.4.0
    def each
      @ordered_keys.each {|k| yield(k, @h[k])}
    end
    alias :each_pair :each

    # @since 2.4.0
    def each_value
      @ordered_keys.each {|k| yield(@h[k])}
    end

    # @since 2.4.0
    def each_key
      @ordered_keys.each {|k| yield k}
    end

    # @since 2.4.0
    def key?(key)
      @h.key?(key)
    end
    alias :has_key? :key?
    alias :include? :key?
    alias :member? :key?

    # @since 2.4.0
    def keys
      @ordered_keys
    end

    # @since 2.4.0
    def values
      @ordered_keys.map {|k| @h[k]}
    end

    # @since 2.4.0
    def clear
      @ordered_keys.clear
      @h.clear
    end

    # @since 2.4.0
    def delete(k, &block)
      @ordered_keys.delete k
      @h.delete(k, &block)
    end

    # @since 2.4.0
    def reject!
      del = []
      each_pair {|k,v| del << k if yield k,v}
      del.each {|k| delete k}
      del.empty? ? nil : self
    end

    # @since 2.4.0
    def delete_if(&block)
      reject!(&block)
      self
    end

    # @since 2.4.0
    def merge!(hash)
      hash.each { |key, value|
        if @h.key?(key)
          @h[key] = value
        else
          self[key] = value
        end
      }
    end

    #%w(merge!).each do |name|
    #  define_method(name) do |*args|
    #  raise NotImplementedError, "#{name} not implemented"
    #  end
    #end

    # @since 2.4.0
    def method_missing(*args)
      @h.send(*args)
    end

    # @return [Hash]
    # @since 2.4.0
    def to_hash
      @h.dup
    end

    # Compile JSON Hash into a string.
    #
    # @since 2.4.0
    def to_s(format=false)
      arr = self.map { |k,v|
        key = ( k.is_a?(Symbol) ) ? k.to_s.inspect : k.inspect
        value = TT::Javascript.to_js(v, format)
        "#{key}: #{value}"
      }
      str = (format) ? arr.join(",\n\t") : arr.join(", ")
      return (format) ? "{\n\t#{str}\n}\n" : "{#{str}}"
    end
    alias :inspect :to_s

  end # class TT::JSON
end
