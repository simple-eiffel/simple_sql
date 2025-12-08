note
	description: "[
		Advanced JSON support using SQLite's JSON1 extension.
		Provides validation, path queries, aggregation, and modification.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_JSON

create
	make

feature {NONE} -- Initialization

	make (a_database: SIMPLE_SQL_DATABASE)
			-- Initialize with database connection
		require
			database_not_void: a_database /= Void
			database_open: a_database.is_open
		do
			database := a_database
		ensure
			database_set: database = a_database
		end

feature -- Access

	database: SIMPLE_SQL_DATABASE
			-- Database connection

feature -- Status report

	is_valid_json (a_json: STRING_8): BOOLEAN
			-- Is string valid JSON?
		require
			json_not_empty: not a_json.is_empty
		local
			l_result: SIMPLE_SQL_RESULT
			l_stmt: SIMPLE_SQL_PREPARED_STATEMENT
		do
			l_stmt := database.prepare ("SELECT json_valid(?)")
			l_stmt.bind_text (1, a_json)
			l_result := l_stmt.execute_returning_result
			if not l_result.is_empty and then attached l_result.first.item (1) as l_val then
				if attached {INTEGER_64} l_val as l_int then
					Result := l_int /= 0
				end
			end
		end

	json_type (a_json: STRING_8; a_path: detachable STRING_8): detachable STRING_32
			-- Get JSON type at path (null, true, false, integer, real, text, array, object)
			-- If a_path is Void, checks root type
		require
			json_not_empty: not a_json.is_empty
		local
			l_result: SIMPLE_SQL_RESULT
			l_stmt: SIMPLE_SQL_PREPARED_STATEMENT
			l_sql: STRING_8
		do
			if a_path = Void then
				create l_sql.make_from_string ("SELECT json_type(?)")
			else
				create l_sql.make_from_string ("SELECT json_type(?, ?)")
			end
			l_stmt := database.prepare (l_sql)
			l_stmt.bind_text (1, a_json)
			if a_path /= Void then
				l_stmt.bind_text (2, a_path)
			end
			l_result := l_stmt.execute_returning_result
			if not l_result.is_empty then
				if attached l_result.first.item (1) as l_val then
					Result := l_val.out.to_string_32
				end
			end
		end

feature -- JSON Path Queries

	extract (a_json: STRING_8; a_path: STRING_8): detachable STRING_32
			-- Extract value at JSON path
			-- Example: extract('{"user":{"name":"Alice"}}', '$.user.name') => "Alice"
		require
			json_not_empty: not a_json.is_empty
			path_not_empty: not a_path.is_empty
		local
			l_result: SIMPLE_SQL_RESULT
			l_stmt: SIMPLE_SQL_PREPARED_STATEMENT
		do
			l_stmt := database.prepare ("SELECT json_extract(?, ?)")
			l_stmt.bind_text (1, a_json)
			l_stmt.bind_text (2, a_path)
			l_result := l_stmt.execute_returning_result
			if not l_result.is_empty and then attached l_result.first.item (1) as l_val then
				Result := l_val.out.to_string_32
			end
		end

	extract_multiple (a_json: STRING_8; a_paths: ARRAY [STRING_8]): SIMPLE_SQL_RESULT
			-- Extract multiple paths at once
			-- Returns result with columns for each path
		require
			json_not_empty: not a_json.is_empty
			paths_not_empty: not a_paths.is_empty
		local
			l_sql: STRING_8
			l_stmt: SIMPLE_SQL_PREPARED_STATEMENT
			i: INTEGER
		do
			create l_sql.make_from_string ("SELECT ")
			from i := a_paths.lower until i > a_paths.upper loop
				if i > a_paths.lower then
					l_sql.append (", ")
				end
				l_sql.append ("json_extract(?, '")
				l_sql.append (a_paths [i])
				l_sql.append ("')")
				i := i + 1
			end
			l_stmt := database.prepare (l_sql)
			l_stmt.bind_text (1, a_json)
			Result := l_stmt.execute_returning_result
		end

feature -- JSON Modification

	json_set (a_json: STRING_8; a_path: STRING_8; a_value: detachable ANY): STRING_8
			-- Set value at path, creating parent structures if needed
			-- Example: json_set('{"a":1}', '$.b', 2) => '{"a":1,"b":2}'
		require
			json_not_empty: not a_json.is_empty
			path_not_empty: not a_path.is_empty
		local
			l_result: SIMPLE_SQL_RESULT
			l_stmt: SIMPLE_SQL_PREPARED_STATEMENT
		do
			l_stmt := database.prepare ("SELECT json_set(?, ?, ?)")
			l_stmt.bind_text (1, a_json)
			l_stmt.bind_text (2, a_path)
			bind_json_value (l_stmt, 3, a_value)
			l_result := l_stmt.execute_returning_result
			if not l_result.is_empty and then attached l_result.first.item (1) as l_val then
				Result := l_val.out.to_string_8
			else
				Result := a_json
			end
		ensure
			result_not_empty: not Result.is_empty
		end

	json_insert (a_json: STRING_8; a_path: STRING_8; a_value: detachable ANY): STRING_8
			-- Insert value at path (only if path doesn't exist)
			-- Example: json_insert('{"a":1}', '$.b', 2) => '{"a":1,"b":2}'
			-- Example: json_insert('{"a":1}', '$.a', 2) => '{"a":1}' (no change)
		require
			json_not_empty: not a_json.is_empty
			path_not_empty: not a_path.is_empty
		local
			l_result: SIMPLE_SQL_RESULT
			l_stmt: SIMPLE_SQL_PREPARED_STATEMENT
		do
			l_stmt := database.prepare ("SELECT json_insert(?, ?, ?)")
			l_stmt.bind_text (1, a_json)
			l_stmt.bind_text (2, a_path)
			bind_json_value (l_stmt, 3, a_value)
			l_result := l_stmt.execute_returning_result
			if not l_result.is_empty and then attached l_result.first.item (1) as l_val then
				Result := l_val.out.to_string_8
			else
				Result := a_json
			end
		ensure
			result_not_empty: not Result.is_empty
		end

	json_replace (a_json: STRING_8; a_path: STRING_8; a_value: detachable ANY): STRING_8
			-- Replace value at path (only if path exists)
			-- Example: json_replace('{"a":1}', '$.a', 2) => '{"a":2}'
			-- Example: json_replace('{"a":1}', '$.b', 2) => '{"a":1}' (no change)
		require
			json_not_empty: not a_json.is_empty
			path_not_empty: not a_path.is_empty
		local
			l_result: SIMPLE_SQL_RESULT
			l_stmt: SIMPLE_SQL_PREPARED_STATEMENT
		do
			l_stmt := database.prepare ("SELECT json_replace(?, ?, ?)")
			l_stmt.bind_text (1, a_json)
			l_stmt.bind_text (2, a_path)
			bind_json_value (l_stmt, 3, a_value)
			l_result := l_stmt.execute_returning_result
			if not l_result.is_empty and then attached l_result.first.item (1) as l_val then
				Result := l_val.out.to_string_8
			else
				Result := a_json
			end
		ensure
			result_not_empty: not Result.is_empty
		end

	json_remove (a_json: STRING_8; a_path: STRING_8): STRING_8
			-- Remove value at path
			-- Example: json_remove('{"a":1,"b":2}', '$.b') => '{"a":1}'
		require
			json_not_empty: not a_json.is_empty
			path_not_empty: not a_path.is_empty
		local
			l_result: SIMPLE_SQL_RESULT
			l_stmt: SIMPLE_SQL_PREPARED_STATEMENT
		do
			l_stmt := database.prepare ("SELECT json_remove(?, ?)")
			l_stmt.bind_text (1, a_json)
			l_stmt.bind_text (2, a_path)
			l_result := l_stmt.execute_returning_result
			if not l_result.is_empty and then attached l_result.first.item (1) as l_val then
				Result := l_val.out.to_string_8
			else
				Result := a_json
			end
		ensure
			result_not_empty: not Result.is_empty
		end

feature -- JSON Creation

	json_array_from_values (a_values: ARRAY [detachable ANY]): STRING_8
			-- Create JSON array from Eiffel values
			-- Example: json_array_from_values(<<1, "two", 3.0>>) => '[1,"two",3.0]'
		require
			values_not_empty: not a_values.is_empty
		local
			l_sql: STRING_8
			l_stmt: SIMPLE_SQL_PREPARED_STATEMENT
			l_result: SIMPLE_SQL_RESULT
			i: INTEGER
		do
			create l_sql.make_from_string ("SELECT json_array(")
			from i := a_values.lower until i > a_values.upper loop
				if i > a_values.lower then
					l_sql.append (", ")
				end
				l_sql.append ("?")
				i := i + 1
			end
			l_sql.append (")")

			l_stmt := database.prepare (l_sql)
			from i := a_values.lower until i > a_values.upper loop
				bind_json_value (l_stmt, i - a_values.lower + 1, a_values [i])
				i := i + 1
			end

			l_result := l_stmt.execute_returning_result
			if not l_result.is_empty and then attached l_result.first.item (1) as l_val then
				Result := l_val.out.to_string_8
			else
				Result := "[]"
			end
		ensure
			result_not_empty: not Result.is_empty
		end

	json_object_from_pairs (a_pairs: ARRAY [TUPLE [key: STRING_8; value: detachable ANY]]): STRING_8
			-- Create JSON object from key-value pairs
			-- Example: json_object_from_pairs(<<["name", "Alice"], ["age", 30]>>) => '{"name":"Alice","age":30}'
		require
			pairs_not_empty: not a_pairs.is_empty
		local
			l_sql: STRING_8
			l_stmt: SIMPLE_SQL_PREPARED_STATEMENT
			l_result: SIMPLE_SQL_RESULT
			i, l_param_index: INTEGER
		do
			create l_sql.make_from_string ("SELECT json_object(")
			from i := a_pairs.lower until i > a_pairs.upper loop
				if i > a_pairs.lower then
					l_sql.append (", ")
				end
				l_sql.append ("?, ?")
				i := i + 1
			end
			l_sql.append (")")

			l_stmt := database.prepare (l_sql)
			l_param_index := 1
			from i := a_pairs.lower until i > a_pairs.upper loop
				l_stmt.bind_text (l_param_index, a_pairs [i].key)
				l_param_index := l_param_index + 1
				bind_json_value (l_stmt, l_param_index, a_pairs [i].value)
				l_param_index := l_param_index + 1
				i := i + 1
			end

			l_result := l_stmt.execute_returning_result
			if not l_result.is_empty and then attached l_result.first.item (1) as l_val then
				Result := l_val.out.to_string_8
			else
				Result := "{}"
			end
		ensure
			result_not_empty: not Result.is_empty
		end

feature -- JSON Aggregation

	aggregate_to_array (a_table: STRING_8; a_column: STRING_8; a_where: detachable STRING_8): STRING_8
			-- Aggregate column values into JSON array
			-- Example: aggregate_to_array("users", "name", "age > 18") => '["Alice","Bob","Charlie"]'
		require
			table_not_empty: not a_table.is_empty
			column_not_empty: not a_column.is_empty
		local
			l_sql: STRING_8
			l_result: SIMPLE_SQL_RESULT
		do
			create l_sql.make_from_string ("SELECT json_group_array(")
			l_sql.append (a_column)
			l_sql.append (") FROM ")
			l_sql.append (a_table)
			if a_where /= Void and then not a_where.is_empty then
				l_sql.append (" WHERE ")
				l_sql.append (a_where)
			end

			l_result := database.query (l_sql)
			if not l_result.is_empty and then attached l_result.first.item (1) as l_val then
				Result := l_val.out.to_string_8
			else
				Result := "[]"
			end
		ensure
			result_not_empty: not Result.is_empty
		end

	aggregate_to_object (a_table: STRING_8; a_key_column: STRING_8; a_value_column: STRING_8; a_where: detachable STRING_8): STRING_8
			-- Aggregate key-value pairs into JSON object
			-- Example: aggregate_to_object("settings", "key", "value", Void) => '{"theme":"dark","lang":"en"}'
		require
			table_not_empty: not a_table.is_empty
			key_column_not_empty: not a_key_column.is_empty
			value_column_not_empty: not a_value_column.is_empty
		local
			l_sql: STRING_8
			l_result: SIMPLE_SQL_RESULT
		do
			create l_sql.make_from_string ("SELECT json_group_object(")
			l_sql.append (a_key_column)
			l_sql.append (", ")
			l_sql.append (a_value_column)
			l_sql.append (") FROM ")
			l_sql.append (a_table)
			if a_where /= Void and then not a_where.is_empty then
				l_sql.append (" WHERE ")
				l_sql.append (a_where)
			end

			l_result := database.query (l_sql)
			if not l_result.is_empty and then attached l_result.first.item (1) as l_val then
				Result := l_val.out.to_string_8
			else
				Result := "{}"
			end
		ensure
			result_not_empty: not Result.is_empty
		end

feature {NONE} -- Implementation

	bind_json_value (a_stmt: SIMPLE_SQL_PREPARED_STATEMENT; a_index: INTEGER; a_value: detachable ANY)
			-- Bind value appropriate for JSON
		require
			statement_not_void: a_stmt /= Void
			valid_index: a_index >= 1
		do
			if a_value = Void then
				a_stmt.bind_null (a_index)
			elseif attached {INTEGER_64} a_value as l_int then
				a_stmt.bind_integer (a_index, l_int)
			elseif attached {INTEGER_32} a_value as l_int32 then
				a_stmt.bind_integer (a_index, l_int32.to_integer_64)
			elseif attached {REAL_64} a_value as l_real then
				a_stmt.bind_real (a_index, l_real)
			elseif attached {BOOLEAN} a_value as l_bool then
				a_stmt.bind_integer (a_index, if l_bool then 1 else 0 end)
			elseif attached {READABLE_STRING_GENERAL} a_value as l_string then
				a_stmt.bind_text (a_index, l_string)
			else
				-- Default: convert to string
				a_stmt.bind_text (a_index, a_value.out)
			end
		end

invariant
	database_not_void: database /= Void

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		SIMPLE_SQL - High-level SQLite API for Eiffel
		JSON1 Extension Support
	]"

end
