# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../speckle_connector_3/src/auth/server_auth_client'

module SpeckleConnector3
  module Auth
    # The account id is MD5(email + server url), so the url a sign-in saves must be the one the .NET SDK derives
    # from the same address (`new Uri(address).ToString().TrimEnd('/')`), or the same account gets two rows.
    # Expected values are what that .NET expression gives.
    class ServerUrlNormalisationTest < Minitest::Test
      SDK_URLS = {
        'https://app.speckle.systems' => 'https://app.speckle.systems',
        'https://app.speckle.systems/' => 'https://app.speckle.systems',
        'https://app.speckle.systems//' => 'https://app.speckle.systems',
        '  https://app.speckle.systems  ' => 'https://app.speckle.systems',
        'HTTPS://App.Speckle.Systems/' => 'https://app.speckle.systems',
        'https://app.speckle.systems:443' => 'https://app.speckle.systems',
        'http://localhost:80/' => 'http://localhost',
        'http://localhost:3000/' => 'http://localhost:3000',
        'https://speckle.example.com:8443' => 'https://speckle.example.com:8443',
        'http://speckle.example.com:443' => 'http://speckle.example.com:443',
        'https://example.com/speckle/' => 'https://example.com/speckle',
        'https://example.com/Speckle' => 'https://example.com/Speckle'
      }.freeze

      def test_a_server_address_normalises_to_the_url_the_sdk_derives_from_it
        SDK_URLS.each do |address, sdk_url|
          assert_equal sdk_url, ServerAuthClient.normalize_url(address), address
        end
      end

      def test_an_address_that_is_not_an_absolute_http_url_is_rejected
        ['speckle.example.com', 'ftp://speckle.example.com', 'https://', 'http://exa mple.com', ''].each do |address|
          assert_raises(InvalidServerUrlError, address) { ServerAuthClient.normalize_url(address) }
        end
      end
    end
  end
end
