# frozen_string_literal: true

require_relative '../constants/platform_constants'

# Loads the per-ABI native DuckDB extension (built from the `_duckdb` submodule),
# the same way ext/sqlite3.rb loads sqlite. The compiled libs live next to this file
# at ext/duckdb/duckdb_<ruby_abi>.<so|bundle>. Absent (not built) -> LoadError, which
# the receive path treats as "fall back to the pure-Ruby reader".
module SpeckleConnector3
  extension = OPERATING_SYSTEM == OS_WIN ? 'so' : 'bundle'
  duckdb_dir = File.expand_path('duckdb', File.dirname(__FILE__))

  if OPERATING_SYSTEM == OS_WIN
    # duckdb_<abi>.so dynamically depends on duckdb.dll, which sits right beside it —
    # but Windows resolves a dependent DLL via the EXE dir / PATH, NOT the folder of
    # the module being loaded. So make duckdb.dll resolvable before requiring the ext:
    # pre-load it by full path (most reliable) and also prepend its dir to PATH.
    dll = File.join(duckdb_dir, 'duckdb.dll')
    if File.exist?(dll)
      begin
        require 'fiddle'
        Fiddle.dlopen(dll)
      rescue StandardError => e
        warn("Speckle: could not preload duckdb.dll (#{e.message})")
      end
      win_dir = duckdb_dir.tr('/', '\\')
      ENV['PATH'] = "#{win_dir};#{ENV['PATH']}" unless ENV['PATH'].to_s.include?(win_dir)
    end
  end

  duckdb_file = "duckdb_#{RUBY_VERSION_NUMBER}.#{extension}"
  require_relative(File.join('duckdb', duckdb_file))
end
