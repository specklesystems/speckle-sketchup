# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../speckle_connector/src/states/speckle_state'
require_relative '../../../speckle_connector/src/speckle_objects/geometry/point'
require_relative '../../../speckle_connector/src/speckle_objects/geometry/line'
require_relative '../../../speckle_connector/src/convertors/base_object_serializer'

module SpeckleConnector
  module Converters
    class BaseObjectSerializerTest < Minitest::Test
      def setup
        # Do nothing
      end

      def teardown
        # Do nothing
      end

      def test_base_initialize
        speckle_state = States::SpeckleState.new({}, {}, {})
        start_point = SpeckleObjects::Geometry::Point.new(0.0, 0.0, 0.0, 'm')
        end_point = SpeckleObjects::Geometry::Point.new(10.0, 10.0, 0.0, 'm')
        line = SpeckleObjects::Geometry::Line.test_line(start_point, end_point, 'm')
        serializer = Converters::BaseObjectSerializer.new

        new_speckle_state, id, traversed = serializer.serialize(line, speckle_state)
        assert_equal(id, "a53c02860be04238514f1a5b00883fe2")
      end
    end
  end
end
