# frozen_string_literal: true

require_relative '../constants/platform_constants'

module SpeckleConnector3
  extension = if OPERATING_SYSTEM == OS_WIN
                'so'
              else
                'bundle'
              end
  sqlite3_file = "sqlite3_#{RUBY_VERSION_NUMBER}.#{extension}"
  require_relative(File.join('sqlite3', sqlite3_file))
end
