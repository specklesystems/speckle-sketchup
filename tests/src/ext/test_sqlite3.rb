# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../speckle_connector/src/ext/sqlite3'
require_relative '../../../speckle_connector/src/constants/path_constants'

module SpeckleConnector
  class Sqlite3Test < Minitest::Test
    TABLE_NAME = "sketchup_test"
    TABLE_COLUMNS = "(hash TEXT PRIMARY KEY NOT NULL, content TEXT NOT NULL);"
    INSERT_DATA = "('oguzhan', 'koral');"
    INSERT_DATA_2 = "('oguzhan', 'koral2');"

    def setup
      # Do nothing
    end

    def teardown
      # Do nothing
    end

    def test_table_exists
      db_path = SPECKLE_TEST_DB_PATH

      db = Sqlite3::Database.new(db_path)
      exists = db.table_exist?('objects')
      db.close
      assert_equal(exists, false)
    end

    def test_create_table
      # Init file and close it
      test_database_file = File.new(SPECKLE_TEST_DB_PATH, "w")
      test_database_file.close

      # Init sqlite database and create table
      db = Sqlite3::Database.new(test_database_file.path)
      db.exec("CREATE TABLE #{TABLE_NAME} #{TABLE_COLUMNS}")
      exists = db.table_exist?(TABLE_NAME)
      db.close

      # Assert
      assert_equal(exists, true)

      # Delete test database file
      File.delete(test_database_file.path) if File.exist?(test_database_file.path)
    end

    def test_insert_to_table
      # Init file and close it
      test_database_file = File.new(SPECKLE_TEST_DB_PATH, "w")
      test_database_file.close

      # Init sqlite database
      db = Sqlite3::Database.new(test_database_file.path)

      # Create table
      db.exec("CREATE TABLE #{TABLE_NAME} #{TABLE_COLUMNS}")

      # Insert data
      db.exec("INSERT INTO #{TABLE_NAME} VALUES #{INSERT_DATA}")

      # Select data
      data = db.exec("SELECT content FROM #{TABLE_NAME} WHERE hash = 'oguzhan'")

      # Close database
      db.close

      assert_equal(data, [["koral"]])

      # Delete test database file
      File.delete(test_database_file.path) if File.exist?(test_database_file.path)
    end

    def test_update_value
      # Init file and close it
      test_database_file = File.new(SPECKLE_TEST_DB_PATH, "w")
      test_database_file.close

      # Init sqlite database
      db = Sqlite3::Database.new(test_database_file.path)

      # Create table
      db.exec("CREATE TABLE #{TABLE_NAME} #{TABLE_COLUMNS}")

      # Insert data
      db.exec("INSERT INTO #{TABLE_NAME} VALUES #{INSERT_DATA}")

      # Update data
      db.exec("UPDATE #{TABLE_NAME} SET content = 'updated_koral' WHERE hash = 'oguzhan'")

      # Select data
      data = db.exec("SELECT content FROM #{TABLE_NAME} WHERE hash = 'oguzhan'")

      # Close database
      db.close

      assert_equal(data, [["updated_koral"]])

      # Delete test database file
      File.delete(test_database_file.path) if File.exist?(test_database_file.path)
    end
  end
end