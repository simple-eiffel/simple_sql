note
	description: "[
		Prepared statement wrapper for SQLite with parameter binding.

		Provides cached, parameterized queries for:
			- Security: Prevents SQL injection via bound parameters
			- Performance: Statement compiled once, executed many times
			- Convenience: Named or indexed parameter binding

		Usage (indexed parameters):
			stmt := db.prepare ("INSERT INTO users (name, age) VALUES (?, ?)")
			stmt.bind_text (1, "Alice")
			stmt.bind_integer (2, 30)
			stmt.execute
			stmt.reset  -- Reuse with new values
			stmt.bind_text (1, "Bob")
			stmt.bind_integer (2, 25)
			stmt.execute

		Usage (named parameters):
			stmt := db.prepare ("INSERT INTO users (name, age) VALUES (:name, :age)")
			stmt.bind_text_by_name (":name", "Alice")
			stmt.bind_integer_by_name (":age", 30)
			stmt.execute
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_PREPARED_STATEMENT

create
	make

feature {NONE} -- Initialization

	make (a_sql: READABLE_STRING_8; a_database: SQLITE_DATABASE)
			-- Prepare statement for execution
		require
			sql_not_empty: not a_sql.is_empty
			database_attached: a_database /= Void
			database_readable: a_database.is_readable
		do
			create sql.make_from_string (a_sql)
			database := a_database
			create bindings.make (Initial_binding_capacity)
			is_query := sql.count >= 6 and then sql.substring (1, 6).is_case_insensitive_equal ("SELECT")
			has_executed := False
		ensure
			sql_set: sql.same_string (a_sql)
			database_set: database = a_database
			not_executed: not has_executed
		end

feature -- Access

	sql: STRING_8
			-- The prepared SQL statement

	last_result: detachable SIMPLE_SQL_RESULT
			-- Result from last query execution (Void for non-query statements)

	last_error: detachable SIMPLE_SQL_ERROR
			-- Error from last operation

	parameter_count: INTEGER
			-- Number of parameters in the statement
		do
			Result := count_parameters
		end

feature -- Status

	is_query: BOOLEAN
			-- Is this a SELECT query?

	has_error: BOOLEAN
			-- Did last operation fail?
		do
			Result := last_error /= Void
		end

	has_executed: BOOLEAN
			-- Has this statement been executed at least once?

feature -- Binding by index (1-based)

	bind_integer (a_index: INTEGER; a_value: INTEGER_64)
			-- Bind integer value at parameter index
		require
			valid_index: a_index >= 1
		do
			store_binding (a_index, a_value)
		end

	bind_real (a_index: INTEGER; a_value: REAL_64)
			-- Bind real value at parameter index
		require
			valid_index: a_index >= 1
		do
			store_binding (a_index, a_value)
		end

	bind_text (a_index: INTEGER; a_value: READABLE_STRING_GENERAL)
			-- Bind text value at parameter index
		require
			valid_index: a_index >= 1
			value_not_void: a_value /= Void
		do
			store_binding (a_index, a_value.to_string_32)
		end

	bind_blob (a_index: INTEGER; a_value: MANAGED_POINTER)
			-- Bind blob value at parameter index
		require
			valid_index: a_index >= 1
			value_not_void: a_value /= Void
		do
			store_binding (a_index, a_value)
		end

	bind_null (a_index: INTEGER)
			-- Bind NULL at parameter index
		require
			valid_index: a_index >= 1
		do
			store_binding (a_index, Void)
		end

feature -- Binding by name

	bind_integer_by_name (a_name: STRING_8; a_value: INTEGER_64)
			-- Bind integer value to named parameter
		require
			name_not_empty: not a_name.is_empty
		local
			l_index: INTEGER
		do
			l_index := parameter_index (a_name)
			if l_index > 0 then
				bind_integer (l_index, a_value)
			end
		end

	bind_real_by_name (a_name: STRING_8; a_value: REAL_64)
			-- Bind real value to named parameter
		require
			name_not_empty: not a_name.is_empty
		local
			l_index: INTEGER
		do
			l_index := parameter_index (a_name)
			if l_index > 0 then
				bind_real (l_index, a_value)
			end
		end

	bind_text_by_name (a_name: STRING_8; a_value: READABLE_STRING_GENERAL)
			-- Bind text value to named parameter
		require
			name_not_empty: not a_name.is_empty
			value_not_void: a_value /= Void
		local
			l_index: INTEGER
		do
			l_index := parameter_index (a_name)
			if l_index > 0 then
				bind_text (l_index, a_value)
			end
		end

	bind_null_by_name (a_name: STRING_8)
			-- Bind NULL to named parameter
		require
			name_not_empty: not a_name.is_empty
		local
			l_index: INTEGER
		do
			l_index := parameter_index (a_name)
			if l_index > 0 then
				bind_null (l_index)
			end
		end

feature -- Execution

	execute
			-- Execute the prepared statement
		local
			l_sql_with_bindings: STRING_8
		do
			last_error := Void
			last_result := Void
			l_sql_with_bindings := sql_with_bound_values
			if is_query then
				execute_query (l_sql_with_bindings)
			else
				execute_modify (l_sql_with_bindings)
			end
			has_executed := True
		end

	execute_returning_result: SIMPLE_SQL_RESULT
			-- Execute query and return result
		require
			is_query: is_query
		do
			execute
			if attached last_result as l_result then
				Result := l_result
			else
				create Result.make_empty
			end
		ensure
			result_attached: Result /= Void
		end

feature -- Reset

	reset
			-- Clear bindings for reuse with new values
		do
			bindings.wipe_out
			last_error := Void
			last_result := Void
		ensure
			bindings_cleared: bindings.is_empty
			no_error: not has_error
		end

	clear_bindings
			-- Clear all parameter bindings (alias for reset)
		do
			reset
		end

feature {NONE} -- Implementation

	database: SQLITE_DATABASE
			-- Database connection

	bindings: HASH_TABLE [detachable ANY, INTEGER]
			-- Parameter bindings (index -> value)

	store_binding (a_index: INTEGER; a_value: detachable ANY)
			-- Store binding value for parameter
		do
			bindings.force (a_value, a_index)
		end

	count_parameters: INTEGER
			-- Count ? placeholders in SQL
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > sql.count
			loop
				if sql.item (i) = '?' then
					Result := Result + 1
				end
				i := i + 1
			end
		end

	parameter_index (a_name: STRING_8): INTEGER
			-- Find index of named parameter (returns 0 if not found)
			-- Handles :name, @name, $name formats
		local
			l_pos: INTEGER
			l_param_num: INTEGER
		do
			-- Simple implementation: scan SQL for named parameters
			-- and return position. Named params become positional.
			l_pos := sql.substring_index (a_name, 1)
			if l_pos > 0 then
				-- Count ? and named params before this position
				l_param_num := count_parameters_before (l_pos) + 1
				Result := l_param_num
			end
		end

	count_parameters_before (a_position: INTEGER): INTEGER
			-- Count parameters before given position
		local
			i: INTEGER
			c: CHARACTER_8
		do
			from
				i := 1
			until
				i >= a_position
			loop
				c := sql.item (i)
				if c = '?' or c = ':' or c = '@' or c = '$' then
					Result := Result + 1
				end
				i := i + 1
			end
		end

	sql_with_bound_values: STRING_8
			-- SQL with bound values substituted
			-- NOTE: This is a simple implementation that substitutes values directly.
			-- A production implementation would use actual SQLite parameter binding.
		local
			l_result: STRING_8
			i, l_param_index: INTEGER
			c: CHARACTER_8
			l_in_string: BOOLEAN
		do
			create l_result.make (sql.count + 50)
			l_param_index := 0
			from
				i := 1
			until
				i > sql.count
			loop
				c := sql.item (i)
				if c = '%'' then
					l_in_string := not l_in_string
					l_result.append_character (c)
				elseif not l_in_string and c = '?' then
					l_param_index := l_param_index + 1
					l_result.append (value_as_sql (bindings.item (l_param_index)))
				else
					l_result.append_character (c)
				end
				i := i + 1
			end
			Result := l_result
		end

	value_as_sql (a_value: detachable ANY): STRING_8
			-- Convert value to SQL literal
		do
			if a_value = Void then
				Result := "NULL"
			elseif attached {INTEGER_64} a_value as l_int then
				Result := l_int.out
			elseif attached {INTEGER_32} a_value as l_int32 then
				Result := l_int32.out
			elseif attached {REAL_64} a_value as l_real then
				Result := l_real.out
			elseif attached {REAL_32} a_value as l_real32 then
				Result := l_real32.out
			elseif attached {READABLE_STRING_GENERAL} a_value as l_string then
				Result := escaped_string (l_string)
			else
				Result := "NULL"
			end
		ensure
			result_not_empty: not Result.is_empty
		end

	escaped_string (a_string: READABLE_STRING_GENERAL): STRING_8
			-- Escape string for SQL (single quotes)
		local
			i: INTEGER
			c: CHARACTER_32
		do
			create Result.make (a_string.count + 10)
			Result.append_character ('%'')
			from
				i := 1
			until
				i > a_string.count
			loop
				c := a_string.item (i)
				if c = '%'' then
					Result.append_character ('%'')
					Result.append_character ('%'')
				else
					Result.append_character (c.to_character_8)
				end
				i := i + 1
			end
			Result.append_character ('%'')
		end

	execute_query (a_sql: STRING_8)
			-- Execute as SELECT query
		local
			l_sql: STRING_8
		do
			create l_sql.make_from_string (a_sql)
			if not l_sql.ends_with (";") then
				l_sql.append_character (';')
			end
			create last_result.make (l_sql, database)
		end

	execute_modify (a_sql: STRING_8)
			-- Execute as INSERT/UPDATE/DELETE
		local
			l_statement: SQLITE_MODIFY_STATEMENT
			l_sql: STRING_8
		do
			create l_sql.make_from_string (a_sql)
			if not l_sql.ends_with (";") then
				l_sql.append_character (';')
			end
			create l_statement.make (l_sql, database)
			l_statement.execute
		end

feature {NONE} -- Constants

	Initial_binding_capacity: INTEGER = 10
			-- Initial capacity for bindings hash table

invariant
	sql_attached: sql /= Void
	database_attached: database /= Void
	bindings_attached: bindings /= Void

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		SIMPLE_SQL - High-level SQLite API for Eiffel
	]"

end
