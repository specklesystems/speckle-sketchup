# frozen_string_literal: true

require 'json'
require_relative '../../../test_helper'
require_relative '../../../../speckle_connector/src/speckle_objects/geometry/point'

module SpeckleConnector
  module SpeckleObjects
    module Geometry
      class PointTest < Minitest::Test
        def setup
          # Do nothing
        end

        def teardown
          # Do nothing
        end

        def test_point_to_json
          point = Point.new(1.0, 1.0, 1.0, 'm')
          serialized_point = {
            speckle_type: 'Objects.Geometry.Point',
            units: 'm',
            x: 1.0,
            y: 1.0,
            z: 1.0
          }
          serialized = point.to_json
          hash = JSON.parse(serialized, { symbolize_names: true })

          assert_equal(serialized_point, hash)
        end
      end
    end
  end
end
