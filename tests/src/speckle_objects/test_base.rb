# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../speckle_connector_3/src/speckle_objects/base'

module SpeckleConnector3
  module SpeckleObjects
    class BaseTest < Minitest::Test
      def setup
        # Do nothing
      end

      def teardown
        # Do nothing
      end

      def test_base_init
        base = Base.new
        json = base.to_json

        base_obj = {"speckle_type":"Base","applicationId":nil,"id":nil}
        serialized = JSON.generate(base_obj)

        assert_equal(json, serialized)
      end

      def test_base_set_property
        base = Base.new
        base[:sketchup_attributes] = {soften_edge: true}
        base[:id] = 'idididididid'

        base_obj = {"speckle_type":"Base","applicationId":nil,"id":'idididididid', "sketchup_attributes": {"soften_edge": true }}
        serialized = JSON.generate(base_obj)
        hash = JSON.parse(serialized, { symbolize_names: true })

        assert_equal(base, hash)
      end
    end
  end
end
