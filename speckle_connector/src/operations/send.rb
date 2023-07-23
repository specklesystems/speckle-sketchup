# frozen_string_literal: true

require_relative '../accounts/accounts'

module SpeckleConnector
  # Operations between server and connector.
  module Operations
    # Formats payload as multipart data.
    # @param boundary [String] randomly generated boundary to wrap data.
    # @param payload_data [String] data to wrap between boundaries
    # @param content_type [String] type of the data i.e. application/json, application/gzip...
    # @return [String] formatted data for multipart form-data.
    def self.format_payload(boundary, payload_data, content_type)
      data = []
      data << "--#{boundary}\r\n"
      data << "Content-Disposition: form-data; name=\"file\"; filename=\"data\"\r\n"
      data << "Content-Type: #{content_type}\r\n\r\n"
      data << payload_data
      data << "\r\n\r\n--#{boundary}--\r\n"
      data.join
    end

    # Send operation. (WIP)
    # @param stream_id [String] stream id to send batches.
    # @param batches [Array<String>] batches to send stream.
    def self.send_json(stream_id, batches)
      account = Accounts.default_account

      boundary = "----RubyMultipartClient#{rand(1000000)}ZZZZZ"
      payload = format_payload(boundary, batches, 'application/json')

      uri = URI.parse("#{account['serverInfo']['url']}/objects/#{stream_id}")

      headers = {}
      headers['Content-Type'] = "multipart/form-data; boundary=#{boundary}"
      headers['Authorization'] = "Bearer #{account['token']}"

      request = Sketchup::Http::Request.new(uri.to_s, Sketchup::Http::POST)
      request.headers = headers
      request.body = payload

      request.start do |req, res|
        # Not entering
        p res
        p res.status_code
        puts res.body
      end
    end
  end
end
