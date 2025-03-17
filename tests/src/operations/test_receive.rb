# frozen_string_literal: true

require 'net/http'

require_relative '../../test_helper'
require_relative '../../../speckle_connector/src/accounts/accounts'

module SpeckleConnector
  module Converters
    class ReceiveTest < Minitest::Test

      # Replace here test stream id on your local server account
      TEST_STREAM_ID = 'f0b4392dc8'

      # Replace here test object id
      TEST_OBJECT_ID = '76de2dc989ccab95c3c5ee2d977587b4'

      def setup
        # Do nothing
      end

      def teardown
        # Do nothing
      end

      def test_receive
        local_server_account = Accounts.try_get_local_server_account
        uri = URI.parse("https://speckle.xyz/objects/1ce562e99a/745ea505d154c09e2317121bd263a2b2/single")
        # uri = URI.parse("#{local_server_account['serverInfo']['url']}/objects/#{TEST_STREAM_ID}/#{TEST_OBJECT_ID}/single")
        http = Net::HTTP.new(uri.host, uri.port)
        req = Net::HTTP::Get.new(uri)
        req["Authorization"] = "Bearer #{local_server_account['token']}"
        res = http.request(req)
        object_id = JSON.parse(res.body)["id"]
        assert_equal(TEST_OBJECT_ID, object_id)
      rescue => e
        puts "failed #{e}"
      end
    end
  end
end
