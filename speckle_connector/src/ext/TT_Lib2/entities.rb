#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require_relative 'core.rb'
require_relative 'instance.rb'

# Collection of Entities methods.
#
# @since 2.0.0
module SpeckleConnector
  module TT::Entities


    # Returns a boundingbox for all the given entities.
    #
    # @param [Enumerable] entities
    #
    # @return [Geom::BoundingBox]
    # @since 2.1.0
    def self.bounds(entities)
      bb = Geom::BoundingBox.new
      for e in entities
        next unless e.respond_to?(:bounds)
        bb.add( e.bounds )
      end
      return bb
    end


    # Counts all unique +Sketchup::Entities+ collections in the given context,
    # including sub-entities.
    #
    # @param [Enumerable] context
    # @param [Hash] options
    #
    # @return [Integer]
    # @since 2.5.0
    def self.count_unique_entities( context, options={} )
      c = 0
      entities = nil # Init variables for speed
      self.each_entities( context, options={} ) { |entities| c = c.next  }
      c
    end


    # Counts all unique entities in the given collection, including sub-entities.
    #
    # @param [Enumerable] context
    # @param [Hash] options
    #
    # @return [Integer]
    # @since 2.5.0
    def self.count_unique_entity( context, options={} )
      c = context.length
      entities = nil # Init variables for speed
      self.each_entities( context, options={} ) { |entities|
        c += entities.length
      }
      c
    end


    # Yields each unique Entities collection recursivly.
    #
    #  TT::Entities.each_entities { |entities|
    #    processEntities( entities )
    #  }
    #
    # If a number is returned to the processing block it will be used to add up a
    # total when +each_entities+ returns.
    #
    #  TT::Entities.each_entities { |entities|
    #    c = 0
    #    for e in entities
    #      c += 1 if e.is_a?( SketchUp::Edge )
    #    end
    #    c
    #  }
    #
    # This example will return the total number of edges processed. Use to keep
    # statistic for the iteration.
    #
    # @param [Enumerable] context
    # @param [Hash] processed_definitions Hash index of processed entities.
    # @param [Hash] options
    #
    # @yield [entities]
    # @yieldparam [Enumerable|Sketchup::Entities] entities
    #
    # @return [Integer] Returns
    # @since 2.5.0
    def self.each_entities( context, processed_definitions={}, options={}, &block )
      skip_locked = options[:locked] && options[:locked].is_a?( Hash )
      c = 0
      result = yield( context )
      c += result if result.is_a?( Numeric )
      # Process Groups and ComponentInstances
      for e in context.to_a
        next unless e.valid? && TT::Instance.is?( e )
        d = TT::Instance.definition( e )
        if processed_definitions[d].nil?
          processed_definitions[d] = true
          next if skip_locked && options[:locked].key?(d)
          result = self.each_entities( d.entities, processed_definitions, options, &block )
          c += result if result.is_a?( Numeric )
        end
      end
      c
    end


    # Yields each entity recursivly.
    def self.each_entity( entities, processed_definitions={}, options={}, &block )
      skip_locked = options[:locked] && options[:locked].is_a?( Hash )
      c = 0
      for e in entities.to_a
        next if skip_locked && e.respond_to?( :locked? ) && e.locked?
        c = c.next if yield( e )
        # Process Groups and ComponentInstances
        next unless e.valid? && TT::Instance.is?( e )
        d = TT::Instance.definition( e )
        if processed_definitions[d].nil?
          processed_definitions[d] = true
          next if skip_locked && options[:locked].key?(d)
          c += self.each_entity( d.entities, processed_definitions, options, &block )
        end
      end # for
      c
    end


    # Collects the 3d positions of the vertices in the given entities collection.
    # Processes child Groups and Components recursivly.
    #
    # @param [Enumerable] entities
    # @param [Geom::Transformation] parent_transformation
    #
    # @return [Array<Geom::Point3d>]
    # @since 2.0.0
    def self.positions(entities, parent_transformation = Geom::Transformation.new)
      pts = []
      vertices = []
      for e in entities
        if e.respond_to?(:vertices)
          vertices << e.vertices
        elsif TT::Instance.is?( e )
          d = TT::Instance.definition(e)
          t = parent_transformation * e.transformation
          sub_pts = self.positions(d.entities, t)
          pts.concat( sub_pts )
        end
      end # for
      vertices.flatten!
      vertices.uniq!
      pts.concat( vertices.map { |v| v.position.transform( parent_transformation ) } )
      pts
    end

  end # module TT::Entities
end
