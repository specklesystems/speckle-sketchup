# frozen_string_literal: true

require_relative '../accounts/accounts'

module SpeckleConnector
  # Operations between server and connector.
  module Operations
    # Receive operation. (WIP)
    def self.receive(stream_id, object_id)
      default_account = Accounts.default_account
      url = default_account['serverInfo']['url']
      token = default_account['token']
      uri = URI.parse("#{url}/objects/#{stream_id}/#{object_id}/single")

      headers = {}
      headers['Authorization'] = "Bearer #{token}"
      headers['Accept'] = 'text/plain'
      content = nil

      @request = Sketchup::Http::Request.new(uri.to_s, Sketchup::Http::GET)
      @request.headers = headers

      # Can't catch here content as sync...!
      @request.start do |req, res|
        content = res.body
      end

      content
    end
  end
end
