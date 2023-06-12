# frozen_string_literal: true

require_relative 'length'
require_relative 'point'
require_relative 'bounding_box'
require_relative '../base'
require_relative '../primitive/interval'
require_relative '../../sketchup_model/dictionary/base_dictionary_handler'
require_relative '../../sketchup_model/dictionary/speckle_schema_dictionary_handler'

module SpeckleConnector
  module SpeckleObjects
    module Geometry
      # Line object definition for Speckle.
      class Polyline < Base
        SPECKLE_TYPE = OBJECTS_GEOMETRY_POLYLINE

        def initialize(value:, domain:, length:, closed:, units:, application_id: nil)
          super(
            speckle_type: SPECKLE_TYPE,
            total_children_count: 0,
            application_id: application_id,
            id: nil
          )
          self[:value] = value
          self[:domain] = domain
          self[:length] = length
          self[:closed] = closed
          self[:units] = units
        end

        # @param loop [Sketchup::Loop] loop to convert closed speckle polyline.
        def self.from_loop(loop, units)
          points = loop.vertices.collect(&:position)
          values = points.collect do |p|
            [Geometry.length_to_speckle(p.x, units),
             Geometry.length_to_speckle(p.y, units),
             Geometry.length_to_speckle(p.z, units)]
          end.flatten
          loop_length = loop.edges.sum(&:length)
          length = Geometry.length_to_speckle(loop_length, units)
          domain = Primitive::Interval.from_lengths(0, loop_length, units)
          Polyline.new(
            value: values,
            domain: domain,
            length: length,
            units: units,
            closed: true,
            application_id: loop.entityID
          )
        end
      end
    end
  end
end
