note
	description: "[
		A streaming query processor that delivers rows one at a time via callbacks.
		Executes SQL through SQLITE_QUERY_STATEMENT and invokes a user-supplied
		function or procedure agent for each row, supporting early termination
		and bounded collection without buffering the entire result set.
		Enables memory-efficient processing of large datasets in the simple_sql library.
	]"
	purpose: "Stream query rows one at a time through callback agents for memory-efficient processing"
	collaborators: "SIMPLE_SQL_ROW, SQLITE_DATABASE, SQLITE_QUERY_STATEMENT, SQLITE_RESULT_ROW"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_RESULT_STREAM

create
	make

feature {NONE} -- Initialization

	make (a_sql: READABLE_STRING_8; a_database: SQLITE_DATABASE)
			-- Create stream for query
		note
			semantic_role: "[
				Captures query and database reference
				for deferred streaming execution.
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
			rows_processed := 0
			was_stopped_early := False
		ensure
			sql_set: sql.same_string (a_sql) or sql.same_string (a_sql + ";")
			database_set: database = a_database
		end

feature -- Access

	sql: STRING_8
			-- The SQL query

	rows_processed: INTEGER
			-- Number of rows processed in last stream operation

	was_stopped_early: BOOLEAN
			-- Did last stream operation stop before exhausting results?

feature -- Streaming operations

	for_each (a_action: FUNCTION [SIMPLE_SQL_ROW, BOOLEAN])
			-- Process each row with action
			-- Action returns True to stop early, False to continue
		note
			semantic_role: "[
				Streams rows through a boolean-returning
				function for processing with early
				termination.
			]"
		require
			action_attached: a_action /= Void
		local
			l_statement: SQLITE_QUERY_STATEMENT
		do
			rows_processed := 0
			was_stopped_early := False
			current_action := a_action
			create l_statement.make (sql, database)
			l_statement.execute (agent process_row)
			current_action := Void
		end

	for_each_do (a_procedure: PROCEDURE [SIMPLE_SQL_ROW])
			-- Process each row with procedure (processes all rows)
		note
			semantic_role: "[
				Streams all rows through a procedure
				agent without early termination.
			]"
		require
			procedure_attached: a_procedure /= Void
		local
			l_statement: SQLITE_QUERY_STATEMENT
		do
			rows_processed := 0
			was_stopped_early := False
			current_procedure := a_procedure
			create l_statement.make (sql, database)
			l_statement.execute (agent process_row_procedure)
			current_procedure := Void
		end

	collect_first (a_count: INTEGER): ARRAYED_LIST [SIMPLE_SQL_ROW]
			-- Collect first `a_count` rows (memory-bounded)
		note
			semantic_role: "[
				Materializes a bounded prefix of the
				result set into a list.
			]"
		require
			positive_count: a_count > 0
		local
			l_statement: SQLITE_QUERY_STATEMENT
		do
			create Result.make (a_count)
			rows_processed := 0
			was_stopped_early := False
			collect_target := Result
			collect_limit := a_count
			create l_statement.make (sql, database)
			l_statement.execute (agent collect_row_limited)
			collect_target := Void
		ensure
			result_bounded: Result.count <= a_count
		end

	count_rows: INTEGER
			-- Count total rows (processes all)
		note
			semantic_role: "[
				Counts rows by streaming through the
				entire result set.
			]"
		local
			l_statement: SQLITE_QUERY_STATEMENT
		do
			rows_processed := 0
			was_stopped_early := False
			create l_statement.make (sql, database)
			l_statement.execute (agent count_row)
			Result := rows_processed
		end

	first_row: detachable SIMPLE_SQL_ROW
			-- Get first row only
		note
			semantic_role: "[
				Convenience accessor collecting and
				returning just the first result row.
			]"
		local
			l_result: ARRAYED_LIST [SIMPLE_SQL_ROW]
		do
			l_result := collect_first (1)
			if not l_result.is_empty then
				Result := l_result.first
			end
		end

	exists: BOOLEAN
			-- Does at least one row exist?
		note
			semantic_role: "[
				Existence check delegating to first_row
				for boolean result.
			]"
		do
			Result := first_row /= Void
		end

feature {NONE} -- Implementation

	database: SQLITE_DATABASE
			-- Database connection

	current_action: detachable FUNCTION [SIMPLE_SQL_ROW, BOOLEAN]
			-- Current action being executed

	current_procedure: detachable PROCEDURE [SIMPLE_SQL_ROW]
			-- Current procedure being executed

	collect_target: detachable ARRAYED_LIST [SIMPLE_SQL_ROW]
			-- Target list for collect operations

	collect_limit: INTEGER
			-- Maximum rows to collect

	process_row (a_row: SQLITE_RESULT_ROW): BOOLEAN
			-- Process single row via current action
		note
			semantic_role: "[
				SQLite callback converting result row
				and delegating to the user's function
				agent.
			]"
		local
			l_sql_row: SIMPLE_SQL_ROW
		do
			l_sql_row := convert_row (a_row)
			rows_processed := rows_processed + 1
			if attached current_action as al_l_action then
				Result := al_l_action.item ([l_sql_row])
				if Result then
					was_stopped_early := True
				end
			end
		end

	process_row_procedure (a_row: SQLITE_RESULT_ROW): BOOLEAN
			-- Process single row via current procedure
		note
			semantic_role: "[
				SQLite callback converting result row
				and delegating to the user's procedure
				agent.
			]"
		local
			l_sql_row: SIMPLE_SQL_ROW
		do
			l_sql_row := convert_row (a_row)
			rows_processed := rows_processed + 1
			if attached current_procedure as al_l_proc then
				al_l_proc.call ([l_sql_row])
			end
			Result := False -- Continue processing
		end

	collect_row_limited (a_row: SQLITE_RESULT_ROW): BOOLEAN
			-- Collect row if under limit
		note
			semantic_role: "[
				SQLite callback collecting rows into a
				bounded target list.
			]"
		local
			l_sql_row: SIMPLE_SQL_ROW
		do
			if attached collect_target as l_target and then l_target.count < collect_limit then
				l_sql_row := convert_row (a_row)
				l_target.extend (l_sql_row)
				rows_processed := rows_processed + 1
				Result := l_target.count >= collect_limit -- Stop when limit reached
				if Result then
					was_stopped_early := True
				end
			else
				Result := True -- Stop
				was_stopped_early := True
			end
		end

	count_row (a_row: SQLITE_RESULT_ROW): BOOLEAN
			-- Just count the row
		note
			semantic_role: "[
				SQLite callback that only increments
				the row counter.
			]"
		do
			rows_processed := rows_processed + 1
			Result := False -- Continue
		end

	convert_row (a_row: SQLITE_RESULT_ROW): SIMPLE_SQL_ROW
			-- Convert SQLite row to SIMPLE_SQL_ROW
		note
			semantic_role: "[
				Maps low-level SQLITE_RESULT_ROW columns
				into a SIMPLE_SQL_ROW.
			]"
		local
			i: NATURAL
			l_col_name: STRING_8
		do
			create Result.make (a_row.count.to_integer_32)
			from
				i := 1
			until
				i > a_row.count
			loop
				l_col_name := a_row.column_name (i).to_string_8
				Result.add_column (l_col_name, a_row [i])
				i := i + 1
			end
		end

invariant
	sql_attached: sql /= Void
	database_attached: database /= Void
	rows_processed_non_negative: rows_processed >= 0

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		simple_sql - High-level SQLite API for Eiffel
		https://github.com/simple-eiffel/simple_sql
	]"

end
