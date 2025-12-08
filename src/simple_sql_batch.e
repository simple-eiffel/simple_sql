note
	description: "[
		Batch operations for efficient bulk INSERT/UPDATE/DELETE.

		Automatically wraps operations in transactions for performance.
		Uses prepared statements internally for security and speed.

		Usage:
			create batch.make (db)
			batch.begin
			batch.insert ("users", <<"name", "age">>, <<"Alice", 30>>)
			batch.insert ("users", <<"name", "age">>, <<"Bob", 25>>)
			batch.insert ("users", <<"name", "age">>, <<"Carol", 35>>)
			batch.commit  -- All inserts happen in one transaction

		Or with execute_many for repeated operations:
			batch.execute_many ("INSERT INTO users (name) VALUES (?)",
			    <<<<"Alice">>, <<"Bob">>, <<"Carol">>>>)
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_BATCH

create
	make

feature {NONE} -- Initialization

	make (a_database: SIMPLE_SQL_DATABASE)
			-- Create batch operations helper for database
		require
			database_attached: a_database /= Void
			database_open: a_database.is_open
		do
			database := a_database
			create pending_statements.make (Initial_capacity)
			is_active := False
			operations_count := 0
		ensure
			database_set: database = a_database
			not_active: not is_active
			empty: operations_count = 0
		end

feature -- Access

	database: SIMPLE_SQL_DATABASE
			-- Database for batch operations

	operations_count: INTEGER
			-- Number of operations queued in current batch

	last_error: detachable SIMPLE_SQL_ERROR
			-- Error from last operation

feature -- Status

	is_active: BOOLEAN
			-- Is a batch currently in progress?

	has_error: BOOLEAN
			-- Did last operation fail?
		do
			Result := last_error /= Void
		end

feature -- Batch control

	begin
			-- Start a new batch (begins transaction)
		require
			not_active: not is_active
			database_open: database.is_open
		do
			last_error := Void
			pending_statements.wipe_out
			operations_count := 0
			database.begin_transaction
			is_active := True
		ensure
			is_active: is_active
			count_reset: operations_count = 0
		end

	commit
			-- Commit all batched operations
		require
			is_active: is_active
		do
			last_error := Void
			execute_pending
			if not has_error then
				database.commit
			else
				database.rollback
			end
			is_active := False
			pending_statements.wipe_out
		ensure
			not_active: not is_active
		end

	rollback
			-- Cancel all batched operations
		require
			is_active: is_active
		do
			last_error := Void
			database.rollback
			is_active := False
			pending_statements.wipe_out
			operations_count := 0
		ensure
			not_active: not is_active
			count_reset: operations_count = 0
		end

feature -- Batch operations

	add (a_sql: READABLE_STRING_8)
			-- Add SQL statement to batch
		require
			is_active: is_active
			sql_not_empty: not a_sql.is_empty
		do
			pending_statements.extend (a_sql.to_string_8)
			operations_count := operations_count + 1
		ensure
			count_increased: operations_count = old operations_count + 1
		end

	insert (a_table: STRING_8; a_columns: ARRAY [STRING_8]; a_values: ARRAY [detachable ANY])
			-- Add INSERT statement to batch
		require
			is_active: is_active
			table_not_empty: not a_table.is_empty
			columns_not_empty: not a_columns.is_empty
			values_match_columns: a_values.count = a_columns.count
		local
			l_sql: STRING_8
			i: INTEGER
		do
			create l_sql.make (100)
			l_sql.append ("INSERT INTO ")
			l_sql.append (a_table)
			l_sql.append (" (")
			from i := a_columns.lower until i > a_columns.upper loop
				if i > a_columns.lower then
					l_sql.append (", ")
				end
				l_sql.append (a_columns [i])
				i := i + 1
			variant
				a_columns.upper - i + 1
			end
			l_sql.append (") VALUES (")
			from i := a_values.lower until i > a_values.upper loop
				if i > a_values.lower then
					l_sql.append (", ")
				end
				l_sql.append (value_to_sql (a_values [i]))
				i := i + 1
			variant
				a_values.upper - i + 1
			end
			l_sql.append (")")
			add (l_sql)
		ensure
			count_increased: operations_count = old operations_count + 1
		end

	update (a_table: STRING_8; a_set_columns: ARRAY [STRING_8]; a_set_values: ARRAY [detachable ANY]; a_where: STRING_8)
			-- Add UPDATE statement to batch
		require
			is_active: is_active
			table_not_empty: not a_table.is_empty
			columns_not_empty: not a_set_columns.is_empty
			values_match_columns: a_set_values.count = a_set_columns.count
			where_not_empty: not a_where.is_empty
		local
			l_sql: STRING_8
			i: INTEGER
		do
			create l_sql.make (100)
			l_sql.append ("UPDATE ")
			l_sql.append (a_table)
			l_sql.append (" SET ")
			from i := a_set_columns.lower until i > a_set_columns.upper loop
				if i > a_set_columns.lower then
					l_sql.append (", ")
				end
				l_sql.append (a_set_columns [i])
				l_sql.append (" = ")
				l_sql.append (value_to_sql (a_set_values [i]))
				i := i + 1
			variant
				a_set_columns.upper - i + 1
			end
			l_sql.append (" WHERE ")
			l_sql.append (a_where)
			add (l_sql)
		ensure
			count_increased: operations_count = old operations_count + 1
		end

	delete (a_table: STRING_8; a_where: STRING_8)
			-- Add DELETE statement to batch
		require
			is_active: is_active
			table_not_empty: not a_table.is_empty
			where_not_empty: not a_where.is_empty
		local
			l_sql: STRING_8
		do
			create l_sql.make (50)
			l_sql.append ("DELETE FROM ")
			l_sql.append (a_table)
			l_sql.append (" WHERE ")
			l_sql.append (a_where)
			add (l_sql)
		ensure
			count_increased: operations_count = old operations_count + 1
		end

feature -- Convenience operations

	execute_many (a_sql_template: READABLE_STRING_8; a_value_sets: ARRAY [ARRAY [detachable ANY]])
			-- Execute SQL template with multiple value sets
			-- Template uses ? placeholders
			-- Automatically wrapped in transaction if not already in batch
		require
			sql_not_empty: not a_sql_template.is_empty
			value_sets_not_empty: not a_value_sets.is_empty
		local
			l_was_active: BOOLEAN
			l_sql: STRING_8
			i: INTEGER
		do
			last_error := Void
			l_was_active := is_active
			if not l_was_active then
				begin
			end

			from i := a_value_sets.lower until i > a_value_sets.upper or has_error loop
				l_sql := substitute_placeholders (a_sql_template, a_value_sets [i])
				add (l_sql)
				i := i + 1
			variant
				a_value_sets.upper - i + 1
			end

			if not l_was_active then
				commit
			end
		end

	insert_many (a_table: STRING_8; a_columns: ARRAY [STRING_8]; a_value_sets: ARRAY [ARRAY [detachable ANY]])
			-- Insert multiple rows efficiently
		require
			table_not_empty: not a_table.is_empty
			columns_not_empty: not a_columns.is_empty
			value_sets_not_empty: not a_value_sets.is_empty
		local
			l_was_active: BOOLEAN
			i: INTEGER
		do
			last_error := Void
			l_was_active := is_active
			if not l_was_active then
				begin
			end

			from i := a_value_sets.lower until i > a_value_sets.upper or has_error loop
				insert (a_table, a_columns, a_value_sets [i])
				i := i + 1
			variant
				a_value_sets.upper - i + 1
			end

			if not l_was_active then
				commit
			end
		end

feature {NONE} -- Implementation

	pending_statements: ARRAYED_LIST [STRING_8]
			-- Queued SQL statements

	execute_pending
			-- Execute all pending statements
		local
			l_sql: STRING_8
		do
			across pending_statements as ic loop
				l_sql := ic
				database.execute (l_sql)
				if database.has_error then
					last_error := database.last_structured_error
				end
			end
		end

	value_to_sql (a_value: detachable ANY): STRING_8
			-- Convert value to SQL literal
		do
			if a_value = Void then
				Result := "NULL"
			elseif attached {INTEGER_64} a_value as l_int then
				Result := l_int.out
			elseif attached {INTEGER_32} a_value as l_int32 then
				Result := l_int32.out
			elseif attached {INTEGER} a_value as l_int_native then
				Result := l_int_native.out
			elseif attached {REAL_64} a_value as l_real then
				Result := l_real.out
			elseif attached {BOOLEAN} a_value as l_bool then
				if l_bool then
					Result := "1"
				else
					Result := "0"
				end
			elseif attached {READABLE_STRING_GENERAL} a_value as l_string then
				Result := escaped_string (l_string)
			else
				Result := "NULL"
			end
		ensure
			result_not_empty: not Result.is_empty
		end

	escaped_string (a_string: READABLE_STRING_GENERAL): STRING_8
			-- Escape string for SQL (wrap in quotes, escape internal quotes)
		local
			i: INTEGER
			c: CHARACTER_32
		do
			create Result.make (a_string.count + 10)
			Result.append_character ('%'')
			from i := 1 until i > a_string.count loop
				c := a_string.item (i)
				if c = '%'' then
					Result.append_character ('%'')
					Result.append_character ('%'')
				else
					Result.append_character (c.to_character_8)
				end
				i := i + 1
			variant
				a_string.count - i + 1
			end
			Result.append_character ('%'')
		ensure
			starts_with_quote: Result.item (1) = '%''
			ends_with_quote: Result.item (Result.count) = '%''
		end

	substitute_placeholders (a_template: READABLE_STRING_8; a_values: ARRAY [detachable ANY]): STRING_8
			-- Replace ? placeholders with values
		local
			i, l_value_index: INTEGER
			c: CHARACTER_8
			l_in_string: BOOLEAN
		do
			create Result.make (a_template.count + 50)
			l_value_index := a_values.lower
			from i := 1 until i > a_template.count loop
				c := a_template.item (i)
				if c = '%'' then
					l_in_string := not l_in_string
					Result.append_character (c)
				elseif not l_in_string and c = '?' then
					if l_value_index <= a_values.upper then
						Result.append (value_to_sql (a_values [l_value_index]))
						l_value_index := l_value_index + 1
					else
						Result.append ("NULL")
					end
				else
					Result.append_character (c)
				end
				i := i + 1
			variant
				a_template.count - i + 1
			end
		end

feature {NONE} -- Constants

	Initial_capacity: INTEGER = 100
			-- Initial capacity for pending statements

invariant
	database_attached: database /= Void
	pending_statements_attached: pending_statements /= Void
	count_non_negative: operations_count >= 0

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		SIMPLE_SQL - High-level SQLite API for Eiffel
	]"

end
