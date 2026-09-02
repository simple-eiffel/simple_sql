note
	description: "[
		Fluent builder for SQL INSERT statements supporting single-row and multi-row inserts.
		Accumulates columns and values via chained calls, then generates and optionally
		executes the INSERT with returning-id support.
		Provides the INSERT composition layer for simple_sql query building.
	]"
	purpose: "Build and execute INSERT statements with fluent column/value chaining"
	collaborators: "SIMPLE_SQL_QUERY_BUILDER, SIMPLE_SQL_DATABASE"
	design_pattern: "Builder"
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
		note
			semantic_role: "[
				Initializes empty column list and value
				row storage for incremental INSERT
				construction.
			]"
		do
			create table_name.make_empty
			create columns.make (10)
			create value_rows.make (10)
			create current_values.make (10)
		end

	make_with_database (a_database: SIMPLE_SQL_DATABASE)
			-- Create with database for execution
		note
			semantic_role: "[
				Combines builder initialization with
				database attachment for immediate
				execution capability.
			]"
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
		note
			semantic_role: "[
				Specifies the INSERT INTO target table,
				returning Current for fluent chaining.
			]"
			modifies: "table_name"
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
		note
			semantic_role: "[
				Appends a single column to the INSERT
				column list.
			]"
			modifies: "columns"
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
		note
			semantic_role: "[
				Replaces the column list with all
				provided column names in one call.
			]"
			modifies: "columns"
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
		note
			semantic_role: "[
				Appends a single value to the row being
				built, paired positionally with columns.
			]"
			modifies: "current_values"
		do
			current_values.extend (a_value)
			Result := Current
		end

	values (a_values: ARRAY [detachable ANY]): like Current
			-- Set all values for current row and finalize it
		note
			semantic_role: "[
				Creates a complete value row from an
				array and immediately finalizes it.
			]"
			modifies: "value_rows"
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
		note
			semantic_role: "[
				Commits the accumulated current_values
				as a complete row for multi-row inserts.
			]"
			modifies: "value_rows, current_values"
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
		note
			semantic_role: "[
				Combined column-and-value setter for
				convenience when building single-row
				inserts.
			]"
			modifies: "columns, current_values"
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
		note
			semantic_role: "[
				Table specification predicate guarding
				INSERT execution.
			]"
		do
			Result := not table_name.is_empty
		end

	has_values: BOOLEAN
			-- Are there values to insert (either finalized rows or current values)?
		note
			semantic_role: "[
				Value presence predicate ensuring at
				least one row of data exists.
			]"
		do
			Result := not value_rows.is_empty or not current_values.is_empty
		end

	has_current_values: BOOLEAN
			-- Are there values in the current row being built?
		note
			semantic_role: "[
				In-progress row detection for end_row
				precondition.
			]"
		do
			Result := not current_values.is_empty
		end

feature -- Execution

	execute: INTEGER
			-- Execute insert and return number of rows affected
		note
			semantic_role: "[
				Finalizes pending values, executes
				INSERT, and returns affected row count.
			]"
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

			if attached database as al_l_db then
				al_l_db.execute (to_sql)
				if not al_l_db.has_error then
					Result := value_rows.count
				end
			end
		end

	execute_returning_id: INTEGER_64
			-- Execute insert and return the last inserted row ID
		note
			semantic_role: "[
				Executes INSERT and retrieves SQLite
				last_insert_rowid for auto-increment
				keys.
			]"
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

			if attached database as al_l_db then
				al_l_db.execute (to_sql)
				if not al_l_db.has_error then
					Result := al_l_db.last_insert_rowid
				end
			end
		end

feature -- Reset

	reset
			-- Clear all builder state
		note
			semantic_role: "[
				Returns builder to empty state for
				reuse with a different INSERT.
			]"
			modifies: "table_name, columns, value_rows, current_values"
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
		note
			semantic_role: "[
				Assembles INSERT INTO with column list
				and VALUES rows from accumulated state.
			]"
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

feature -- Model Queries

	columns_model: MML_SEQUENCE [STRING_8]
			-- Mathematical model of column names in order.
		note
			semantic_role: "[
				Provides an MML sequence model of
				column names for contract verification.
			]"
		do
			create Result
			across columns as ic loop
				Result := Result & ic
			end
		ensure
			count_matches: Result.count = columns.count
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

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		simple_sql - High-level SQLite API for Eiffel
		https://github.com/simple-eiffel/simple_sql
	]"

end
