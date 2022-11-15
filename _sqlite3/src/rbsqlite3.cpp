#include "sqlite3.h"
#include "RubyUtils/RubyUtils.h"

VALUE ruby_platform() {
	return GetRubyInterface(RUBY_PLATFORM);
}

// Load this module from Ruby using:
//   require 'Sqlite3'
extern "C" {
	static void rbsqlite3_free(void* ptr) {
		delete (sqlite3*)ptr;
	}

	static VALUE rbsqlite3_new(VALUE klass, const char* path) {
		sqlite3** db{};
		int ptr = sqlite3_open(path, db);
		VALUE r = Data_Wrap_Struct(klass, 0, rbsqlite3_free, db);
		rb_obj_call_init(r, 0, 0);
		rb_iv_set(r, "@multiplier", INT2NUM(1048576));
		return r;
	}

	static VALUE hi_from_c_sqlite3() {
		char message[] = "hi from c sqlite3!";
		VALUE str_val = rb_str_new2(message);
		return str_val;
	}
}


typedef VALUE(*ruby_method)(...);
void Init_sqlite3()
{
	// Init modules
	VALUE speckle_connector = rb_define_module("SpeckleConnector");
	VALUE speckle_connector_sqlite3 = rb_define_class_under(speckle_connector, "Sqlite3", rb_cObject);

	rb_define_singleton_method(speckle_connector_sqlite3, "new", (ruby_method)rbsqlite3_new, 0);
	rb_define_singleton_method(speckle_connector_sqlite3, "ruby_platform", (ruby_method)ruby_platform, 0);
	rb_define_singleton_method(speckle_connector_sqlite3, "greetings!", (ruby_method)hi_from_c_sqlite3, 0);
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