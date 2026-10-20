# frozen_string_literal: true

require 'uri'

module SpeckleConnector3
  module Settings
    # Resolves machine-wide connector configuration: env var > HKLM > HKCU > default,
    # the same keys and precedence as the .NET connectors' GlobalConfigResolver.
    class GlobalConfig
      REGISTRY_PATH = 'Software\\Speckle\\Connector Config\\Global'
      DUI_URL_KEY = 'SPECKLE_DUI_URL'
      DEFAULT_SERVER_URL_KEY = 'SPECKLE_DEFAULT_SPECKLE_SERVER_URL'
      UPDATE_NOTIFICATION_DISABLED_KEY = 'SPECKLE_IS_UPDATE_NOTIFICATION_DISABLED'
      DEFAULT_DUI_URL = 'https://dui.speckle.systems'
      DEFAULT_SERVER_URL = 'https://app.speckle.systems'
      ERROR_FILE_NOT_FOUND = 2

      def initialize(env: ENV, platform: nil, registry_reader: nil, warn: nil)
        @env = env
        @platform = platform
        @registry_reader = registry_reader || method(:win32_registry_value)
        @warn = warn || ->(message) { puts message }
      end

      def dui_url
        url_value(DUI_URL_KEY, DEFAULT_DUI_URL)
      end

      def default_speckle_server_url
        url_value(DEFAULT_SERVER_URL_KEY, DEFAULT_SERVER_URL)
      end

      def update_notification_disabled?
        bool_value(UPDATE_NOTIFICATION_DISABLED_KEY, false)
      end

      def to_h
        {
          isUpdateNotificationDisabled: update_notification_disabled?,
          defaultSpeckleServerUrl: default_speckle_server_url,
          duiUrl: dui_url
        }
      end

      private

      def config_value(key)
        value = present(@env[key])
        return value if value
        return nil unless platform == :windows

        present(@registry_reader.call(:hklm, key)) || present(@registry_reader.call(:hkcu, key))
      end

      def present(value)
        value = value.to_s.strip
        value.empty? ? nil : value
      end

      def platform
        @platform ||= begin
          require_relative '../constants/platform_constants'
          OPERATING_SYSTEM
        end
      end

      def url_value(key, default)
        value = config_value(key)
        return default unless value

        uri = URI.parse(value)
        return uri.to_s if uri.is_a?(URI::HTTP)

        log_warning("Failed to parse #{key} '#{value}'")
        default
      rescue URI::InvalidURIError
        log_warning("Failed to parse #{key} '#{value}'")
        default
      end

      def bool_value(key, default)
        value = config_value(key)
        return default unless value

        case value.downcase
        when 'true' then true
        when 'false' then false
        else
          log_warning("Failed to parse #{key} '#{value}'")
          default
        end
      end

      def win32_registry_value(hive, key)
        require 'win32/registry'
        root = hive == :hklm ? Win32::Registry::HKEY_LOCAL_MACHINE : Win32::Registry::HKEY_CURRENT_USER
        root.open(REGISTRY_PATH, Win32::Registry::KEY_READ) { |reg| reg[key].to_s }
      rescue LoadError => e
        log_warning("Failed to load win32/registry: #{e.message}")
        nil
      rescue Win32::Registry::Error => e
        # A missing key or value is the normal state of an unconfigured machine, not a warning
        log_warning("Failed to read #{hive} #{key}: #{e.message}") unless e.code == ERROR_FILE_NOT_FOUND
        nil
      rescue StandardError => e
        log_warning("Failed to read #{hive} #{key}: #{e.message}")
        nil
      end

      def log_warning(message)
        @warn.call(message)
      end
    end
  end
end
