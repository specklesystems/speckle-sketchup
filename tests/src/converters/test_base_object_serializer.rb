# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../speckle_connector_3/src/states/speckle_state'
require_relative '../../../speckle_connector_3/src/speckle_objects/geometry/point'
require_relative '../../../speckle_connector_3/src/speckle_objects/geometry/line'
require_relative '../../../speckle_connector_3/src/convertors/base_object_serializer'
require_relative '../../../speckle_connector_3/src/convertors/base_object_serializer_v2'

module SpeckleConnector3
  module Converters
    class BaseObjectSerializerTest < Minitest::Test
      def setup
        # Do nothing
      end

      def teardown
        # Do nothing
      end

      def test_base_initialize
        speckle_state = States::SpeckleState.new({}, {}, {}, {})
        start_point = SpeckleObjects::Geometry::Point.new(0.0, 0.0, 0.0, 'm')
        end_point = SpeckleObjects::Geometry::Point.new(10.0, 10.0, 0.0, 'm')
        line = SpeckleObjects::Geometry::Line.test_line(start_point, end_point, 'm')
        serializer = Converters::BaseObjectSerializerV2.new

        id, traversed = serializer.serialize(line)
        assert_equal(id, "a53c02860be04238514f1a5b00883fe2")
      end
    end
  end
end
