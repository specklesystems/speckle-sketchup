# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'
require 'zlib'

require_relative '../../test_helper'
require_relative '../../../speckle_connector/src/states/speckle_state'
require_relative '../../../speckle_connector/src/accounts/accounts'
require_relative '../../../speckle_connector/src/speckle_objects/geometry/point'
require_relative '../../../speckle_connector/src/speckle_objects/geometry/line'
require_relative '../../../speckle_connector/src/convertors/base_object_serializer'
require_relative '../../../speckle_connector/src/immutable/immutable'
require_relative '../../../speckle_connector/src/operations/send'

module SpeckleConnector3
  module Converters
    class SendTest < Minitest::Test
      include Immutable::ImmutableUtils

      # Replace here test stream id
      TEST_STREAM_ID = 'f0b4392dc8'
      TEST_PREFERENCES = {
        user: {
          register_speckle_entity: true
        }
      }.freeze

      entity_functions = Proc.new do |klass|
        def attribute_dictionary(name)
          attribute_dictionaries.find { |dict| dict.name == name }
        end
        def get_attribute(name, key)
          nil
        end
        def set_attribute(dictionary_name, key, new_value)
          nil
        end
      end

      FakeEntity = Struct.new('Entity', :application_id, :persistent_id, :material, :attribute_dictionaries,
                              &entity_functions)
      FakeAttributeDictionary = Struct.new('AttributeDictionary', :name)

      speckle_entity_functions = Proc.new do |klass|
        def with_valid_stream_id(stream_id)
          valid_stream_ids.append(stream_id)
        end
      end

      FakeSpeckleEntity = Struct.new('SpeckleEntity', :sketchup_entity, :valid_stream_ids, &speckle_entity_functions)

      speckle_state_functions = Proc.new do |klass|
        def with_speckle_entity(speckle_entity)
          speckle_entities.put(speckle_entity.id, speckle_entity)
        end
      end

      FakeSpeckleState = Struct.new('SpeckleState', :speckle_entities, &speckle_state_functions)

      def setup
        # Do nothing
      end

      def teardown
        # Do nothing
      end

      def test_send_line
        start_point = SpeckleObjects::Geometry::Point.new(0.0, 0.0, 0.0, 'm')
        end_point = SpeckleObjects::Geometry::Point.new(5.0, 5.0, 0.0, 'm')
        line = SpeckleObjects::Geometry::Line.test_line(start_point, end_point, 'm')

        serialized_line = line.to_json
        speckle_state = FakeSpeckleState.new(Immutable::EmptyHash)
        entity = FakeEntity.new('persistent_id', 'application_id', nil, {})
        base_and_entities = [line, [entity]]

        serializer = SpeckleConnector3::Converters::BaseObjectSerializer.new(speckle_state, TEST_STREAM_ID, TEST_PREFERENCES)
        id = serializer.serialize(base_and_entities)
        batches = serializer.batch_json_objects
        send_batch(batches)
      end

      # @param string [String]
      def gzip(string)
        encoded_string = string.encode('UTF-8')
        io = StringIO.new
        io.puts(encoded_string)
        gzip = Zlib::GzipWriter.new(io)
        # Zlib::Deflate.deflate(string)
        # gzip << encoded_string
        # gzip.close.string
        gzip.close.string
      end

      def send_batch(batch)
        # compressed_contents = gzip(batch) # FIXME!
        local_server_account = Accounts.try_get_local_server_account

        boundary = "----RubyMultipartClient#{rand(1000000)}ZZZZZ"
        payload = Operations.format_payload(boundary, batch, 'application/json')

        uri = URI.parse("#{local_server_account['serverInfo']['url']}/objects/#{TEST_STREAM_ID}")
        http = Net::HTTP.new(uri.host, uri.port)
        req = Net::HTTP::Post.new(uri)
        req['Content-Type'] = "multipart/form-data; boundary=#{boundary}"
        req["Authorization"] = "Bearer #{local_server_account['token']}"
        res = http.request(req, payload)
      rescue => e
        puts "failed #{e}"
      end
    end
  end
end
