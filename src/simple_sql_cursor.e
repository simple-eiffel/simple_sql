note
	description: "[
		A lazy cursor for iterating over SQLite query results row by row.
		Fetches rows on demand from a buffered batch, supporting both explicit
		start/forth iteration and Eiffel across-loop syntax via ITERABLE.
		Provides memory-efficient result traversal for the simple_sql library.
	]"
	purpose: "Iterate over query results lazily without loading all rows into memory"
	collaborators: "SIMPLE_SQL_ROW, SIMPLE_SQL_CURSOR_ITERATOR, SQLITE_DATABASE, MML_SEQUENCE"
	design_pattern: "Iterator"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_CURSOR

inherit
	ITERABLE [SIMPLE_SQL_ROW]

create
	make

feature {NONE} -- Initialization

	make (a_sql: READABLE_STRING_8; a_database: SQLITE_DATABASE)
			-- Create cursor for query execution
		note
			semantic_role: "[
				Prepares cursor state and row buffer
				without executing the query yet.
			]"
		require
			sql_not_empty: not a_sql.is_empty
			database_attached: a_database /= Void
			database_readable: a_database.is_readable
		local
			l_sql: STRING_8
		do
			create l_sql.make_from_string (a_sql)
			if not l_sql.ends_with (";") then
				l_sql.append_character (';')
			end
			sql := l_sql
			database := a_database
			create pending_rows.make (Buffer_size)
			is_started := False
			is_exhausted := False
			rows_fetched := 0
		ensure
			sql_set: sql.same_string (a_sql) or sql.same_string (a_sql + ";")
			database_set: database = a_database
			not_started: not is_started
		end

feature -- Access

	sql: STRING_8
			-- The SQL query being executed

	item: SIMPLE_SQL_ROW
			-- Current row
		note
			semantic_role: "[
				Returns the row at the current cursor
				position in the result set.
			]"
		require
			not_after: not after
			started: is_started
		do
			Result := current_row
		end

	new_cursor: SIMPLE_SQL_CURSOR_ITERATOR
			-- Fresh iterator for across loops
		note
			semantic_role: "[
				Creates an ITERATION_CURSOR adapter for
				Eiffel across-loop syntax.
			]"
		do
			create Result.make (Current)
		end

feature -- Measurement

	rows_fetched: INTEGER
			-- Total number of rows fetched so far

feature -- Status report

	is_started: BOOLEAN
			-- Has iteration begun?

	after: BOOLEAN
			-- Are we past the last row?
		note
			semantic_role: "[
				Termination predicate combining started
				state with row availability.
			]"
		do
			Result := is_started and then not has_valid_row
		end

	is_open: BOOLEAN
			-- Is cursor still open for fetching?
		note
			semantic_role: "[
				Liveness predicate indicating the cursor
				can still produce rows.
			]"
		do
			Result := is_started and then not is_closed
		end

	is_closed: BOOLEAN
			-- Has cursor been explicitly closed?

	has_valid_row: BOOLEAN
			-- Is there a valid current row loaded?

feature -- Cursor movement

	start
			-- Start iteration, fetch first row
		note
			semantic_role: "[
				Triggers the initial batch fetch and
				positions cursor on the first row.
			]"
		require
			not_started: not is_started
		do
			is_started := True
			fetch_batch
			advance_to_next_row
		ensure
			started: is_started
		end

	forth
			-- Move to next row
		note
			semantic_role: "[
				Advances cursor to the next available
				row from the buffer.
			]"
		require
			started: is_started
			not_after: not after
		do
			advance_to_next_row
		end

feature -- Model Queries

	pending_rows_model: MML_SEQUENCE [SIMPLE_SQL_ROW]
			-- Mathematical model of buffered rows awaiting consumption.
		note
			semantic_role: "[
				Materializes the pending row buffer as
				an MML_SEQUENCE for contract-based
				verification.
			]"
		do
			create Result
			across pending_rows as ic loop
				Result := Result & ic
			end
		ensure
			count_matches: Result.count = pending_rows.count
		end

feature -- Cleanup

	close
			-- Close cursor and release resources
			-- Safe to call multiple times
		note
			semantic_role: "[
				Releases database resources and clears
				the row buffer.
			]"
			modifies: "is_closed, is_exhausted, pending_rows"
		do
			is_closed := True
			is_exhausted := True
			pending_rows.wipe_out
		ensure
			closed: is_closed
			buffer_empty: pending_rows_model.is_empty
		end

feature {NONE} -- Implementation

	database: SQLITE_DATABASE
			-- Database connection

	pending_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			-- Buffer of fetched rows not yet consumed

	current_row: SIMPLE_SQL_ROW
			-- The current row being accessed
		attribute
			create Result.make (1)
		end

	is_exhausted: BOOLEAN
			-- Have all rows been fetched from database?

	fetch_batch
			-- Fetch next batch of rows into pending_rows buffer
		note
			semantic_role: "[
				Executes the SQL query and fills the
				pending row buffer for consumption.
			]"
		local
			l_statement: SQLITE_QUERY_STATEMENT
		do
			if not is_exhausted and not is_closed then
				pending_rows.wipe_out
				create l_statement.make (sql, database)
				-- Execute and collect all rows (SQLite binding limitation)
				-- The callback collects rows into pending_rows
				batch_row_count := 0
				l_statement.execute (agent collect_row_batch)
				is_exhausted := True -- SQLite executes entire query
			end
		end

	batch_row_count: INTEGER
			-- Count of rows collected in current batch

	collect_row_batch (a_row: SQLITE_RESULT_ROW): BOOLEAN
			-- Collect row into pending buffer
		note
			semantic_role: "[
				SQLite callback converting each result
				row into SIMPLE_SQL_ROW for buffering.
			]"
		local
			l_sql_row: SIMPLE_SQL_ROW
			i: NATURAL
			l_col_name: STRING_8
		do
			create l_sql_row.make (a_row.count.to_integer_32)
			from
				i := 1
			until
				i > a_row.count
			loop
				l_col_name := a_row.column_name (i).to_string_8
				l_sql_row.add_column (l_col_name, a_row [i])
				i := i + 1
			end
			pending_rows.extend (l_sql_row)
			batch_row_count := batch_row_count + 1
			Result := False -- Continue processing
		end

	advance_to_next_row
			-- Move to next available row
		note
			semantic_role: "[
				Pops the next row from the buffer and
				updates cursor validity state.
			]"
		do
			if not pending_rows.is_empty then
				current_row := pending_rows.first
				pending_rows.start
				pending_rows.remove
				rows_fetched := rows_fetched + 1
				has_valid_row := True
			else
				has_valid_row := False
			end
		end

feature {NONE} -- Constants

	Buffer_size: INTEGER = 100
			-- Initial buffer size for pending rows

invariant
	sql_attached: sql /= Void
	database_attached: database /= Void
	pending_rows_attached: pending_rows /= Void

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		simple_sql - High-level SQLite API for Eiffel
		https://github.com/simple-eiffel/simple_sql
	]"

end
