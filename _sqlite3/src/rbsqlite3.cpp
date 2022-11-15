#include "RubyUtils/RubyUtils.h"

VALUE ruby_platform() {
	return GetRubyInterface(RUBY_PLATFORM);
}

// Load this module from Ruby using:
//   require 'Sqlite3'
extern "C"

void Init_sqlite3()
{
	VALUE Sqlite3 = rb_define_module("Sqlite3");
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