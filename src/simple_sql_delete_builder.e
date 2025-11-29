note
	description: "Fluent builder for DELETE statements"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_DELETE_BUILDER

inherit
	SIMPLE_SQL_QUERY_BUILDER

create
	make,
	make_with_database

feature {NONE} -- Initialization

	make
			-- Create empty delete builder
		do
			create table_name.make_empty
			create where_clauses.make (10)
		end

	make_with_database (a_database: SIMPLE_SQL_DATABASE)
			-- Create with database for execution
		require
			database_open: a_database.is_open
		do
			make
			set_database (a_database)
		ensure
			database_set: database = a_database
		end

feature -- Table

	from_table (a_table: READABLE_STRING_8): like Current
			-- Set the target table
		require
			table_not_empty: not a_table.is_empty
		do
			table_name := a_table.to_string_8
			Result := Current
		ensure
			table_set: table_name.same_string (a_table)
		end

	delete_from (a_table: READABLE_STRING_8): like Current
			-- Alias for from_table - more natural reading
		require
			table_not_empty: not a_table.is_empty
		do
			Result := from_table (a_table)
		ensure
			table_set: table_name.same_string (a_table)
		end

feature -- WHERE Clauses

	where (a_condition: READABLE_STRING_8): like Current
			-- Set the WHERE condition (replaces any existing)
		require
			condition_not_empty: not a_condition.is_empty
		do
			where_clauses.wipe_out
			where_clauses.extend ([a_condition.to_string_8, ""])
			Result := Current
		end

	where_equals (a_column: READABLE_STRING_8; a_value: detachable ANY): like Current
			-- Add WHERE column = value
		require
			column_not_empty: not a_column.is_empty
		do
			where_clauses.wipe_out
			where_clauses.extend ([a_column.to_string_8 + " = " + value_to_sql (a_value), ""])
			Result := Current
		end

	where_id (a_id: INTEGER_64): like Current
			-- Convenience: WHERE id = value
		do
			Result := where_equals ("id", a_id)
		end

	and_where (a_condition: READABLE_STRING_8): like Current
			-- Add AND condition
		require
			condition_not_empty: not a_condition.is_empty
		do
			where_clauses.extend ([a_condition.to_string_8, "AND"])
			Result := Current
		end

	and_where_equals (a_column: READABLE_STRING_8; a_value: detachable ANY): like Current
			-- Add AND column = value
		require
			column_not_empty: not a_column.is_empty
		do
			where_clauses.extend ([a_column.to_string_8 + " = " + value_to_sql (a_value), "AND"])
			Result := Current
		end

	or_where (a_condition: READABLE_STRING_8): like Current
			-- Add OR condition
		require
			condition_not_empty: not a_condition.is_empty
		do
			where_clauses.extend ([a_condition.to_string_8, "OR"])
			Result := Current
		end

	or_where_equals (a_column: READABLE_STRING_8; a_value: detachable ANY): like Current
			-- Add OR column = value
		require
			column_not_empty: not a_column.is_empty
		do
			where_clauses.extend ([a_column.to_string_8 + " = " + value_to_sql (a_value), "OR"])
			Result := Current
		end

	where_null (a_column: READABLE_STRING_8): like Current
			-- Add WHERE column IS NULL
		require
			column_not_empty: not a_column.is_empty
		do
			where_clauses.wipe_out
			where_clauses.extend ([a_column.to_string_8 + " IS NULL", ""])
			Result := Current
		end

	where_not_null (a_column: READABLE_STRING_8): like Current
			-- Add WHERE column IS NOT NULL
		require
			column_not_empty: not a_column.is_empty
		do
			where_clauses.wipe_out
			where_clauses.extend ([a_column.to_string_8 + " IS NOT NULL", ""])
			Result := Current
		end

	where_in (a_column: READABLE_STRING_8; a_values: ARRAY [detachable ANY]): like Current
			-- Add WHERE column IN (values)
		require
			column_not_empty: not a_column.is_empty
			values_not_empty: not a_values.is_empty
		local
			l_sql: STRING_8
			i: INTEGER
		do
			create l_sql.make (50)
			l_sql.append (a_column.to_string_8)
			l_sql.append (" IN (")
			from i := a_values.lower until i > a_values.upper loop
				if i > a_values.lower then
					l_sql.append (", ")
				end
				l_sql.append (value_to_sql (a_values [i]))
				i := i + 1
			end
			l_sql.append (")")
			where_clauses.wipe_out
			where_clauses.extend ([l_sql, ""])
			Result := Current
		end

	where_between (a_column: READABLE_STRING_8; a_low: detachable ANY; a_high: detachable ANY): like Current
			-- Add WHERE column BETWEEN low AND high
		require
			column_not_empty: not a_column.is_empty
		do
			where_clauses.wipe_out
			where_clauses.extend ([a_column.to_string_8 + " BETWEEN " + value_to_sql (a_low) + " AND " + value_to_sql (a_high), ""])
			Result := Current
		end

feature -- Status (for preconditions)

	has_table: BOOLEAN
			-- Has a table been specified?
		do
			Result := not table_name.is_empty
		end

feature -- Execution

	execute: INTEGER
			-- Execute delete and return number of rows affected
		require
			has_database: has_database
			has_table: has_table
		do
			if attached database as l_db then
				l_db.execute (to_sql)
				if not l_db.has_error then
					Result := l_db.changes_count
				end
			end
		end

	execute_all: INTEGER
			-- Delete all rows (no WHERE clause required)
			-- Returns number of rows deleted
		require
			has_database: has_database
			has_table: has_table
		do
			-- Clear any existing where clauses to delete all
			where_clauses.wipe_out
			Result := execute
		end

feature -- Reset

	reset
			-- Clear all builder state
		do
			table_name.wipe_out
			where_clauses.wipe_out
		ensure
			table_empty: table_name.is_empty
			where_empty: where_clauses.is_empty
		end

feature -- Output

	to_sql: STRING_8
			-- Generate SQL DELETE statement
		local
			i: INTEGER
		do
			create Result.make (100)

			-- DELETE FROM table
			Result.append ("DELETE FROM ")
			Result.append (table_name)

			-- WHERE
			if not where_clauses.is_empty then
				Result.append (" WHERE ")
				from i := 1 until i > where_clauses.count loop
					if i > 1 and then not where_clauses [i].connector.is_empty then
						Result.append (" ")
						Result.append (where_clauses [i].connector)
						Result.append (" ")
					end
					Result.append (where_clauses [i].condition)
					i := i + 1
				end
			end
		end

feature {NONE} -- Implementation

	table_name: STRING_8
			-- Target table name

	where_clauses: ARRAYED_LIST [TUPLE [condition: STRING_8; connector: STRING_8]]
			-- WHERE conditions with connectors

invariant
	table_name_attached: attached table_name
	where_clauses_attached: attached where_clauses

end
