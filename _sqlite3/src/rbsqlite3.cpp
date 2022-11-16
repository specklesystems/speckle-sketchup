#include "Database.h"
#include "RubyUtils/RubyUtils.h"
#include "ruby.h"

VALUE ruby_platform() {
	return GetRubyInterface(RUBY_PLATFORM);
}

// Load this module from Ruby using:
//   require 'Sqlite3'
extern "C" {
	// Proof of concept to test it on Sketchup. Call;
	//  SpeckleConnector::Sqlite.greetings!
	static VALUE hi_from_c_sqlite3() {
		char message[] = "hi from c sqlite3!";
		VALUE str_val = rb_str_new2(message);
		return str_val;
	}

	static void rbsqlite3_free(void* ptr) {
		delete (SQLite::Database*)ptr;
	}

	static VALUE rbsqlite3_new(VALUE klass, VALUE pathValue) {
		VALUE argv[1];
		const char* path = "C:/Users/sotas/AppData/Roaming/Speckle/Accounts.db";
		SQLite::Database* database = new SQLite::Database(path);
		VALUE obj = Data_Wrap_Struct(klass, 0, rbsqlite3_free, database);
		argv[0] = pathValue;

		rb_obj_call_init(obj, 1, argv);
		rb_iv_set(obj, "@path", pathValue);
		return obj;
	}

	static VALUE rbsqlite3_new2(VALUE klass) {
		const char* path = "C:/Users/sotas/AppData/Roaming/Speckle/Accounts.db";
		SQLite::Database* database = new SQLite::Database(path);
		VALUE obj = Data_Wrap_Struct(klass, 0, rbsqlite3_free, database);
		rb_obj_call_init(obj, 0, 0);
		return obj;
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
	rb_define_singleton_method(speckle_connector_sqlite3, "greetings!", (ruby_method)hi_from_c_sqlite3, 0);

	rb_define_singleton_method(speckle_connector_sqlite3_database, "new", (ruby_method)rbsqlite3_new, 1);
	rb_define_singleton_method(speckle_connector_sqlite3_database, "new2", (ruby_method)rbsqlite3_new2, 0);

	rb_define_method(speckle_connector_sqlite3_database, "close", (ruby_method)rbsqlite3_free, 0);
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