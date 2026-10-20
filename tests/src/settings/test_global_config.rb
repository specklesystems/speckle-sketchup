# frozen_string_literal: true

require 'json'
require_relative '../../test_helper'
require_relative '../../../speckle_connector_3/src/settings/global_config'

module SpeckleConnector3
  module Settings
    class GlobalConfigTest < Minitest::Test
      DUI_KEY = GlobalConfig::DUI_URL_KEY
      SERVER_KEY = GlobalConfig::DEFAULT_SERVER_URL_KEY
      UPDATE_KEY = GlobalConfig::UPDATE_NOTIFICATION_DISABLED_KEY

      def resolver(env: {}, registry: {}, platform: :windows)
        @warnings = []
        @registry_calls = []
        reader = lambda do |hive, key|
          @registry_calls << [hive, key]
          registry[[hive, key]]
        end
        GlobalConfig.new(
          env: env, platform: platform, registry_reader: reader, warn: ->(message) { @warnings << message }
        )
      end

      def test_defaults_when_nothing_set
        config = resolver
        assert_equal 'https://dui.speckle.systems', config.dui_url
        assert_equal 'https://app.speckle.systems', config.default_speckle_server_url
        refute config.update_notification_disabled?
        assert_empty @warnings
      end

      def test_env_wins_over_registry
        config = resolver(
          env: { DUI_KEY => 'http://127.0.0.1:8082' },
          registry: { [:hklm, DUI_KEY] => 'https://hklm.example' }
        )
        assert_equal 'http://127.0.0.1:8082', config.dui_url
        assert_empty @registry_calls
      end

      def test_hklm_wins_over_hkcu
        config = resolver(
          registry: { [:hklm, DUI_KEY] => 'https://hklm.example', [:hkcu, DUI_KEY] => 'https://hkcu.example' }
        )
        assert_equal 'https://hklm.example', config.dui_url
        assert_equal [[:hklm, DUI_KEY]], @registry_calls
      end

      def test_blank_env_falls_through_to_registry
        config = resolver(env: { DUI_KEY => '   ' }, registry: { [:hkcu, DUI_KEY] => 'https://hkcu.example' })
        assert_equal 'https://hkcu.example', config.dui_url
        assert_equal [[:hklm, DUI_KEY], [:hkcu, DUI_KEY]], @registry_calls
      end

      def test_macos_never_reads_registry
        config = resolver(platform: :macos, registry: { [:hklm, DUI_KEY] => 'https://hklm.example' })
        assert_equal 'https://dui.speckle.systems', config.dui_url
        assert_empty @registry_calls

        config = resolver(platform: :macos, env: { DUI_KEY => 'https://env.example' })
        assert_equal 'https://env.example', config.dui_url
      end

      def test_invalid_url_falls_back_with_warning
        ['garbage', 'not a url', '/relative'].each do |value|
          config = resolver(env: { SERVER_KEY => value })
          assert_equal 'https://app.speckle.systems', config.default_speckle_server_url, value
          assert_equal 1, @warnings.length, value
          assert_includes @warnings.first, SERVER_KEY
        end
      end

      def test_bool_parsing
        ['true', 'True', ' TRUE '].each do |value|
          assert resolver(env: { UPDATE_KEY => value }).update_notification_disabled?, value
          assert_empty @warnings
        end
        refute resolver(env: { UPDATE_KEY => 'false' }).update_notification_disabled?
        %w[garbage 1].each do |value|
          refute resolver(env: { UPDATE_KEY => value }).update_notification_disabled?, value
          assert_equal 1, @warnings.length, value
        end
      end

      def test_to_h_matches_dui_contract
        json = JSON.parse(resolver.to_h.to_json)
        assert_equal %w[isUpdateNotificationDisabled defaultSpeckleServerUrl duiUrl], json.keys
        assert_equal false, json['isUpdateNotificationDisabled']
      end
    end
  end
end
