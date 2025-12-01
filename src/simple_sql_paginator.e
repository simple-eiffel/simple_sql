note
	description: "[
		Cursor-based pagination builder.

		Provides a clean API for implementing efficient cursor-based pagination
		that works well with large datasets.

		Usage:
			paginator := db.paginator ("documents")
				.order_by ("updated_at", "id")
				.page_size (20)
				.active_only

			-- First page
			page := paginator.first_page
			-- page.items has the rows
			-- page.next_cursor for the next page

			-- Next page
			page := paginator.after (previous_cursor)
	]"
	EIS: "name=API Reference", "src=../docs/api/paginator.html", "protocol=URI", "tag=documentation"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_PAGINATOR

create
	make

feature {NONE} -- Initialization

	make (a_database: SIMPLE_SQL_DATABASE; a_table: READABLE_STRING_8)
			-- Initialize paginator for table.
		require
			database_not_void: a_database /= Void
			database_open: a_database.is_open
			table_not_empty: not a_table.is_empty
		do
			database := a_database
			table_name := a_table.to_string_8
			page_size_value := Default_page_size
			create order_columns.make (2)
			create where_conditions.make (3)
			cursor_delimiter := "|"
		ensure
			database_set: database = a_database
			table_set: table_name.same_string (a_table)
		end

feature -- Access

	database: SIMPLE_SQL_DATABASE
			-- Database connection.

	table_name: STRING_8
			-- Table to paginate.

feature -- Configuration

	page_size (a_size: INTEGER): like Current
			-- Set number of items per page.
		require
			size_positive: a_size > 0
		do
			page_size_value := a_size
			Result := Current
		ensure
			size_set: page_size_value = a_size
		end

	order_by (a_columns: ARRAY [READABLE_STRING_8]): like Current
			-- Set ordering columns (used for cursor).
			-- Must include unique column (like id) as final tiebreaker.
		require
			columns_not_empty: not a_columns.is_empty
		do
			order_columns.wipe_out
			across a_columns as ic loop
				order_columns.extend (ic.to_string_8)
			end
			Result := Current
		end

	order_by_desc: like Current
			-- Order descending instead of ascending.
		do
			is_descending := True
			Result := Current
		ensure
			descending: is_descending
		end

	where (a_condition: READABLE_STRING_8): like Current
			-- Add WHERE condition.
		require
			condition_not_empty: not a_condition.is_empty
		do
			where_conditions.extend (a_condition.to_string_8)
			Result := Current
		end

	active_only: like Current
			-- Filter to non-deleted records only.
		do
			soft_delete_mode := 1
			Result := Current
		end

	with_deleted: like Current
			-- Include soft-deleted records.
		do
			soft_delete_mode := 0
			Result := Current
		end

	set_soft_delete_column (a_column: READABLE_STRING_8)
			-- Set custom column for soft delete filtering.
		require
			column_not_empty: not a_column.is_empty
		do
			soft_delete_column := a_column.to_string_8
		end

	select_columns (a_columns: ARRAY [READABLE_STRING_8]): like Current
			-- Specify which columns to select.
		require
			columns_not_empty: not a_columns.is_empty
		local
			l_cols: ARRAYED_LIST [STRING_8]
		do
			create l_cols.make (a_columns.count)
			across a_columns as ic loop
				l_cols.extend (ic.to_string_8)
			end
			select_cols := l_cols
			Result := Current
		end

feature -- Execution

	first_page: SIMPLE_SQL_PAGE
			-- Get first page of results.
		do
			Result := execute_page (Void)
		ensure
			result_not_void: Result /= Void
		end

	after (a_cursor: READABLE_STRING_8): SIMPLE_SQL_PAGE
			-- Get page after the given cursor.
		require
			cursor_not_empty: not a_cursor.is_empty
		do
			Result := execute_page (a_cursor.to_string_8)
		ensure
			result_not_void: Result /= Void
		end

feature {NONE} -- Implementation

	page_size_value: INTEGER
			-- Number of items per page.

	order_columns: ARRAYED_LIST [STRING_8]
			-- Columns to order by.

	where_conditions: ARRAYED_LIST [STRING_8]
			-- WHERE conditions.

	is_descending: BOOLEAN
			-- Order descending?

	soft_delete_mode: INTEGER
			-- 0 = all, 1 = active only

	soft_delete_column: detachable STRING_8
			-- Column name for soft delete.

	select_cols: detachable ARRAYED_LIST [STRING_8]
			-- Columns to select (Void = all).

	cursor_delimiter: STRING_8
			-- Delimiter for cursor parts.

	Default_page_size: INTEGER = 20
			-- Default page size.

	effective_soft_delete_column: STRING_8
			-- Column name to use for soft delete.
		do
			if attached soft_delete_column as c then
				Result := c
			else
				Result := "deleted_at"
			end
		end

	execute_page (a_cursor: detachable STRING_8): SIMPLE_SQL_PAGE
			-- Execute query for a page.
		local
			l_sql: STRING_8
			l_result: SIMPLE_SQL_RESULT
			l_items: ARRAYED_LIST [SIMPLE_SQL_ROW]
			l_next_cursor: detachable STRING_8
			l_has_more: BOOLEAN
		do
			l_sql := build_query (a_cursor)
			l_result := database.query (l_sql)

			-- Check if we have more items
			l_has_more := l_result.rows.count > page_size_value

			-- Build items list (exclude extra item)
			create l_items.make (page_size_value)
			across l_result.rows as ic loop
				if l_items.count < page_size_value then
					l_items.extend (ic)
				end
			end

			-- Build next cursor from last item
			if l_has_more and then not l_items.is_empty then
				l_next_cursor := build_cursor (l_items.last)
			end

			create Result.make (l_items, l_next_cursor, l_has_more)
		end

	build_query (a_cursor: detachable STRING_8): STRING_8
			-- Build SQL query for page.
		local
			l_cursor_values: detachable ARRAYED_LIST [STRING_8]
			i: INTEGER
		do
			create Result.make (300)

			-- SELECT
			Result.append ("SELECT ")
			if attached select_cols as cols and then not cols.is_empty then
				from i := 1 until i > cols.count loop
					if i > 1 then
						Result.append (", ")
					end
					Result.append (cols [i])
					i := i + 1
				end
			else
				Result.append ("*")
			end

			-- FROM
			Result.append (" FROM ")
			Result.append (table_name)

			-- WHERE
			Result.append (" WHERE 1=1")

			-- Soft delete filter
			if soft_delete_mode = 1 then
				Result.append (" AND ")
				Result.append (effective_soft_delete_column)
				Result.append (" IS NULL")
			end

			-- User conditions
			across where_conditions as ic loop
				Result.append (" AND ")
				Result.append (ic)
			end

			-- Cursor condition
			if attached a_cursor as c and then not c.is_empty then
				l_cursor_values := parse_cursor (c)
				if attached l_cursor_values as cv and then cv.count = order_columns.count then
					Result.append (" AND ")
					Result.append (build_cursor_condition (cv))
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
					if is_descending then
						Result.append (" DESC")
					end
					i := i + 1
				end
			end

			-- LIMIT (fetch one extra to detect more pages)
			Result.append (" LIMIT ")
			Result.append_integer (page_size_value + 1)
		end

	parse_cursor (a_cursor: STRING_8): ARRAYED_LIST [STRING_8]
			-- Parse cursor string into component values.
		local
			l_parts: LIST [STRING_8]
		do
			l_parts := a_cursor.split (cursor_delimiter.item (1))
			create Result.make (l_parts.count)
			across l_parts as ic loop
				Result.extend (ic.to_string_8)
			end
		end

	build_cursor (a_row: SIMPLE_SQL_ROW): STRING_8
			-- Build cursor string from row.
		local
			i: INTEGER
			l_value: detachable ANY
		do
			create Result.make (50)
			from i := 1 until i > order_columns.count loop
				if i > 1 then
					Result.append (cursor_delimiter)
				end
				l_value := a_row.column_value (order_columns [i])
				if attached l_value as v then
					Result.append (v.out)
				end
				i := i + 1
			end
		end

	build_cursor_condition (a_values: ARRAYED_LIST [STRING_8]): STRING_8
			-- Build WHERE condition for cursor-based pagination.
			-- Uses tuple comparison: (col1, col2) > (val1, val2)
		local
			i: INTEGER
			l_op: STRING_8
		do
			create Result.make (100)

			if is_descending then
				l_op := " < "
			else
				l_op := " > "
			end

			-- Use tuple comparison for proper multi-column ordering
			Result.append ("(")
			from i := 1 until i > order_columns.count loop
				if i > 1 then
					Result.append (", ")
				end
				Result.append (order_columns [i])
				i := i + 1
			end
			Result.append (")")
			Result.append (l_op)
			Result.append ("(")
			from i := 1 until i > a_values.count loop
				if i > 1 then
					Result.append (", ")
				end
				Result.append (quote_value (a_values [i]))
				i := i + 1
			end
			Result.append (")")
		end

	quote_value (a_value: STRING_8): STRING_8
			-- Quote a value for SQL.
		do
			-- Try to detect if it's a number
			if a_value.is_integer_64 then
				Result := a_value
			else
				create Result.make (a_value.count + 2)
				Result.append_character ('%'')
				Result.append (a_value)
				Result.append_character ('%'')
			end
		end

invariant
	database_attached: database /= Void
	table_not_empty: not table_name.is_empty
	page_size_positive: page_size_value > 0

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
