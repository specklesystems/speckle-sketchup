# frozen_string_literal: true

require 'json'
require_relative '../../../test_helper'
require_relative '../../../../speckle_connector_3/src/speckle_objects/geometry/vector'

module SpeckleConnector3
  module SpeckleObjects
    module Geometry
      class VectorTest < Minitest::Test
        def setup
          # Do nothing
        end

        def teardown
          # Do nothing
        end

        def test_vector_to_json
          point = Vector.new(1.0, 1.0, 1.0, 'm')
          serialized_point = {
            speckle_type: 'Objects.Geometry.Vector',
            units: 'm',
            x: 1.0,
            y: 1.0,
            z: 1.0
          }
          serialized = JSON.generate(point)
          hash = JSON.parse(serialized, { symbolize_names: true })

          assert_equal(serialized_point, hash)
        end
      end
    end
  end
end
