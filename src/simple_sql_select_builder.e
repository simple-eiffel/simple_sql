note
	description: "Fluent builder for SELECT queries"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_SELECT_BUILDER

inherit
	SIMPLE_SQL_QUERY_BUILDER

create
	make,
	make_with_database

feature {NONE} -- Initialization

	make
			-- Create empty select builder
		do
			create columns.make (10)
			columns.compare_objects
			create tables.make (5)
			tables.compare_objects
			create joins.make (5)
			joins.compare_objects
			create where_clauses.make (10)
			create group_columns.make (5)
			group_columns.compare_objects
			create order_columns.make (5)
			order_columns.compare_objects
			create having_clauses.make (5)
			is_distinct := False
			limit_value := -1
			offset_value := -1
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

feature -- Column Selection

	select_all: like Current
			-- Select all columns (*)
		do
			columns.wipe_out
			columns.extend ("*")
			Result := Current
		ensure
			has_star: columns.has ("*")
		end

	select_column (a_column: READABLE_STRING_8): like Current
			-- Add a column to select
		require
			column_not_empty: not a_column.is_empty
		do
			columns.extend (a_column.to_string_8)
			Result := Current
		ensure
			column_added: columns.has (a_column.to_string_8)
		end

	select_columns (a_columns: ARRAY [READABLE_STRING_8]): like Current
			-- Add multiple columns to select
		require
			columns_not_empty: not a_columns.is_empty
		local
			i: INTEGER
		do
			from i := a_columns.lower until i > a_columns.upper loop
				columns.extend (a_columns [i].to_string_8)
				i := i + 1
			end
			Result := Current
		end

	select_column_as (a_column: READABLE_STRING_8; a_alias: READABLE_STRING_8): like Current
			-- Add a column with an alias
		require
			column_not_empty: not a_column.is_empty
			alias_not_empty: not a_alias.is_empty
		do
			columns.extend (a_column.to_string_8 + " AS " + identifier (a_alias.to_string_8))
			Result := Current
		end

	distinct: like Current
			-- Add DISTINCT modifier
		do
			is_distinct := True
			Result := Current
		ensure
			is_distinct: is_distinct
		end

feature -- Table Selection

	from_table (a_table: READABLE_STRING_8): like Current
			-- Set the FROM table
		require
			table_not_empty: not a_table.is_empty
		do
			tables.wipe_out
			tables.extend (a_table.to_string_8)
			Result := Current
		ensure
			table_set: tables.has (a_table.to_string_8)
		end

	from_table_as (a_table: READABLE_STRING_8; a_alias: READABLE_STRING_8): like Current
			-- Set the FROM table with alias
		require
			table_not_empty: not a_table.is_empty
			alias_not_empty: not a_alias.is_empty
		do
			tables.wipe_out
			tables.extend (a_table.to_string_8 + " AS " + identifier (a_alias.to_string_8))
			Result := Current
		end

feature -- Joins

	join (a_table: READABLE_STRING_8; a_condition: READABLE_STRING_8): like Current
			-- Add an INNER JOIN
		require
			table_not_empty: not a_table.is_empty
			condition_not_empty: not a_condition.is_empty
		do
			joins.extend ("JOIN " + a_table.to_string_8 + " ON " + a_condition.to_string_8)
			Result := Current
		end

	inner_join (a_table: READABLE_STRING_8; a_condition: READABLE_STRING_8): like Current
			-- Add an INNER JOIN (explicit)
		require
			table_not_empty: not a_table.is_empty
			condition_not_empty: not a_condition.is_empty
		do
			joins.extend ("INNER JOIN " + a_table.to_string_8 + " ON " + a_condition.to_string_8)
			Result := Current
		end

	left_join (a_table: READABLE_STRING_8; a_condition: READABLE_STRING_8): like Current
			-- Add a LEFT OUTER JOIN
		require
			table_not_empty: not a_table.is_empty
			condition_not_empty: not a_condition.is_empty
		do
			joins.extend ("LEFT JOIN " + a_table.to_string_8 + " ON " + a_condition.to_string_8)
			Result := Current
		end

	cross_join (a_table: READABLE_STRING_8): like Current
			-- Add a CROSS JOIN
		require
			table_not_empty: not a_table.is_empty
		do
			joins.extend ("CROSS JOIN " + a_table.to_string_8)
			Result := Current
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

	where_like (a_column: READABLE_STRING_8; a_pattern: READABLE_STRING_8): like Current
			-- Add WHERE column LIKE pattern
		require
			column_not_empty: not a_column.is_empty
			pattern_not_empty: not a_pattern.is_empty
		do
			where_clauses.wipe_out
			where_clauses.extend ([a_column.to_string_8 + " LIKE " + escaped_string (a_pattern), ""])
			Result := Current
		end

feature -- Grouping

	group_by (a_column: READABLE_STRING_8): like Current
			-- Add GROUP BY column
		require
			column_not_empty: not a_column.is_empty
		do
			group_columns.extend (a_column.to_string_8)
			Result := Current
		end

	group_by_columns (a_columns: ARRAY [READABLE_STRING_8]): like Current
			-- Add multiple GROUP BY columns
		require
			columns_not_empty: not a_columns.is_empty
		local
			i: INTEGER
		do
			from i := a_columns.lower until i > a_columns.upper loop
				group_columns.extend (a_columns [i].to_string_8)
				i := i + 1
			end
			Result := Current
		end

	having (a_condition: READABLE_STRING_8): like Current
			-- Add HAVING condition
		require
			condition_not_empty: not a_condition.is_empty
		do
			having_clauses.wipe_out
			having_clauses.extend ([a_condition.to_string_8, ""])
			Result := Current
		end

	and_having (a_condition: READABLE_STRING_8): like Current
			-- Add AND HAVING condition
		require
			condition_not_empty: not a_condition.is_empty
		do
			having_clauses.extend ([a_condition.to_string_8, "AND"])
			Result := Current
		end

feature -- Ordering

	order_by (a_column: READABLE_STRING_8): like Current
			-- Add ORDER BY column (ascending)
		require
			column_not_empty: not a_column.is_empty
		do
			order_columns.extend (a_column.to_string_8)
			Result := Current
		end

	order_by_desc (a_column: READABLE_STRING_8): like Current
			-- Add ORDER BY column descending
		require
			column_not_empty: not a_column.is_empty
		do
			order_columns.extend (a_column.to_string_8 + " DESC")
			Result := Current
		end

	order_by_asc (a_column: READABLE_STRING_8): like Current
			-- Add ORDER BY column ascending (explicit)
		require
			column_not_empty: not a_column.is_empty
		do
			order_columns.extend (a_column.to_string_8 + " ASC")
			Result := Current
		end

feature -- Limiting

	limit (a_limit: INTEGER): like Current
			-- Set LIMIT value
		require
			limit_positive: a_limit >= 0
		do
			limit_value := a_limit
			Result := Current
		ensure
			limit_set: limit_value = a_limit
		end

	offset (a_offset: INTEGER): like Current
			-- Set OFFSET value
		require
			offset_positive: a_offset >= 0
		do
			offset_value := a_offset
			Result := Current
		ensure
			offset_set: offset_value = a_offset
		end

feature -- Status (for preconditions)

	has_table: BOOLEAN
			-- Has at least one table been specified?
		do
			Result := not tables.is_empty
		end

feature -- Execution

	execute: detachable SIMPLE_SQL_RESULT
			-- Execute query and return result
		require
			has_database: has_database
			has_table: has_table
		do
			if attached database as l_db then
				Result := l_db.query (to_sql)
			end
		end

	first: detachable SIMPLE_SQL_ROW
			-- Execute query and return first row
		require
			has_database: has_database
			has_table: has_table
		local
			l_saved_limit: INTEGER
		do
			l_saved_limit := limit_value
			limit_value := 1
			if attached execute as l_result and then not l_result.rows.is_empty then
				Result := l_result.rows.first
			end
			limit_value := l_saved_limit
		end

	count: INTEGER
			-- Execute COUNT(*) query and return result
		require
			has_database: has_database
			has_table: has_table
		local
			l_saved_columns: like columns
		do
			l_saved_columns := columns.twin
			columns.wipe_out
			columns.extend ("COUNT(*)")
			if attached execute as l_result and then not l_result.rows.is_empty then
				if attached l_result.rows.first as l_row then
					-- Use item(1) to get the first column value, then cast to INTEGER_64
					if attached {INTEGER_64} l_row.item (1) as l_count then
						Result := l_count.to_integer_32
					end
				end
			end
			columns := l_saved_columns
		end

	exists: BOOLEAN
			-- Does at least one row match?
		require
			has_database: has_database
			has_table: has_table
		do
			Result := count > 0
		end

feature -- Reset

	reset
			-- Clear all builder state
		do
			columns.wipe_out
			tables.wipe_out
			joins.wipe_out
			where_clauses.wipe_out
			group_columns.wipe_out
			order_columns.wipe_out
			having_clauses.wipe_out
			is_distinct := False
			limit_value := -1
			offset_value := -1
		ensure
			columns_empty: columns.is_empty
			tables_empty: tables.is_empty
		end

feature -- Output

	to_sql: STRING_8
			-- Generate SQL SELECT statement
		local
			i: INTEGER
		do
			create Result.make (200)

			-- SELECT
			Result.append ("SELECT ")
			if is_distinct then
				Result.append ("DISTINCT ")
			end

			-- Columns
			if columns.is_empty then
				Result.append ("*")
			else
				from i := 1 until i > columns.count loop
					if i > 1 then
						Result.append (", ")
					end
					Result.append (columns [i])
					i := i + 1
				end
			end

			-- FROM
			if not tables.is_empty then
				Result.append (" FROM ")
				from i := 1 until i > tables.count loop
					if i > 1 then
						Result.append (", ")
					end
					Result.append (tables [i])
					i := i + 1
				end
			end

			-- JOINs
			across joins as ic loop
				Result.append (" ")
				Result.append (ic)
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

			-- GROUP BY
			if not group_columns.is_empty then
				Result.append (" GROUP BY ")
				from i := 1 until i > group_columns.count loop
					if i > 1 then
						Result.append (", ")
					end
					Result.append (group_columns [i])
					i := i + 1
				end
			end

			-- HAVING
			if not having_clauses.is_empty then
				Result.append (" HAVING ")
				from i := 1 until i > having_clauses.count loop
					if i > 1 and then not having_clauses [i].connector.is_empty then
						Result.append (" ")
						Result.append (having_clauses [i].connector)
						Result.append (" ")
					end
					Result.append (having_clauses [i].condition)
					i := i + 1
				end
			end

			-- ORDER BY
			if not order_columns.is_empty then
				Result.append (" ORDER BY ")
				from i := 1 until i > order_columns.count loop
					if i > 1 then
						Result.append (", ")
					end
					Result.append (order_columns [i])
					i := i + 1
				end
			end

			-- LIMIT
			if limit_value >= 0 then
				Result.append (" LIMIT ")
				Result.append_integer (limit_value)
			end

			-- OFFSET
			if offset_value >= 0 then
				Result.append (" OFFSET ")
				Result.append_integer (offset_value)
			end
		end

feature {NONE} -- Implementation

	columns: ARRAYED_LIST [STRING_8]
			-- Columns to select

	tables: ARRAYED_LIST [STRING_8]
			-- Tables to select from

	joins: ARRAYED_LIST [STRING_8]
			-- JOIN clauses

	where_clauses: ARRAYED_LIST [TUPLE [condition: STRING_8; connector: STRING_8]]
			-- WHERE conditions with connectors (AND/OR)

	group_columns: ARRAYED_LIST [STRING_8]
			-- GROUP BY columns

	order_columns: ARRAYED_LIST [STRING_8]
			-- ORDER BY columns

	having_clauses: ARRAYED_LIST [TUPLE [condition: STRING_8; connector: STRING_8]]
			-- HAVING conditions with connectors

	is_distinct: BOOLEAN
			-- Use DISTINCT?

	limit_value: INTEGER
			-- LIMIT value (-1 means not set)

	offset_value: INTEGER
			-- OFFSET value (-1 means not set)

invariant
	limit_valid: limit_value >= -1
	offset_valid: offset_value >= -1

end
