note
	description: "Tests for SIMPLE_SQL_SCHEMA and related info classes"
	testing: "type/manual"
	testing: "execution/serial"

class
	TEST_SIMPLE_SQL_SCHEMA

inherit
	TEST_SET_BASE

feature -- Test routines: Tables

	test_tables_list
			-- Test listing tables
		local
			l_db: SIMPLE_SQL_DATABASE
			l_schema: SIMPLE_SQL_SCHEMA
			l_tables: ARRAYED_LIST [STRING_8]
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE users (id INTEGER)")
			l_db.execute ("CREATE TABLE orders (id INTEGER)")

			create l_schema.make (l_db)
			l_tables := l_schema.tables

			assert_equal ("two_tables", 2, l_tables.count)
			assert_true ("has_users", l_tables.has ("users"))
			assert_true ("has_orders", l_tables.has ("orders"))

			l_db.close
		end

	test_table_exists
			-- Test table existence check
		local
			l_db: SIMPLE_SQL_DATABASE
			l_schema: SIMPLE_SQL_SCHEMA
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE users (id INTEGER)")

			create l_schema.make (l_db)

			assert_true ("exists", l_schema.table_exists ("users"))
			assert_false ("not_exists", l_schema.table_exists ("nonexistent"))

			l_db.close
		end

	test_views_list
			-- Test listing views
		local
			l_db: SIMPLE_SQL_DATABASE
			l_schema: SIMPLE_SQL_SCHEMA
			l_views: ARRAYED_LIST [STRING_8]
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE users (id INTEGER, active INTEGER)")
			l_db.execute ("CREATE VIEW active_users AS SELECT * FROM users WHERE active = 1")

			create l_schema.make (l_db)
			l_views := l_schema.views

			assert_equal ("one_view", 1, l_views.count)
			assert_true ("has_view", l_views.has ("active_users"))

			l_db.close
		end

feature -- Test routines: Columns

	test_column_names
			-- Test getting column names
		local
			l_db: SIMPLE_SQL_DATABASE
			l_schema: SIMPLE_SQL_SCHEMA
			l_columns: ARRAYED_LIST [STRING_8]
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE users (id INTEGER, name TEXT, age INTEGER)")

			create l_schema.make (l_db)
			l_columns := l_schema.column_names ("users")

			assert_equal ("three_columns", 3, l_columns.count)
			assert_true ("has_id", l_columns.has ("id"))
			assert_true ("has_name", l_columns.has ("name"))
			assert_true ("has_age", l_columns.has ("age"))

			l_db.close
		end

	test_columns_info
			-- Test getting detailed column info
		local
			l_db: SIMPLE_SQL_DATABASE
			l_schema: SIMPLE_SQL_SCHEMA
			l_columns: ARRAYED_LIST [SIMPLE_SQL_COLUMN_INFO]
			l_col: SIMPLE_SQL_COLUMN_INFO
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL, age INTEGER DEFAULT 0)")

			create l_schema.make (l_db)
			l_columns := l_schema.columns ("users")

			assert_equal ("three_columns", 3, l_columns.count)

			-- Check id column
			l_col := l_columns [1]
			assert_strings_equal ("id_name", "id", l_col.name)
			assert_true ("id_is_pk", l_col.is_primary_key)

			-- Check name column
			l_col := l_columns [2]
			assert_strings_equal ("name_name", "name", l_col.name)
			assert_true ("name_not_null", l_col.is_not_null)

			-- Check age column
			l_col := l_columns [3]
			assert_strings_equal ("age_name", "age", l_col.name)
			assert_true ("age_has_default", l_col.has_default)

			l_db.close
		end

feature -- Test routines: Table Info

	test_table_info
			-- Test getting full table info
		local
			l_db: SIMPLE_SQL_DATABASE
			l_schema: SIMPLE_SQL_SCHEMA
			l_info: detachable SIMPLE_SQL_TABLE_INFO
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)")
			l_db.execute ("CREATE INDEX idx_name ON users (name)")

			create l_schema.make (l_db)
			l_info := l_schema.table_info ("users")

			if attached l_info as l_i then
				assert_strings_equal ("name", "users", l_i.name)
				assert_strings_equal ("type", "table", l_i.table_type)
				assert_equal ("col_count", 2, l_i.column_count)
				assert_false ("indexes_empty", l_i.indexes.is_empty)
			else
				assert_true ("info_attached", False)
			end

			l_db.close
		end

feature -- Test routines: Indexes

	test_indexes
			-- Test getting index information
		local
			l_db: SIMPLE_SQL_DATABASE
			l_schema: SIMPLE_SQL_SCHEMA
			l_indexes: ARRAYED_LIST [SIMPLE_SQL_INDEX_INFO]
			l_idx: SIMPLE_SQL_INDEX_INFO
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE users (id INTEGER, name TEXT, email TEXT)")
			l_db.execute ("CREATE INDEX idx_name ON users (name)")
			l_db.execute ("CREATE UNIQUE INDEX idx_email ON users (email)")

			create l_schema.make (l_db)
			l_indexes := l_schema.indexes ("users")

			assert_equal ("two_indexes", 2, l_indexes.count)

			-- Find unique index
			across l_indexes as ic loop
				if ic.name.same_string ("idx_email") then
					l_idx := ic
				end
			end
			if attached l_idx then
				assert_true ("is_unique", l_idx.is_unique)
			end

			l_db.close
		end

feature -- Test routines: Foreign Keys

	test_foreign_keys
			-- Test getting foreign key information
		local
			l_db: SIMPLE_SQL_DATABASE
			l_schema: SIMPLE_SQL_SCHEMA
			l_fks: ARRAYED_LIST [SIMPLE_SQL_FOREIGN_KEY_INFO]
			l_fk: SIMPLE_SQL_FOREIGN_KEY_INFO
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE users (id INTEGER PRIMARY KEY)")
			l_db.execute ("CREATE TABLE orders (id INTEGER PRIMARY KEY, user_id INTEGER REFERENCES users(id) ON DELETE CASCADE)")

			create l_schema.make (l_db)
			l_fks := l_schema.foreign_keys ("orders")

			assert_equal ("one_fk", 1, l_fks.count)

			l_fk := l_fks.first
			assert_strings_equal ("ref_table", "users", l_fk.to_table)
			assert_strings_equal ("on_delete", "CASCADE", l_fk.on_delete)

			l_db.close
		end

feature -- Test routines: User Version

	test_user_version
			-- Test getting and setting user_version
		local
			l_db: SIMPLE_SQL_DATABASE
			l_schema: SIMPLE_SQL_SCHEMA
		do
			create l_db.make_memory

			create l_schema.make (l_db)

			assert_equal ("initial_zero", 0, l_schema.user_version)

			l_schema.set_user_version (5)
			assert_equal ("after_set", 5, l_schema.user_version)

			l_schema.set_user_version (10)
			assert_equal ("after_set_again", 10, l_schema.user_version)

			l_db.close
		end

	test_schema_version
			-- Test getting schema_version
		local
			l_db: SIMPLE_SQL_DATABASE
			l_schema: SIMPLE_SQL_SCHEMA
			l_initial, l_after: INTEGER
		do
			create l_db.make_memory

			create l_schema.make (l_db)
			l_initial := l_schema.schema_version

			l_db.execute ("CREATE TABLE test (id INTEGER)")
			l_after := l_schema.schema_version

			-- Schema version should increment after schema change
			assert_true ("version_changed", l_after > l_initial)

			l_db.close
		end

feature -- Test routines: Column Info Details

	test_column_info_description
			-- Test column info description generation
		local
			l_db: SIMPLE_SQL_DATABASE
			l_schema: SIMPLE_SQL_SCHEMA
			l_columns: ARRAYED_LIST [SIMPLE_SQL_COLUMN_INFO]
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT NOT NULL)")

			create l_schema.make (l_db)
			l_columns := l_schema.columns ("test")

			-- Check that description contains key info
			assert_string_contains ("pk_in_desc", l_columns [1].description, "PRIMARY KEY")
			assert_string_contains ("notnull_in_desc", l_columns [2].description, "NOT NULL")

			l_db.close
		end

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
