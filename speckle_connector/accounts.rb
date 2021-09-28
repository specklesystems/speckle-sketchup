require "JSON"

begin
  require "sqlite3"
rescue LoadError
  Gem::install(File.join(File.dirname(File.expand_path(__FILE__)), "utils/sqlite3-1.4.2.mspgreg-x64-mingw32.gem"))
  else
    require "sqlite3"
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

    def self._get_speckle_dir
      platform = RUBY_PLATFORM.downcase

      speckle_dir =
        if platform =~ (/mingw/) || platform =~ (/win/)
          # win
          File.join(Dir.home, "AppData/Roaming/Speckle")
        elsif platform =~ /linux/
          # linux
          File.expand_path("~/.local/share/Speckle")
        else
          # mac
          File.expand_path("~/.config/Speckle")
        end
      return speckle_dir if Dir.exist?(speckle_dir)

      raise(IOError, "No Speckle Directory exists. Please read the guide to get Speckle set up on your machine: \nhttps://speckle.guide/user/manager.html")
    end
  end
end
