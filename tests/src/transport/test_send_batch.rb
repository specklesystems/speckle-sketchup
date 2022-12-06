# frozen_string_literal: true

require 'json'
require 'net/http'
require "uri"
require_relative '../../test_helper'
require_relative '../../../speckle_connector/src/speckle_objects/geometry/point'
require_relative '../../../speckle_connector/src/speckle_objects/geometry/line'

module SpeckleConnector
  module SpeckleObjects
    module Geometry
      class SendBatchTest < Minitest::Test
        TEST_STREAM_ID = '7007d02e4f'
        AUTH_TOKEN = 'b61a0439516b05f96332e98048f778871ef55ac436'
        SERVER_URL = 'https://speckle.xyz'
        AUTHORIZATION_HEADER = 'Bearer ' + AUTH_TOKEN

        def setup
          # Do nothing
        end

        def teardown
          # Do nothing
        end

        def test_send_reference

        end

        def test_send_line
          start_point = Point.new(0.0, 0.0, 0.0, 'm')
          end_point = Point.new(5.0, 5.0, 0.0, 'm')
          line = Line.test_line(start_point, end_point, 'm')

          serialized_line = line.to_json
          send_batch(serialized_line)
        end

        def test
          uri = URI('https://some.end.point/some/path')
          request = Net::HTTP::Post.new(uri)
          request['Authorization'] = 'If you need some headers'
          form_data = [['photos', photo.tempfile]] # or File.open() in case of local file

          request.set_form form_data, 'multipart/form-data'
          response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http| # pay attention to use_ssl if you need it
            http.request(request)
          end
        end

        def send_batch(batch)
          uri = URI.parse(SERVER_URL + '/objects/' + TEST_STREAM_ID)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          req = Net::HTTP::Post.new(uri)
          req["Authorization"] = AUTHORIZATION_HEADER
          req["Content-Type"] = "multipart/form-data"
          form_data = [['batch-1', batch]]
          req.set_form(form_data, 'multipart/form-data')
          res = http.request(req)

          # res = http.request(req)
          puts "response #{res.body}"
        rescue => e
          puts "failed #{e}"
        end
      end
    end
  end
end
