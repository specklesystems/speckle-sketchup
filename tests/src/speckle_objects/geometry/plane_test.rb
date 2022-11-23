# frozen_string_literal: true

require 'json'
require_relative '../../../test_helper'
require_relative '../../../../speckle_connector/src/speckle_objects/geometry/plane'

module SpeckleConnector
  module SpeckleObjects
    module Geometry
      class PlaneTest < Minitest::Test
        def setup
          # Do nothing
        end

        def teardown
          # Do nothing
        end

        def test_plane_to_json
          plane = Plane.origin('m')
          serialized_plane = {
            speckle_type: 'Objects.Geometry.Plane',
            units: 'm',
            xdir: {
              speckle_type: 'Objects.Geometry.Vector',
              units: 'm',
              x: 1.0,
              y: 0.0,
              z: 0.0
            },
            ydir: {
              speckle_type: 'Objects.Geometry.Vector',
              units: 'm',
              x: 0.0,
              y: 1.0,
              z: 0.0
            },
            normal: {
              speckle_type: 'Objects.Geometry.Vector',
              units: 'm',
              x: 0.0,
              y: 0.0,
              z: 1.0
            },
            origin: {
              speckle_type: 'Objects.Geometry.Point',
              units: 'm',
              x: 0.0,
              y: 0.0,
              z: 0.0
            }
          }

          serialized = JSON.generate(plane)
          hash = JSON.parse(serialized, { symbolize_names: true })

          assert_equal(serialized_plane, hash)
        end
      end
    end
  end
end
