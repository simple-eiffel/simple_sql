note
	description: "[
		The primary facade for all SQLite database operations in the simple_sql library.
		Wraps ISE's SQLITE_DATABASE with a high-level API providing execute, query,
		prepared statements, transactions, query builders, streaming, and N+1 detection.
		Serves as the single entry point to all database subsystems including schema,
		FTS5, JSON, audit, and PRAGMA configuration.
	]"
	purpose: "Provide a high-level, contract-driven facade for SQLite database operations"
	collaborators: "SQLITE_DATABASE, SIMPLE_SQL_RESULT, SIMPLE_SQL_ROW, SIMPLE_SQL_PREPARED_STATEMENT, SIMPLE_SQL_SCHEMA, SIMPLE_SQL_ERROR, SIMPLE_SQL_QUERY_MONITOR"
	design_pattern: "Facade"
	EIS: "name=API Reference", "src=../docs/api/database.html", "protocol=URI", "tag=documentation"
	EIS: "name=Getting Started", "src=../docs/getting-started.html", "protocol=URI", "tag=tutorial"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_DATABASE

inherit
	DISPOSABLE

create
	make,
	make_memory,
	make_read_only

feature {NONE} -- Initialization

	make (a_file_name: READABLE_STRING_GENERAL)
			-- Create/open database file in read-write mode
		note
			semantic_role: "[
				Opens or creates a persistent database
				file for read-write operations.
			]"
		require
			file_name_not_empty: not a_file_name.is_empty
		do
			create internal_db.make_create_read_write (a_file_name)
			file_name := a_file_name.to_string_32
		ensure
			is_open: is_open
			file_name_set: file_name ~ a_file_name.to_string_32
		end

	make_memory
			-- Create in-memory database
		note
			semantic_role: "[
				Creates an ephemeral in-memory database
				for testing and temporary operations.
			]"
		do
			create internal_db.make (create {SQLITE_IN_MEMORY_SOURCE})
			internal_db.open_create_read_write
			create file_name.make_from_string (":memory:")
		ensure
			is_open: is_open
			in_memory: file_name ~ ":memory:"
		end

	make_read_only (a_file_name: READABLE_STRING_GENERAL)
			-- Open existing database file in read-only mode
		note
			semantic_role: "[
				Opens an existing database in read-only
				mode for safe concurrent access.
			]"
		require
			file_name_not_empty: not a_file_name.is_empty
			file_exists: (create {RAW_FILE}.make_with_name (a_file_name)).exists
		do
			create internal_db.make_open_read (a_file_name)
			file_name := a_file_name.to_string_32
		ensure
			is_open: is_open
			file_name_set: file_name ~ a_file_name.to_string_32
		end

feature -- Access

	file_name: STRING_32
			-- Database file name or ":memory:"

	last_structured_error: detachable SIMPLE_SQL_ERROR
			-- Structured error from last failed operation.
			-- Inside a failed transaction this stays attached (sticky) until the transaction ends.

	transaction_error: detachable SIMPLE_SQL_ERROR
			-- First error raised by a statement inside the open transaction (Void when none).
			-- A transaction with such an error is failed: `commit' rolls it back instead of committing.

	last_error_message: detachable STRING_32
			-- Error message from last failed operation
		note
			semantic_role: "[
				Convenience accessor extracting error
				message from structured error for
				quick diagnostics.
			]"
		do
			if attached last_structured_error as al_l_err then
				Result := al_l_err.message
			end
		end

	last_error_code: INTEGER
			-- Error code from last operation (0 = success)
		note
			semantic_role: "[
				Convenience accessor extracting error
				code from structured error for
				programmatic error handling.
			]"
		do
			if attached last_structured_error as al_l_err then
				Result := al_l_err.code
			end
		ensure
			zero_when_no_error: not has_error implies Result = 0
		end

	error_codes: SIMPLE_SQL_ERROR_CODE
			-- Access to error code constants for comparisons
			-- Usage: if db.last_error_code = db.error_codes.constraint then ...
		note
			semantic_role: "[
				Provides error code constants for
				programmatic comparison without
				hardcoded integers.
			]"
		once
			create Result
		end

	changes_count,
	rows_affected,
	modified_count: INTEGER
			-- Number of rows modified by last operation
		note
			semantic_role: "[
				Reports modification count for verifying
				INSERT/UPDATE/DELETE effects.
			]"
		require
			is_open: is_open
		do
			Result := internal_db.changes_count.to_integer_32
		end

	is_in_transaction: BOOLEAN
			-- Is database currently in a transaction?
		note
			semantic_role: "[
				Transaction state predicate for
				precondition guards on commit and
				rollback.
			]"
		require
			is_open: is_open
		do
			Result := internal_db.is_in_transaction
		end

feature -- Status report

	is_transaction_failed: BOOLEAN
			-- Did a statement fail inside the open transaction?
		note
			semantic_role: "[
				Failed-transaction predicate: once True, the
				transaction can only be rolled back, and
				has_error stays True until it ends.
			]"
		do
			Result := transaction_error /= Void
		ensure
			definition: Result = (transaction_error /= Void)
		end

	is_open,
	connected,
	is_connected: BOOLEAN
			-- Is database connection open?
		note
			semantic_role: "[
				Connection state predicate used as
				precondition guard on all database
				operations.
			]"
		do
			Result := not internal_db.is_closed
		end

	has_error,
	failed,
	error_occurred: BOOLEAN
			-- Did last operation fail?
		note
			semantic_role: "[
				Error state predicate for checking
				operation success before proceeding.
			]"
		do
			Result := last_structured_error /= Void
		ensure
			error_attached: Result implies last_structured_error /= Void
		end

feature -- Error status queries

	is_constraint_error: BOOLEAN
			-- Was last error a constraint violation?
		note
			semantic_role: "[
				Constraint violation classification for
				handling UNIQUE, NOT NULL, and CHECK
				failures.
			]"
		do
			Result := attached last_structured_error as l_err and then l_err.is_constraint_violation
		end

	is_busy_error: BOOLEAN
			-- Was last error due to database being busy/locked?
		note
			semantic_role: "[
				Busy/locked classification for retry
				logic in concurrent access scenarios.
			]"
		do
			Result := attached last_structured_error as l_err and then l_err.is_busy
		end

	is_readonly_error: BOOLEAN
			-- Was last error due to readonly database?
		note
			semantic_role: "[
				Readonly classification for detecting
				write attempts on read-only connections.
			]"
		do
			Result := attached last_structured_error as l_err and then l_err.is_readonly
		end

feature -- Basic operations

	execute,
	run_sql,
	exec,
	run_statement,
	perform (a_sql: READABLE_STRING_8)
			-- Execute SQL statement (INSERT, UPDATE, DELETE, CREATE, etc)
		note
			semantic_role: "[
				Primary command execution entry point
				for all non-query SQL statements.
			]"
		require
			is_open: is_open
			sql_not_empty: not a_sql.is_empty
		local
			l_statement: SQLITE_MODIFY_STATEMENT
			l_sql: STRING_8
		do
			clear_error
			create l_sql.make_from_string (a_sql)
			if not l_sql.ends_with (";") then
				l_sql.append_character (';')
			end
			create l_statement.make (l_sql, internal_db)
			if l_statement.is_compiled then
				l_statement.execute
			end
			if l_statement.has_error and then attached l_statement.last_exception as al_ex then
				record_error (error_from_sqlite_exception (al_ex, a_sql))
			else
				check_and_set_error (a_sql)
			end
			l_statement.cleanup
		ensure
			sticky_in_failed_transaction: is_transaction_failed implies has_error
		rescue
			set_error_from_exception (a_sql)
		end

	query,
	select_rows,
	fetch,
	query_sql,
	run_query (a_sql: READABLE_STRING_8): SIMPLE_SQL_RESULT
			-- Execute query and return results
		note
			semantic_role: "[
				Primary query execution entry point
				returning eagerly-loaded result rows.
			]"
		require
			is_open: is_open
			sql_not_empty: not a_sql.is_empty
		local
			l_sql: STRING_8
		do
			clear_error
			-- Record query for N+1 detection
			if attached query_monitor as m and then m.is_enabled then
				m.record_query (a_sql)
			end
			create l_sql.make_from_string (a_sql)
			if not l_sql.ends_with (";") then
				l_sql.append_character (';')
			end
			create Result.make (l_sql, internal_db)
			check_and_set_error (a_sql)
		ensure
			sticky_in_failed_transaction: is_transaction_failed implies has_error
		rescue
			set_error_from_exception (a_sql)
			create Result.make_empty
		end

feature -- Parameterized Operations (convenience methods)

	execute_with_args,
	run_sql_with,
	exec_with,
	perform_with (a_sql: READABLE_STRING_8; a_args: ARRAY [detachable ANY])
			-- Execute SQL with parameters. Use ? placeholders.
			-- Supported types: INTEGER, INTEGER_64, REAL_64, STRING, BOOLEAN, MANAGED_POINTER, Void (NULL)
			-- Example: execute_with_args ("INSERT INTO t (a, b) VALUES (?, ?)", <<123, "text">>)
			-- Note: the values are escaped and substituted into the SQL text as literals (strings quoted,
			-- quotes doubled; BLOBs as X'..' literals); SQLite bind variables are not used.
			-- A failure is reported through `has_error' and `last_error_message'.
		note
			semantic_role: "[
				Parameterized command execution with
				escaped literal substitution; failures
				reported like execute.
			]"
		require
			is_open: is_open
			sql_not_empty: not a_sql.is_empty
		local
			l_stmt: SIMPLE_SQL_PREPARED_STATEMENT
		do
			clear_error
			l_stmt := prepare (a_sql)
			bind_args (l_stmt, a_args)
			l_stmt.execute
			if attached l_stmt.last_error as al_err then
				record_error (al_err)
			end
		ensure
			statement_failure_reported: not has_error implies not is_transaction_failed
		end

	query_with_args,
	select_rows_with,
	fetch_with,
	query_sql_with (a_sql: READABLE_STRING_8; a_args: ARRAY [detachable ANY]): SIMPLE_SQL_RESULT
			-- Execute query with parameters. Use ? placeholders.
			-- Supported types: INTEGER, INTEGER_64, REAL_64, STRING, BOOLEAN, Void (NULL)
			-- Example: query_with_args ("SELECT * FROM t WHERE id = ?", <<123>>)
		note
			semantic_role: "[
				Parameterized query execution preventing
				SQL injection via bind variables.
			]"
		require
			is_open: is_open
			sql_not_empty: not a_sql.is_empty
		local
			l_stmt: SIMPLE_SQL_PREPARED_STATEMENT
		do
			clear_error
			l_stmt := prepare (a_sql)
			bind_args (l_stmt, a_args)
			Result := l_stmt.execute_returning_result
			if attached l_stmt.last_error as al_err then
				record_error (al_err)
			end
		end

	begin_transaction
			-- Begin transaction (deferred mode)
		note
			semantic_role: "[
				Starts a deferred transaction for
				grouping multiple operations atomically.
			]"
		require
			is_open: is_open
		do
			transaction_error := Void
			clear_error
			internal_db.begin_transaction (True)
			check_and_set_error ("BEGIN")
		ensure
			fresh_transaction: not is_transaction_failed
			begun_or_reported: not has_error implies is_in_transaction
		end

	commit
			-- Commit current transaction.
			-- A failed transaction (`is_transaction_failed') is rolled back instead, keeping its error.
			-- A failed COMMIT is reported (`has_error'); SQLite may keep the transaction open
			-- (`is_in_transaction'), in which case retry `commit' or call `rollback'.
		note
			semantic_role: "[
				Makes all changes within the current
				transaction permanent, or refuses to
				when a statement in it failed.
			]"
		require
			is_open: is_open
			in_transaction: is_in_transaction
		do
			commit_or_refuse
		ensure
			failed_transaction_not_committed: old is_transaction_failed implies has_error
			open_transaction_reported: is_in_transaction implies has_error
			clean_commit: not has_error implies not is_in_transaction
		end

	rollback
			-- Rollback current transaction.
			-- The error that led the caller here (if any) is kept for the caller to read.
		note
			semantic_role: "[
				Discards all changes within the current
				transaction, keeping the error that
				caused it.
			]"
		require
			is_open: is_open
			in_transaction: is_in_transaction
		do
			rollback_keeping_error
		ensure
			error_kept: old has_error implies has_error
		end

	close
			-- Close database connection
		note
			semantic_role: "[
				Releases the database connection and
				associated resources.
			]"
		do
			if not internal_db.is_closed then
				if internal_db.is_in_transaction then
						-- For example a COMMIT that failed: SQLite would roll back on close anyway,
						-- but SQLITE_DATABASE.close requires no open transaction.
					rollback_keeping_error
				end
				internal_db.close
			end
			transaction_error := Void
		ensure
			is_closed: not is_open
		end

feature {NONE} -- Error handling implementation

	clear_error
			-- Clear any previous error, except inside a failed transaction, where the
			-- transaction's first error stays (errors are sticky until the transaction ends).
		note
			semantic_role: "[
				Resets error state before each operation
				so has_error reflects the latest operation,
				or the failed transaction it belongs to.
			]"
		do
			last_structured_error := transaction_error
		ensure
			sticky: has_error = is_transaction_failed
		end

	record_error (a_error: SIMPLE_SQL_ERROR)
			-- Make `a_error' the last error; inside a transaction, mark the transaction failed.
		do
			last_structured_error := a_error
			if transaction_error = Void and then is_open and then internal_db.is_in_transaction then
				transaction_error := a_error
			end
		ensure
			has_error: has_error
		end

	error_from_sqlite_exception (a_exception: SQLITE_EXCEPTION; a_sql: READABLE_STRING_GENERAL): SIMPLE_SQL_ERROR
			-- Structured error carrying SQLite's code and message from `a_exception'.
		local
			l_message: STRING_32
		do
				-- SQLITE_EXCEPTION carries sqlite3_errmsg in `tag'; `description' is usually Void.
			if attached a_exception.tag as al_tag and then not al_tag.is_empty then
				l_message := al_tag.to_string_32
			elseif attached a_exception.description as al_desc and then not al_desc.is_empty then
				l_message := al_desc.to_string_32
			else
				l_message := "Unknown error"
			end
			create Result.make_with_sql (a_exception.result_code, l_message, a_sql)
		end

	commit_or_refuse
			-- COMMIT, or roll back a failed transaction; report the outcome.
		require
			is_open: is_open
			in_transaction: is_in_transaction
		do
			if is_transaction_failed then
				rollback_keeping_error
			else
				internal_db.commit
				if internal_db.has_error and then attached internal_db.last_exception as al_ex then
						-- Report the failed COMMIT without failing the transaction, so a retry is possible.
					last_structured_error := error_from_sqlite_exception (al_ex, "COMMIT")
				elseif internal_db.is_in_transaction then
					create last_structured_error.make_with_sql (error_codes.error, "COMMIT did not end the transaction", "COMMIT")
				else
					last_structured_error := Void
					transaction_error := Void
				end
			end
		end

	rollback_keeping_error
			-- ROLLBACK; keep the error the caller is about to read, or report a failed ROLLBACK.
		require
			is_open: is_open
		local
			l_kept: like last_structured_error
		do
			l_kept := last_structured_error
			if l_kept = Void then
				l_kept := transaction_error
			end
			internal_db.rollback
			if internal_db.is_in_transaction then
				if l_kept = Void and then attached internal_db.last_exception as al_ex then
					l_kept := error_from_sqlite_exception (al_ex, "ROLLBACK")
				end
			else
				transaction_error := Void
			end
			last_structured_error := l_kept
		ensure
			error_kept: (old last_structured_error /= Void) implies has_error
		end

	exception_description: STRING_32
			-- Text describing the exception being handled, for `atomic''s report.
		do
			create Result.make_from_string ("Operation raised an exception; transaction rolled back")
			if attached {EXCEPTION_MANAGER_FACTORY}.exception_manager.last_exception as al_ex then
				Result.append_string_general (": ")
				Result.append_string_general (al_ex.generating_type.name)
				if attached al_ex.description as al_desc then
					Result.append_string_general (" ")
					Result.append_string_general (al_desc)
				end
			end
		end

	check_and_set_error (a_sql: READABLE_STRING_GENERAL)
			-- Check internal_db for error and set structured error if found
		note
			semantic_role: "[
				Translates internal SQLite error state
				into structured SIMPLE_SQL_ERROR after
				operation completion.
			]"
		do
			if internal_db.has_error then
				set_error_from_exception (a_sql)
			end
		end

	set_error_from_exception (a_sql: READABLE_STRING_GENERAL)
			-- Set structured error from internal_db exception
		note
			semantic_role: "[
				Captures SQLite exception details into
				structured error with code, message,
				and SQL context.
			]"
		do
			if is_open and then attached internal_db.last_exception as al_l_exception then
				record_error (error_from_sqlite_exception (al_l_exception, a_sql))
			else
				-- Exception without details
				record_error (create {SIMPLE_SQL_ERROR}.make_with_sql (
					error_codes.error,
					"Unknown database error",
					a_sql
				))
			end
		ensure
			has_error: has_error
		end

feature -- Attached databases

	attach_read_only (a_file_name: READABLE_STRING_GENERAL; a_schema: READABLE_STRING_8)
			-- Attach the existing database file `a_file_name' as schema `a_schema', READ-ONLY.
			-- Works on a read-only connection (`make_read_only') as well as a read-write one, and the
			-- attachment stays read-only either way: it is opened through a "file:" URI with mode=ro.
			-- A missing file is reported (`has_error'), never created.
		note
			semantic_role: "[
				Supported read-only ATTACH, including on a
				read-only connection, where execute cannot
				run ATTACH.
			]"
		require
			is_open: is_open
			file_name_not_empty: not a_file_name.is_empty
			valid_schema_name: is_valid_schema_name (a_schema)
			not_yet_attached: not is_attached (a_schema)
		do
			clear_error
			run_without_write_check ("ATTACH DATABASE '" + read_only_uri (a_file_name) + "' AS " + a_schema)
		ensure
			attached_on_success: not has_error implies is_attached (a_schema)
		end

	detach (a_schema: READABLE_STRING_8)
			-- Detach the database attached as `a_schema'.
		note
			semantic_role: "[
				Releases an attached database; works on
				read-only connections too.
			]"
		require
			is_open: is_open
			valid_schema_name: is_valid_schema_name (a_schema)
			is_attached: is_attached (a_schema)
		do
			clear_error
			run_without_write_check ("DETACH DATABASE " + a_schema)
		ensure
			detached_on_success: not has_error implies not is_attached (a_schema)
		end

	is_attached (a_schema: READABLE_STRING_8): BOOLEAN
			-- Is a database attached under schema name `a_schema' (case-insensitive)?
		require
			is_open: is_open
		local
			l_list: SIMPLE_SQL_RESULT
		do
			create l_list.make ("PRAGMA database_list;", internal_db)
			across l_list.rows as ic loop
				if attached {READABLE_STRING_GENERAL} ic.item (2) as al_name and then al_name.is_case_insensitive_equal (a_schema) then
					Result := True
				end
			end
		end

	is_valid_schema_name (a_schema: READABLE_STRING_8): BOOLEAN
			-- Is `a_schema' a plain identifier usable as an attachment name (not main or temp)?
		local
			i: INTEGER
			c: CHARACTER_8
		do
			Result := not a_schema.is_empty and then (a_schema [1].is_alpha or a_schema [1] = '_')
				and then not a_schema.is_case_insensitive_equal ("main")
				and then not a_schema.is_case_insensitive_equal ("temp")
			from i := 2 until not Result or i > a_schema.count loop
				c := a_schema [i]
				Result := c.is_alpha_numeric or c = '_'
				i := i + 1
			end
		end

	read_only_uri (a_file_name: READABLE_STRING_GENERAL): STRING_8
			-- SQLite "file:" URI for `a_file_name' with mode=ro: UTF-8, '\' as '/', and every byte
			-- other than letters, digits and - . _ ~ / : percent-encoded (so '?', '#', '%', ' ' and
			-- quotes are safe). An absolute Windows path X:\... becomes file:///X:/...
		local
			l_utf: UTF_CONVERTER
			l_path: STRING_8
			i: INTEGER
			c: CHARACTER_8
		do
			l_path := l_utf.utf_32_string_to_utf_8_string_8 (a_file_name.to_string_32)
			l_path.replace_substring_all ("\", "/")
			create Result.make (l_path.count + 20)
			Result.append ("file:")
			if l_path.count >= 2 and then l_path [1].is_alpha and then l_path [2] = ':' then
				Result.append ("///")
			elseif l_path.starts_with ("//") then
				Result.append ("//")
			end
			from i := 1 until i > l_path.count loop
				c := l_path [i]
				if c.is_alpha_numeric or c = '-' or c = '.' or c = '_' or c = '~' or c = '/' or c = ':' then
					Result.append_character (c)
				else
					Result.append_character ('%%')
					Result.append_string (c.code.to_hex_string.substring (7, 8))
				end
				i := i + 1
			end
			Result.append ("?mode=ro")
		ensure
			is_uri: Result.starts_with ("file:")
			read_only: Result.ends_with ("?mode=ro")
			no_quote: not Result.has ('%'')
		end

feature {NONE} -- Attached databases implementation

	run_without_write_check (a_sql: READABLE_STRING_8)
			-- Run `a_sql' (ATTACH or DETACH) through a query statement, which, unlike a modify
			-- statement, does not require a writable connection; report any failure.
		require
			is_open: is_open
		local
			l_statement: SQLITE_QUERY_STATEMENT
		do
			create l_statement.make (a_sql + ";", internal_db)
			if l_statement.is_compiled then
				l_statement.execute (agent (a_row: SQLITE_RESULT_ROW): BOOLEAN do Result := True end)
			end
			if l_statement.has_error and then attached l_statement.last_exception as al_ex then
				record_error (error_from_sqlite_exception (al_ex, a_sql))
			else
				check_and_set_error (a_sql)
			end
			l_statement.cleanup
		end

feature -- Prepared Statements

	prepare,
	prepare_statement,
	create_statement,
	compile_sql (a_sql: READABLE_STRING_8): SIMPLE_SQL_PREPARED_STATEMENT
			-- Create prepared statement for given SQL
		note
			semantic_role: "[
				Creates a reusable prepared statement
				for repeated execution with different
				parameters.
			]"
		require
			is_open: is_open
			sql_not_empty: not a_sql.is_empty
		do
			create Result.make (a_sql, internal_db)
		ensure
			result_attached: Result /= Void
		end

feature -- Query Builders

	select_builder: SIMPLE_SQL_SELECT_BUILDER
			-- Create SELECT query builder for this database
		note
			semantic_role: "[
				Factory for fluent SELECT query
				construction bound to this database.
			]"
		require
			is_open: is_open
		do
			create Result.make_with_database (Current)
		ensure
			result_attached: Result /= Void
			database_set: Result.database = Current
		end

	insert_builder: SIMPLE_SQL_INSERT_BUILDER
			-- Create INSERT query builder for this database
		note
			semantic_role: "[
				Factory for fluent INSERT statement
				construction bound to this database.
			]"
		require
			is_open: is_open
		do
			create Result.make_with_database (Current)
		ensure
			result_attached: Result /= Void
			database_set: Result.database = Current
		end

	update_builder: SIMPLE_SQL_UPDATE_BUILDER
			-- Create UPDATE query builder for this database
		note
			semantic_role: "[
				Factory for fluent UPDATE statement
				construction bound to this database.
			]"
		require
			is_open: is_open
		do
			create Result.make_with_database (Current)
		ensure
			result_attached: Result /= Void
			database_set: Result.database = Current
		end

	delete_builder: SIMPLE_SQL_DELETE_BUILDER
			-- Create DELETE query builder for this database
		note
			semantic_role: "[
				Factory for fluent DELETE statement
				construction bound to this database.
			]"
		require
			is_open: is_open
		do
			create Result.make_with_database (Current)
		ensure
			result_attached: Result /= Void
			database_set: Result.database = Current
		end

	eager_loader: SIMPLE_SQL_EAGER_LOADER
			-- Create eager loader to prevent N+1 queries.
		note
			semantic_role: "[
				Factory for batch loading related
				records, preventing N+1 query
				performance problems.
			]"
		require
			is_open: is_open
		do
			create Result.make (Current)
		ensure
			result_attached: Result /= Void
		end

	paginator (a_table: READABLE_STRING_8): SIMPLE_SQL_PAGINATOR
			-- Create paginator for cursor-based pagination.
		note
			semantic_role: "[
				Factory for cursor-based pagination
				delivering bounded result pages.
			]"
		require
			is_open: is_open
			table_not_empty: not a_table.is_empty
		do
			create Result.make (Current, a_table)
		ensure
			result_attached: Result /= Void
		end

feature -- Streaming and Cursor Queries

	query_cursor (a_sql: READABLE_STRING_8): SIMPLE_SQL_CURSOR
			-- Execute query returning lazy cursor for row-by-row iteration
			-- Use for large result sets to avoid loading all rows into memory
		note
			semantic_role: "[
				Lazy row-by-row iteration for large
				result sets without full memory
				allocation.
			]"
		require
			is_open: is_open
			sql_not_empty: not a_sql.is_empty
		do
			clear_error
			create Result.make (a_sql, internal_db)
		ensure
			result_attached: Result /= Void
		end

	query_stream (a_sql: READABLE_STRING_8; a_action: FUNCTION [SIMPLE_SQL_ROW, BOOLEAN])
			-- Execute query and process each row via callback action
			-- Action returns True to stop early, False to continue
		note
			semantic_role: "[
				Callback-driven row processing for
				streaming results with early
				termination support.
			]"
		require
			is_open: is_open
			sql_not_empty: not a_sql.is_empty
			action_attached: a_action /= Void
		local
			l_stream: SIMPLE_SQL_RESULT_STREAM
		do
			clear_error
			create l_stream.make (a_sql, internal_db)
			l_stream.for_each (a_action)
		end

	create_stream (a_sql: READABLE_STRING_8): SIMPLE_SQL_RESULT_STREAM
			-- Create stream object for advanced streaming operations
			-- (for_each, aggregate, collect_first, etc.)
		note
			semantic_role: "[
				Factory for advanced streaming operations
				including aggregation and partial
				collection.
			]"
		require
			is_open: is_open
			sql_not_empty: not a_sql.is_empty
		do
			clear_error
			create Result.make (a_sql, internal_db)
		ensure
			result_attached: Result /= Void
		end

feature -- Schema Introspection

	schema: SIMPLE_SQL_SCHEMA
			-- Create schema inspector for this database
		note
			semantic_role: "[
				Factory for runtime schema discovery
				via SQLite PRAGMAs.
			]"
		require
			is_open: is_open
		do
			create Result.make (Current)
		ensure
			result_attached: Result /= Void
		end

feature -- Full-Text Search

	fts5: SIMPLE_SQL_FTS5
			-- Create FTS5 full-text search manager for this database
		note
			semantic_role: "[
				Factory for full-text search operations
				using SQLite's FTS5 extension.
			]"
		require
			is_open: is_open
		do
			create Result.make (Current)
		ensure
			result_attached: Result /= Void
		end

feature -- JSON Support

	json: SIMPLE_SQL_JSON
			-- Create JSON helper for advanced JSON operations (JSON1 extension)
		note
			semantic_role: "[
				Factory for JSON operations using
				SQLite's JSON1 extension.
			]"
		require
			is_open: is_open
		do
			create Result.make (Current)
		ensure
			result_attached: Result /= Void
		end

feature -- Audit/Change Tracking

	audit: SIMPLE_SQL_AUDIT
			-- Create audit manager for automatic change tracking
		note
			semantic_role: "[
				Factory for automatic change tracking
				with trigger-based audit trails.
			]"
		require
			is_open: is_open
		do
			create Result.make (Current)
		ensure
			result_attached: Result /= Void
		end

feature -- BLOB Utilities

	read_blob_from_file (a_file_path: STRING_32): detachable MANAGED_POINTER
			-- Read binary file into MANAGED_POINTER for use with BLOB columns
			-- Returns Void if file cannot be read
		note
			semantic_role: "[
				File-to-BLOB bridge for inserting
				binary file contents into BLOB columns.
			]"
		require
			file_path_not_empty: not a_file_path.is_empty
		local
			l_file: RAW_FILE
			l_size: INTEGER
		do
			create l_file.make_with_name (a_file_path)
			if l_file.exists and then l_file.is_readable then
				l_file.open_read
				l_size := l_file.count
				create Result.make (l_size)
				l_file.read_to_managed_pointer (Result, 0, l_size)
				l_file.close
			end
		end

	write_blob_to_file (a_blob: MANAGED_POINTER; a_file_path: STRING_32)
			-- Write BLOB data (MANAGED_POINTER) to file
			-- Creates or overwrites the file at a_file_path
		note
			semantic_role: "[
				BLOB-to-file bridge for extracting
				binary column data to the filesystem.
			]"
		require
			blob_not_void: a_blob /= Void
			file_path_not_empty: not a_file_path.is_empty
		local
			l_file: RAW_FILE
		do
			create l_file.make_create_read_write (a_file_path)
			l_file.put_managed_pointer (a_blob, 0, a_blob.count)
			l_file.close
		end

feature -- Additional Accessors

	last_insert_rowid: INTEGER_64
			-- Row ID of last inserted row
		note
			semantic_role: "[
				Retrieves SQLite's last_insert_rowid
				for obtaining auto-generated primary
				keys.
			]"
		require
			is_open: is_open
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create l_result.make ("SELECT last_insert_rowid();", internal_db)
			if not l_result.rows.is_empty and then attached l_result.rows.first as al_l_row then
				if attached {INTEGER_64} al_l_row.item (1) as al_l_id then
					Result := al_l_id
				end
			end
		end

	commit_transaction
			-- Commit current transaction (alias for commit)
		note
			semantic_role: "[
				Named alias for commit providing
				explicit transaction lifecycle
				semantics.
			]"
		require
			is_open: is_open
			in_transaction: is_in_transaction
		do
			commit_or_refuse
		ensure
			failed_transaction_not_committed: old is_transaction_failed implies has_error
			open_transaction_reported: is_in_transaction implies has_error
			clean_commit: not has_error implies not is_in_transaction
		end

	rollback_transaction
			-- Rollback current transaction (alias for rollback)
		note
			semantic_role: "[
				Named alias for rollback providing
				explicit transaction lifecycle
				semantics.
			]"
		require
			is_open: is_open
			in_transaction: is_in_transaction
		do
			rollback_keeping_error
		ensure
			error_kept: old has_error implies has_error
		end

feature -- Atomic Operations (Phase 6)

	atomic,
	transaction,
	within_transaction,
	transact (a_operation: PROCEDURE)
			-- Execute operation inside a transaction: commit only if every statement succeeded.
			-- If any statement inside fails, the operation raises an exception, or COMMIT fails, the
			-- transaction is rolled back (before any COMMIT) and the failure stays in `has_error' /
			-- `last_error_message'. So after the call: `has_error' = rolled back, not `has_error' =
			-- committed.
			-- Example: db.atomic (agent my_multi_table_operation)
		note
			semantic_role: "[
				Agent-wrapped all-or-nothing transaction:
				any failed statement rolls everything
				back and is reported.
			]"
		require
			is_open: is_open
			not_in_transaction: not is_in_transaction
			operation_attached: a_operation /= Void
		local
			l_failed: BOOLEAN
		do
			if not l_failed then
				begin_transaction
				if not has_error and then is_in_transaction then
					a_operation.call (Void)
					if is_open and then is_in_transaction then
						commit_or_refuse
						if is_in_transaction then
								-- COMMIT failed and SQLite kept the transaction open: give up the work.
							rollback_keeping_error
						end
					end
				end
			end
		ensure
			nothing_left_open: is_open implies not is_in_transaction
		rescue
			if not has_error then
				record_error (create {SIMPLE_SQL_ERROR}.make_with_sql (error_codes.error,
					exception_description, "atomic"))
			end
			if is_open and then internal_db.is_in_transaction then
				rollback_keeping_error
			end
			l_failed := True
			retry
		end

	update_versioned (a_table: READABLE_STRING_8; a_id: INTEGER_64; a_current_version: INTEGER_64;
			a_set_clause: READABLE_STRING_8; a_args: ARRAY [detachable ANY]): TUPLE [success: BOOLEAN; new_version: INTEGER_64]
			-- Update row with optimistic locking using version column.
			-- Returns [True, new_version] on success, [False, 0] if version mismatch (concurrent modification).
			-- The version column is automatically incremented.
			-- Example: result := db.update_versioned ("stock", 42, 5, "quantity = quantity + ?", <<10>>)
		note
			semantic_role: "[
				Optimistic locking update that detects
				concurrent modifications via version
				column comparison.
			]"
		require
			is_open: is_open
			table_not_empty: not a_table.is_empty
			set_clause_not_empty: not a_set_clause.is_empty
		local
			l_sql: STRING_8
			l_all_args: ARRAYED_LIST [detachable ANY]
			l_new_version: INTEGER_64
		do
			l_new_version := a_current_version + 1

			-- Build UPDATE with version check
			create l_sql.make (200)
			l_sql.append ("UPDATE ")
			l_sql.append_string_general (a_table)
			l_sql.append (" SET ")
			l_sql.append_string_general (a_set_clause)
			l_sql.append (", version = ? WHERE id = ? AND version = ?")

			-- Combine user args with version args
			create l_all_args.make (a_args.count + 3)
			across a_args as arg loop
				l_all_args.extend (arg)
			end
			l_all_args.extend (l_new_version)
			l_all_args.extend (a_id)
			l_all_args.extend (a_current_version)

			execute_with_args (l_sql, l_all_args.to_array)

			if changes_count > 0 then
				Result := [True, l_new_version]
			else
				Result := [False, {INTEGER_64} 0]
			end
		ensure
			success_means_changed: Result.success implies changes_count > 0
			failure_means_unchanged: not Result.success implies changes_count = 0
		end

	upsert (a_table: READABLE_STRING_8; a_columns: ARRAY [READABLE_STRING_8];
			a_values: ARRAY [detachable ANY]; a_conflict_columns: ARRAY [READABLE_STRING_8])
			-- Insert row or update if conflict on specified columns.
			-- Uses SQLite's INSERT ... ON CONFLICT DO UPDATE syntax.
			-- Example: db.upsert ("stock", <<"product_id", "location_id", "quantity">>, <<1, 2, 100>>, <<"product_id", "location_id">>)
		note
			semantic_role: "[
				Atomic insert-or-update using SQLite's
				ON CONFLICT clause for idempotent
				writes.
			]"
		require
			is_open: is_open
			table_not_empty: not a_table.is_empty
			columns_not_empty: not a_columns.is_empty
			values_match_columns: a_values.count = a_columns.count
			conflict_columns_not_empty: not a_conflict_columns.is_empty
		local
			l_sql: STRING_8
			i: INTEGER
			l_update_cols: ARRAYED_LIST [STRING_8]
		do
			create l_sql.make (300)
			l_sql.append ("INSERT INTO ")
			l_sql.append_string_general (a_table)
			l_sql.append (" (")

			-- Column list
			from i := a_columns.lower until i > a_columns.upper loop
				if i > a_columns.lower then
					l_sql.append (", ")
				end
				l_sql.append_string_general (a_columns [i])
				i := i + 1
			variant
				a_columns.upper - i + 1
			end

			l_sql.append (") VALUES (")

			-- Placeholders
			from i := a_values.lower until i > a_values.upper loop
				if i > a_values.lower then
					l_sql.append (", ")
				end
				l_sql.append ("?")
				i := i + 1
			variant
				a_values.upper - i + 1
			end

			l_sql.append (") ON CONFLICT (")

			-- Conflict columns
			from i := a_conflict_columns.lower until i > a_conflict_columns.upper loop
				if i > a_conflict_columns.lower then
					l_sql.append (", ")
				end
				l_sql.append_string_general (a_conflict_columns [i])
				i := i + 1
			variant
				a_conflict_columns.upper - i + 1
			end

			l_sql.append (") DO UPDATE SET ")

			-- Build update list (exclude conflict columns)
			create l_update_cols.make (a_columns.count)
			across a_columns as col loop
				if not across a_conflict_columns as cc some cc.same_string (col) end then
					l_update_cols.extend (col.to_string_8)
				end
			end

			from i := 1 until i > l_update_cols.count loop
				if i > 1 then
					l_sql.append (", ")
				end
				l_sql.append (l_update_cols [i])
				l_sql.append (" = excluded.")
				l_sql.append (l_update_cols [i])
				i := i + 1
			variant
				l_update_cols.count - i + 1
			end

			execute_with_args (l_sql, a_values)
		end

	decrement_if (a_table: READABLE_STRING_8; a_column: READABLE_STRING_8;
			a_amount: INTEGER; a_where: READABLE_STRING_8; a_args: ARRAY [detachable ANY]): BOOLEAN
			-- Atomically decrement column if condition is met (including sufficient value).
			-- Returns True if decrement succeeded, False if condition not met.
			-- Prevents race condition of SELECT-then-UPDATE pattern.
			-- Example: success := db.decrement_if ("stock", "quantity", 10, "id = ? AND quantity >= ?", <<stock_id, 10>>)
		note
			semantic_role: "[
				Atomic conditional decrement preventing
				race conditions in inventory-style
				operations.
			]"
		require
			is_open: is_open
			table_not_empty: not a_table.is_empty
			column_not_empty: not a_column.is_empty
			amount_positive: a_amount > 0
			where_not_empty: not a_where.is_empty
		local
			l_sql: STRING_8
			l_all_args: ARRAYED_LIST [detachable ANY]
		do
			create l_sql.make (150)
			l_sql.append ("UPDATE ")
			l_sql.append_string_general (a_table)
			l_sql.append (" SET ")
			l_sql.append_string_general (a_column)
			l_sql.append (" = ")
			l_sql.append_string_general (a_column)
			l_sql.append (" - ? WHERE ")
			l_sql.append_string_general (a_where)

			create l_all_args.make (a_args.count + 1)
			l_all_args.extend (a_amount)
			across a_args as arg loop
				l_all_args.extend (arg)
			end

			execute_with_args (l_sql, l_all_args.to_array)
			Result := changes_count > 0
		end

	increment_if (a_table: READABLE_STRING_8; a_column: READABLE_STRING_8;
			a_amount: INTEGER; a_where: READABLE_STRING_8; a_args: ARRAY [detachable ANY]): BOOLEAN
			-- Atomically increment column if condition is met.
			-- Returns True if increment succeeded, False if condition not met.
			-- Example: success := db.increment_if ("stock", "quantity", 5, "id = ?", <<stock_id>>)
		note
			semantic_role: "[
				Atomic conditional increment for safe
				concurrent counter and quantity updates.
			]"
		require
			is_open: is_open
			table_not_empty: not a_table.is_empty
			column_not_empty: not a_column.is_empty
			amount_positive: a_amount > 0
			where_not_empty: not a_where.is_empty
		local
			l_sql: STRING_8
			l_all_args: ARRAYED_LIST [detachable ANY]
		do
			create l_sql.make (150)
			l_sql.append ("UPDATE ")
			l_sql.append_string_general (a_table)
			l_sql.append (" SET ")
			l_sql.append_string_general (a_column)
			l_sql.append (" = ")
			l_sql.append_string_general (a_column)
			l_sql.append (" + ? WHERE ")
			l_sql.append_string_general (a_where)

			create l_all_args.make (a_args.count + 1)
			l_all_args.extend (a_amount)
			across a_args as arg loop
				l_all_args.extend (arg)
			end

			execute_with_args (l_sql, l_all_args.to_array)
			Result := changes_count > 0
		end

feature -- Query Monitoring (N+1 Detection)

	query_monitor: detachable SIMPLE_SQL_QUERY_MONITOR
			-- Query monitor for N+1 detection (Void when disabled).

	enable_query_monitor
			-- Enable N+1 query detection.
		note
			semantic_role: "[
				Activates runtime query pattern
				monitoring for N+1 detection.
			]"
		do
			if query_monitor = Void then
				create query_monitor.make
			end
			if attached query_monitor as al_m then
				al_m.enable
			end
		ensure
			enabled: attached query_monitor as m and then m.is_enabled
		end

	disable_query_monitor
			-- Disable N+1 query detection.
		note
			semantic_role: "[
				Deactivates query monitoring to
				eliminate monitoring overhead.
			]"
		do
			if attached query_monitor as al_m then
				al_m.disable
			end
		end

	reset_query_monitor
			-- Reset all monitoring data.
		note
			semantic_role: "[
				Clears accumulated query monitoring
				data for a fresh measurement interval.
			]"
		do
			if attached query_monitor as al_m then
				al_m.reset
			end
		end

feature {SIMPLE_SQL_BACKUP, SIMPLE_SQL_ONLINE_BACKUP, SIMPLE_SQL_RESULT, SIMPLE_SQL_PREPARED_STATEMENT, SIMPLE_SQL_SCHEMA, SIMPLE_SQL_JSON, SIMPLE_SQL_FTS5, SIMPLE_SQL_AUDIT} -- Implementation

	internal_db: SQLITE_DATABASE
			-- Underlying sqlite3 database connection

feature {NONE} -- Implementation

	dispose
			-- <Precursor>
		note
			semantic_role: "[
				DISPOSABLE callback ensuring database
				connection cleanup on garbage
				collection.
			]"
		do
				-- With a transaction left open (for example after a failed COMMIT), leave the
				-- connection to SQLITE_DATABASE's own dispose: no SQL runs during collection.
			if not internal_db.is_closed and then not internal_db.is_in_transaction then
				internal_db.close
			end
		end

	bind_args (a_stmt: SIMPLE_SQL_PREPARED_STATEMENT; a_args: ARRAY [detachable ANY])
			-- Bind array of arguments to prepared statement.
		note
			semantic_role: "[
				Maps Eiffel values to SQLite parameter
				types for prepared statement execution.
			]"
		local
			i: INTEGER
		do
			from i := a_args.lower until i > a_args.upper loop
				if attached a_args.item (i) as al_l_arg then
					if attached {INTEGER_64} al_l_arg as al_l_int64 then
						a_stmt.bind_integer (i - a_args.lower + 1, al_l_int64)
					elseif attached {INTEGER_32} al_l_arg as al_l_int32 then
						a_stmt.bind_integer (i - a_args.lower + 1, al_l_int32.to_integer_64)
					elseif attached {REAL_64} al_l_arg as al_l_real then
						a_stmt.bind_real (i - a_args.lower + 1, al_l_real)
					elseif attached {READABLE_STRING_GENERAL} al_l_arg as al_l_str then
						a_stmt.bind_text (i - a_args.lower + 1, al_l_str)
					elseif attached {BOOLEAN} al_l_arg as al_l_bool then
						a_stmt.bind_integer (i - a_args.lower + 1, if al_l_bool then 1 else 0 end)
					elseif attached {MANAGED_POINTER} al_l_arg as al_l_blob then
						a_stmt.bind_blob (i - a_args.lower + 1, al_l_blob)
					end
				else
					a_stmt.bind_null (i - a_args.lower + 1)
				end
				i := i + 1
			variant
				a_args.upper - i + 1
			end
		end

invariant
	internal_db_attached: internal_db /= Void
	file_name_attached: file_name /= Void
	error_consistency: has_error = (last_structured_error /= Void)

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		simple_sql - High-level SQLite API for Eiffel
		https://github.com/simple-eiffel/simple_sql
	]"

end
