# frozen_string_literal: true

require_relative 'length'
require_relative 'point'
require_relative 'bounding_box'
require_relative '../base'
require_relative '../primitive/interval'

module SpeckleConnector
  module SpeckleObjects
    module Geometry
      # Polyline object definition for Speckle.
      class Polyline < Base
        SPECKLE_TYPE = OBJECTS_GEOMETRY_POLYLINE

        # @param value [Array<Numeric>] polygon vertex coordinates as flat list.
        # @param domain [Primitive::Interval] domain of the polyline.
        # @param length [Numeric] length of the polyline.
        # @param closed [Boolean] whether polyline is closed or not.
        # @param units [String] units of the polyline.
        # @param application_id [String] application id of the polyline which corresponds to persistent_id of the Loop.
        # rubocop:disable Metrics/ParameterLists
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
        # rubocop:enable Metrics/ParameterLists

        # @param loop [Sketchup::Loop] loop to convert closed speckle polyline.
        def self.from_loop(loop, units, global_transformation: nil)
          points = loop.vertices.collect do |vertex|
            position = vertex.position
            position = vertex.position.transform!(global_transformation) unless global_transformation.nil?
            position
          end
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
            application_id: loop.persistent_id.to_s
          )
        end
      end
    end
  end
end
