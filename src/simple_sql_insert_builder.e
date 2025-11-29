note
	description: "Fluent builder for INSERT statements"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_INSERT_BUILDER

inherit
	SIMPLE_SQL_QUERY_BUILDER

create
	make,
	make_with_database

feature {NONE} -- Initialization

	make
			-- Create empty insert builder
		do
			create table_name.make_empty
			create columns.make (10)
			create value_rows.make (10)
			create current_values.make (10)
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

	into (a_table: READABLE_STRING_8): like Current
			-- Set the target table
		require
			table_not_empty: not a_table.is_empty
		do
			table_name := a_table.to_string_8
			Result := Current
		ensure
			table_set: table_name.same_string (a_table)
		end

feature -- Columns

	column (a_column: READABLE_STRING_8): like Current
			-- Add a column name
		require
			column_not_empty: not a_column.is_empty
		do
			columns.extend (a_column.to_string_8)
			Result := Current
		ensure
			column_added: columns.has (a_column.to_string_8)
		end

	columns_list (a_columns: ARRAY [READABLE_STRING_8]): like Current
			-- Set multiple column names
		require
			columns_not_empty: not a_columns.is_empty
		local
			i: INTEGER
		do
			columns.wipe_out
			from i := a_columns.lower until i > a_columns.upper loop
				columns.extend (a_columns [i].to_string_8)
				i := i + 1
			end
			Result := Current
		end

feature -- Values

	value (a_value: detachable ANY): like Current
			-- Add a value to the current row
		do
			current_values.extend (a_value)
			Result := Current
		end

	values (a_values: ARRAY [detachable ANY]): like Current
			-- Set all values for current row and finalize it
		require
			values_not_empty: not a_values.is_empty
		local
			i: INTEGER
			l_row: ARRAYED_LIST [detachable ANY]
		do
			create l_row.make (a_values.count)
			from i := a_values.lower until i > a_values.upper loop
				l_row.extend (a_values [i])
				i := i + 1
			end
			value_rows.extend (l_row)
			Result := Current
		end

	end_row: like Current
			-- Finalize current row and start a new one
		require
			has_current_values: has_current_values
		do
			value_rows.extend (current_values.twin)
			current_values.wipe_out
			Result := Current
		ensure
			current_cleared: current_values.is_empty
		end

	set (a_column: READABLE_STRING_8; a_value: detachable ANY): like Current
			-- Set a column-value pair (adds column if not present)
		require
			column_not_empty: not a_column.is_empty
		do
			if not columns.has (a_column.to_string_8) then
				columns.extend (a_column.to_string_8)
			end
			current_values.extend (a_value)
			Result := Current
		end

feature -- Status (for preconditions)

	has_table: BOOLEAN
			-- Has a table been specified?
		do
			Result := not table_name.is_empty
		end

	has_values: BOOLEAN
			-- Are there values to insert (either finalized rows or current values)?
		do
			Result := not value_rows.is_empty or not current_values.is_empty
		end

	has_current_values: BOOLEAN
			-- Are there values in the current row being built?
		do
			Result := not current_values.is_empty
		end

feature -- Execution

	execute: INTEGER
			-- Execute insert and return number of rows affected
		require
			has_database: has_database
			has_table: has_table
			has_values: has_values
		do
			-- Finalize any pending row
			if not current_values.is_empty then
				value_rows.extend (current_values.twin)
				current_values.wipe_out
			end

			if attached database as l_db then
				l_db.execute (to_sql)
				if not l_db.has_error then
					Result := value_rows.count
				end
			end
		end

	execute_returning_id: INTEGER_64
			-- Execute insert and return the last inserted row ID
		require
			has_database: has_database
			has_table: has_table
			has_values: has_values
		do
			-- Finalize any pending row
			if not current_values.is_empty then
				value_rows.extend (current_values.twin)
				current_values.wipe_out
			end

			if attached database as l_db then
				l_db.execute (to_sql)
				if not l_db.has_error then
					Result := l_db.last_insert_rowid
				end
			end
		end

feature -- Reset

	reset
			-- Clear all builder state
		do
			table_name.wipe_out
			columns.wipe_out
			value_rows.wipe_out
			current_values.wipe_out
		ensure
			table_empty: table_name.is_empty
			columns_empty: columns.is_empty
			values_empty: value_rows.is_empty
		end

feature -- Output

	to_sql: STRING_8
			-- Generate SQL INSERT statement
		local
			i, j: INTEGER
			l_row: ARRAYED_LIST [detachable ANY]
			l_all_rows: like value_rows
		do
			create Result.make (200)

			-- Collect all rows (including any pending current row)
			l_all_rows := value_rows.twin
			if not current_values.is_empty then
				l_all_rows.extend (current_values)
			end

			-- INSERT INTO table
			Result.append ("INSERT INTO ")
			Result.append (table_name)

			-- Columns (optional but recommended)
			if not columns.is_empty then
				Result.append (" (")
				from i := 1 until i > columns.count loop
					if i > 1 then
						Result.append (", ")
					end
					Result.append (columns [i])
					i := i + 1
				end
				Result.append (")")
			end

			-- VALUES
			Result.append (" VALUES ")

			from i := 1 until i > l_all_rows.count loop
				if i > 1 then
					Result.append (", ")
				end
				Result.append ("(")
				l_row := l_all_rows [i]
				from j := 1 until j > l_row.count loop
					if j > 1 then
						Result.append (", ")
					end
					Result.append (value_to_sql (l_row [j]))
					j := j + 1
				end
				Result.append (")")
				i := i + 1
			end
		end

feature {NONE} -- Implementation

	table_name: STRING_8
			-- Target table name

	columns: ARRAYED_LIST [STRING_8]
			-- Column names

	value_rows: ARRAYED_LIST [ARRAYED_LIST [detachable ANY]]
			-- Completed value rows for multi-row insert

	current_values: ARRAYED_LIST [detachable ANY]
			-- Values being built for current row

invariant
	table_name_attached: attached table_name
	columns_attached: attached columns
	value_rows_attached: attached value_rows
	current_values_attached: attached current_values

end
