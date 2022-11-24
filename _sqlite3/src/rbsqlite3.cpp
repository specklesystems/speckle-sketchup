#include "Database.h"
#include "RubyUtils/RubyUtils.h"
#include "ruby.h"
#include "sqlite3.h"

VALUE
rbsqlite3_new(VALUE klass, VALUE pathValue)
{
	// Arguments array 
	VALUE argv[1];

	// Convert pathValue to actual path string
	const char* path;
	path = StringValuePtr(pathValue);

	SQLite::Database* db = new SQLite::Database(path);

	VALUE obj = Data_Wrap_Struct(klass, NULL, NULL, db);
	rb_iv_set(obj, "@path", rb_str_new2(path));
	return obj;
}

VALUE
rbsqlite3_table_exist(VALUE klass, VALUE tableNameValue) {
	// Convert pathValue to actual path string
	const char* tableName;
	tableName = StringValuePtr(tableNameValue);

	SQLite::Database* database;
	Data_Get_Struct(klass, SQLite::Database, database);

	bool val = database->tableExists(tableName);
	return val ? Qtrue : Qfalse;
}

VALUE
rbsqlite3_exec(VALUE klass, VALUE execValue) {
	VALUE rows = rb_ary_new();

	// Convert pathValue to actual path string
	const char* query;
	query = StringValuePtr(execValue);

	SQLite::Database* database;
	Data_Get_Struct(klass, SQLite::Database, database);

	VALUE val = database->exec(query);
	return val;
}

VALUE ruby_platform() {
	return GetRubyInterface(RUBY_PLATFORM);
}

// Load this module from Ruby using:
//   require 'Sqlite3'
extern "C" {
	static int hash_callback_function(VALUE callback_ary, int count, char** data, char** columns)
	{
		VALUE new_hash = rb_hash_new();
		int i;

		for (i = 0; i < count; i++) {
			if (data[i] == NULL) {
				rb_hash_aset(new_hash, rb_str_new_cstr(columns[i]), Qnil);
			}
			else {
				rb_hash_aset(new_hash, rb_str_new_cstr(columns[i]), rb_str_new_cstr(data[i]));
			}
		}

		rb_ary_push(callback_ary, new_hash);

		return 0;
	}

	static int regular_callback_function(VALUE callback_ary, int count, char** data, char** columns)
	{
		VALUE new_ary = rb_ary_new();
		int i;

		for (i = 0; i < count; i++) {
			if (data[i] == NULL) {
				rb_ary_push(new_ary, Qnil);
			}
			else {
				rb_ary_push(new_ary, rb_str_new_cstr(data[i]));
			}
		}

		rb_ary_push(callback_ary, new_ary);

		return 0;
	}

	/* Is invoked by calling db.execute_batch2(sql, &block)
	*
	* Executes all statements in a given string separated by semicolons.
	* If a query is made, all values returned are strings
	* (except for 'NULL' values which return nil),
	* so the user may parse values with a block.
	* If no query is made, an empty array will be returned.
	*/
	static VALUE rbsqlite3_exec_batch(VALUE self, VALUE sql, VALUE results_as_hash)
	{
		SQLite::Database* db;
		int status;
		VALUE callback_ary = rb_ary_new();
		char* errMsg;
		VALUE errexp;

		Data_Get_Struct(self, SQLite::Database, db);
		if (!db->getHandle()) \
			rb_raise(rb_path2class("SQLite3::Exception"), "cannot use a closed database");

		status = sqlite3_exec(db->getHandle(), StringValuePtr(sql), (sqlite3_callback)regular_callback_function, (void*)callback_ary, &errMsg);
		
		if (status != SQLITE_OK)
		{
			errexp = rb_exc_new2(rb_eRuntimeError, errMsg);
			sqlite3_free(errMsg);
			rb_exc_raise(errexp);
		}

		return callback_ary;
	}

	static void rbsqlite3_free(void* ptr) {
		delete (SQLite::Database*)ptr;
	}

	/* call-seq: db.close
	*
	* Closes this database.
	*/
	static VALUE rbsqlite3_close(VALUE self)
	{
		SQLite::Database* database;
		Data_Get_Struct(self, SQLite::Database, database);
		sqlite3_close(database->getHandle());
		rb_iv_set(self, "-aggregators", Qnil);
		return self;
	}
}


typedef VALUE(*ruby_method)(...);
void Init_sqlite3()
{
	// Init modules
	VALUE speckle_connector = rb_define_module("SpeckleConnector");
	VALUE speckle_connector_sqlite3 = rb_define_class_under(speckle_connector, "Sqlite3", rb_cObject);
	VALUE speckle_connector_sqlite3_database = rb_define_class_under(speckle_connector_sqlite3, "Database", rb_cObject);

	rb_define_singleton_method(speckle_connector_sqlite3, "ruby_platform", (ruby_method)ruby_platform, 0);
	rb_define_singleton_method(speckle_connector_sqlite3_database, "new", (ruby_method)rbsqlite3_new, 1);

	rb_define_method(speckle_connector_sqlite3_database, "close", (ruby_method)rbsqlite3_close, 0);
	rb_define_method(speckle_connector_sqlite3_database, "exec", (ruby_method)rbsqlite3_exec_batch, 1);
	rb_define_method(speckle_connector_sqlite3_database, "table_exist?", (ruby_method)rbsqlite3_table_exist, 1);
}

void Init_sqlite3_20()
{
	Init_sqlite3();
}

void Init_sqlite3_22()
{
	Init_sqlite3();
}

void Init_sqlite3_25()
{
	Init_sqlite3();
}

void Init_sqlite3_27()
{
	Init_sqlite3();
}