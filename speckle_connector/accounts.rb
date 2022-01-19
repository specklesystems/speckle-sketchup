require "JSON"

begin
  require("sqlite3")
rescue LoadError
  # ty msp-greg! https://github.com/MSP-Greg/SUMisc/releases/tag/sqlite3-mingw-1
  Gem.install(File.join(File.dirname(File.expand_path(__FILE__)), "utils/sqlite3-1.4.2.mspgreg-x64-mingw32.gem"))
  require("sqlite3")
end

module SpeckleSystems::SpeckleConnector
  module Accounts
    def self.load_accounts
      dir = _get_speckle_dir
      db_path = File.join(dir, "Accounts.db")
      unless File.exist?(db_path)
        raise(IOError, "No Accounts db found. Please read the guide for different options for adding your account: \nhttps://speckle.guide/user/manager.html#adding-accounts")
      end

      db = SQLite3::Database.new(db_path)
      rows = db.execute("SELECT * FROM objects")
      db.close
      rows.map { |row| JSON.parse(row[1]) }
    end

    def self.get_suuid
      dir = _get_speckle_dir
      suuid_path = File.join(dir, "suuid")
      return unless File.exist?(suuid_path)

      File.read(suuid_path)
    end

    def self._get_speckle_dir
      speckle_dir =
        case Sketchup.platform
        # sometimes Dir.home on windows points somewhere else bc I guess it's picking up a higher level user?
        when :platform_win then File.join(Dir.pwd[%r{^((?:[^/]*/){3})}], "AppData/Roaming/Speckle")
        when :platform_osx then File.join(Dir.home, ".config", "Speckle")
        else
          nil
        end

      return speckle_dir if Dir.exist?(speckle_dir)

      raise(
        IOError,
        "No Speckle Directory exists. Please read the guide to get Speckle set up on your machine: \nhttps://speckle.guide/user/manager.html"
      )
    end
  end
end
