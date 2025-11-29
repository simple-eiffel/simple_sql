note
	description: "Fluent builder for UPDATE statements"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_UPDATE_BUILDER

inherit
	SIMPLE_SQL_QUERY_BUILDER

create
	make,
	make_with_database

feature {NONE} -- Initialization

	make
			-- Create empty update builder
		do
			create table_name.make_empty
			create set_clauses.make (10)
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

	table (a_table: READABLE_STRING_8): like Current
			-- Set the target table
		require
			table_not_empty: not a_table.is_empty
		do
			table_name := a_table.to_string_8
			Result := Current
		ensure
			table_set: table_name.same_string (a_table)
		end

	update (a_table: READABLE_STRING_8): like Current
			-- Alias for table - more natural reading
		require
			table_not_empty: not a_table.is_empty
		do
			Result := table (a_table)
		ensure
			table_set: table_name.same_string (a_table)
		end

feature -- SET Clauses

	set (a_column: READABLE_STRING_8; a_value: detachable ANY): like Current
			-- Set column = value
		require
			column_not_empty: not a_column.is_empty
		do
			set_clauses.extend ([a_column.to_string_8, a_value])
			Result := Current
		end

	set_null (a_column: READABLE_STRING_8): like Current
			-- Set column = NULL
		require
			column_not_empty: not a_column.is_empty
		do
			set_clauses.extend ([a_column.to_string_8, Void])
			Result := Current
		end

	set_expression (a_column: READABLE_STRING_8; a_expression: READABLE_STRING_8): like Current
			-- Set column = raw SQL expression (not escaped)
			-- Use for things like: set_expression("counter", "counter + 1")
		require
			column_not_empty: not a_column.is_empty
			expression_not_empty: not a_expression.is_empty
		do
			set_clauses.extend ([a_column.to_string_8, create {SIMPLE_SQL_RAW_EXPRESSION}.make (a_expression)])
			Result := Current
		end

	increment (a_column: READABLE_STRING_8): like Current
			-- Increment column by 1
		require
			column_not_empty: not a_column.is_empty
		do
			Result := set_expression (a_column, a_column + " + 1")
		end

	increment_by (a_column: READABLE_STRING_8; a_amount: INTEGER): like Current
			-- Increment column by amount
		require
			column_not_empty: not a_column.is_empty
		do
			Result := set_expression (a_column, a_column + " + " + a_amount.out)
		end

	decrement (a_column: READABLE_STRING_8): like Current
			-- Decrement column by 1
		require
			column_not_empty: not a_column.is_empty
		do
			Result := set_expression (a_column, a_column + " - 1")
		end

	decrement_by (a_column: READABLE_STRING_8; a_amount: INTEGER): like Current
			-- Decrement column by amount
		require
			column_not_empty: not a_column.is_empty
		do
			Result := set_expression (a_column, a_column + " - " + a_amount.out)
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

feature -- Status (for preconditions)

	has_table: BOOLEAN
			-- Has a table been specified?
		do
			Result := not table_name.is_empty
		end

	has_set_clauses: BOOLEAN
			-- Are there SET clauses?
		do
			Result := not set_clauses.is_empty
		end

feature -- Execution

	execute: INTEGER
			-- Execute update and return number of rows affected
		require
			has_database: has_database
			has_table: has_table
			has_set_clauses: has_set_clauses
		do
			if attached database as l_db then
				l_db.execute (to_sql)
				if not l_db.has_error then
					Result := l_db.changes_count
				end
			end
		end

feature -- Reset

	reset
			-- Clear all builder state
		do
			table_name.wipe_out
			set_clauses.wipe_out
			where_clauses.wipe_out
		ensure
			table_empty: table_name.is_empty
			set_empty: set_clauses.is_empty
			where_empty: where_clauses.is_empty
		end

feature -- Output

	to_sql: STRING_8
			-- Generate SQL UPDATE statement
		local
			i: INTEGER
		do
			create Result.make (200)

			-- UPDATE table
			Result.append ("UPDATE ")
			Result.append (table_name)

			-- SET clauses
			Result.append (" SET ")
			from i := 1 until i > set_clauses.count loop
				if i > 1 then
					Result.append (", ")
				end
				Result.append (set_clauses [i].column)
				Result.append (" = ")
				if attached {SIMPLE_SQL_RAW_EXPRESSION} set_clauses [i].value as l_raw then
					Result.append (l_raw.expression)
				else
					Result.append (value_to_sql (set_clauses [i].value))
				end
				i := i + 1
			end

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

	set_clauses: ARRAYED_LIST [TUPLE [column: STRING_8; value: detachable ANY]]
			-- SET column = value pairs

	where_clauses: ARRAYED_LIST [TUPLE [condition: STRING_8; connector: STRING_8]]
			-- WHERE conditions with connectors

invariant
	table_name_attached: attached table_name
	set_clauses_attached: attached set_clauses
	where_clauses_attached: attached where_clauses

end
