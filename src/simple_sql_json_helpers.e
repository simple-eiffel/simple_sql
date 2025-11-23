note
	description: "[
		Helper utilities for storing and retrieving JSON data in SQLite.
		Demonstrates two approaches:
		1. TEXT column with SQLite's json functions
		2. BLOB column with SIMPLE_JSON serialization
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_JSON_HELPERS

feature -- JSON as TEXT (SQLite native)

	create_json_text_table (a_db: SIMPLE_SQL_DATABASE; a_table_name: STRING_8)
			-- Create table with JSON TEXT column
		require
			db_attached: a_db /= Void
			db_open: a_db.is_open
			table_name_not_empty: not a_table_name.is_empty
		local
			l_sql: STRING_8
		do
			create l_sql.make_from_string ("CREATE TABLE ")
			l_sql.append (a_table_name)
			l_sql.append (" (id INTEGER PRIMARY KEY, json_data TEXT)")
			a_db.execute (l_sql)
		end

	insert_json_text (a_db: SIMPLE_SQL_DATABASE; a_table_name: STRING_8; a_json_string: STRING_8)
			-- Insert JSON as TEXT
		require
			db_attached: a_db /= Void
			db_open: a_db.is_open
			table_name_not_empty: not a_table_name.is_empty
			json_not_empty: not a_json_string.is_empty
		local
			l_sql: STRING_8
		do
			create l_sql.make_from_string ("INSERT INTO ")
			l_sql.append (a_table_name)
			l_sql.append (" (json_data) VALUES ('")
			l_sql.append (escape_json_string (a_json_string))
			l_sql.append ("')")
			a_db.execute (l_sql)
		end

	query_json_path (a_db: SIMPLE_SQL_DATABASE; a_table_name: STRING_8; a_json_path: STRING_8): SIMPLE_SQL_RESULT
			-- Query JSON using json_extract path syntax
			-- Example: a_json_path = "$.user.name"
		require
			db_attached: a_db /= Void
			db_open: a_db.is_open
			table_name_not_empty: not a_table_name.is_empty
			path_not_empty: not a_json_path.is_empty
		local
			l_sql: STRING_8
		do
			create l_sql.make_from_string ("SELECT json_extract(json_data, '")
			l_sql.append (a_json_path)
			l_sql.append ("') as value FROM ")
			l_sql.append (a_table_name)
			Result := a_db.query (l_sql)
		end

feature -- JSON as BLOB (SIMPLE_JSON)

	create_json_blob_table (a_db: SIMPLE_SQL_DATABASE; a_table_name: STRING_8)
			-- Create table with JSON BLOB column
		require
			db_attached: a_db /= Void
			db_open: a_db.is_open
			table_name_not_empty: not a_table_name.is_empty
		local
			l_sql: STRING_8
		do
			create l_sql.make_from_string ("CREATE TABLE ")
			l_sql.append (a_table_name)
			l_sql.append (" (id INTEGER PRIMARY KEY, json_blob BLOB)")
			a_db.execute (l_sql)
		end

feature {NONE} -- Implementation

	escape_json_string (a_json: STRING_8): STRING_8
			-- Escape single quotes in JSON string for SQL
		local
			i: INTEGER
		do
			create Result.make (a_json.count)
			from
				i := 1
			until
				i > a_json.count
			loop
				if a_json [i] = '%'' then
					Result.append_character ('%'')
					Result.append_character ('%'')
				else
					Result.append_character (a_json [i])
				end
				i := i + 1
			end
		end

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		SIMPLE_SQL - High-level SQLite API for Eiffel
		Demonstrates both TEXT (json functions) and BLOB (SIMPLE_JSON) approaches
	]"

end
