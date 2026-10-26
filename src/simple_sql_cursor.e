note
	description: "[
		A lazy cursor for iterating over SQLite query results row by row.
		Each `forth' steps the SQLite statement once, so only the current row
		exists in memory, supporting both explicit start/forth iteration and
		Eiffel across-loop syntax via ITERABLE. The statement is released when
		the rows run out or the cursor is closed. A cursor left before its
		last row keeps its statement, and SQLite's read lock, until `close'
		or until the collector reclaims it: close a cursor you leave early.
		A failing step or a query that does not compile ends the walk and
		sets `has_error' / `last_error_message' (scan 22).
		(2026-10-26: it used to run the whole query into a list and take rows
		off its front - every row in memory, and quadratic: 20.7 s for 88,444
		rows in a lean build.)
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
			is_started := False
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

	has_error: BOOLEAN
			-- Did the query fail to compile, or a step fail?
		do
			Result := last_error_message /= Void
		end

	last_error_message: detachable STRING_32
			-- Why the walk ended early, if it did.

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
		local
			l_statement: SQLITE_QUERY_STATEMENT
			l_failed: BOOLEAN
		do
			is_started := True
			if not l_failed and not is_closed then
				create l_statement.make (sql, database)
				statement := l_statement
				if l_statement.is_compiled then
					steps := l_statement.execute_new
				elseif attached l_statement.last_exception as al_e then
					last_error_message := al_e.tag.to_string_32
				else
					last_error_message := {STRING_32} "the query did not compile"
				end
				take_current_step
			end
		ensure
			started: is_started
		rescue
			l_failed := True
			stop_on_failure
			retry
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
		local
			l_failed: BOOLEAN
		do
			if not l_failed then
				if attached steps as al_steps then
					al_steps.forth
				end
				take_current_step
			end
		rescue
			l_failed := True
			stop_on_failure
			retry
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
			modifies: "is_closed, has_valid_row, statement"
		do
			is_closed := True
			has_valid_row := False
			finish
		ensure
			closed: is_closed
			ended: is_started implies after
			released: statement = Void
		end

feature {NONE} -- Implementation

	database: SQLITE_DATABASE
			-- Database connection

	current_row: SIMPLE_SQL_ROW
			-- The current row being accessed
		attribute
			create Result.make (1)
		end

	statement: detachable SQLITE_QUERY_STATEMENT
			-- The running statement, until the rows run out or `close'.

	steps: detachable SQLITE_STATEMENT_ITERATION_CURSOR
			-- `statement' stepped one row at a time.

	take_current_step
			-- Make the statement's current row `current_row', or finish.
		do
			if attached steps as al_steps and then not al_steps.after then
				create current_row.make_from_sqlite (al_steps.item)
				rows_fetched := rows_fetched + 1
				has_valid_row := True
			else
				has_valid_row := False
				finish
			end
		end

	finish
			-- Release the statement (the rows ran out, or `close').
		do
			steps := Void
			if attached statement as al_statement then
				al_statement.cleanup
				statement := Void
			end
		ensure
			released: statement = Void and steps = Void
		end

	stop_on_failure
			-- A step or the start raised: keep SQLite's reason, end the walk.
		do
			if attached database.last_exception as al_e then
				last_error_message := al_e.tag.to_string_32
			elseif attached {EXCEPTION_MANAGER_FACTORY}.exception_manager.last_exception as al_x
				and then attached al_x.description as al_d
			then
				last_error_message := al_d.to_string_32
			else
				last_error_message := {STRING_32} "a step failed"
			end
			has_valid_row := False
			finish
		ensure
			said: has_error
			ended: not has_valid_row and statement = Void
		end

invariant
	sql_attached: sql /= Void
	database_attached: database /= Void
	released_when_closed: is_closed implies statement = Void

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		simple_sql - High-level SQLite API for Eiffel
		https://github.com/simple-eiffel/simple_sql
	]"

end
