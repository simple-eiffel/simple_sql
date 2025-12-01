note
	description: "[
		High-level SQLite database API for simple, safe database operations.
		Simplifies the sqlite3 library for common use cases with automatic resource management.

		Error Handling:
			- `has_error`: Check if last operation failed
			- `last_structured_error`: Full error with code, message, SQL context
			- `last_error_code`: Quick access to error code constant
			- `last_error_message`: Quick access to error message string
			- `error_codes`: Access to SIMPLE_SQL_ERROR_CODE for comparisons
	]"
	EIS: "name=API Reference", "src=../docs/api/database.html", "protocol=URI", "tag=documentation"
	EIS: "name=Getting Started", "src=../docs/getting-started.html", "protocol=URI", "tag=tutorial"
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
			-- Structured error from last failed operation

	last_error_message: detachable STRING_32
			-- Error message from last failed operation
		do
			if attached last_structured_error as l_err then
				Result := l_err.message
			end
		end

	last_error_code: INTEGER
			-- Error code from last operation (0 = success)
		do
			if attached last_structured_error as l_err then
				Result := l_err.code
			end
		ensure
			zero_when_no_error: not has_error implies Result = 0
		end

	error_codes: SIMPLE_SQL_ERROR_CODE
			-- Access to error code constants for comparisons
			-- Usage: if db.last_error_code = db.error_codes.constraint then ...
		once
			create Result
		end

	changes_count: INTEGER
			-- Number of rows modified by last operation
		require
			is_open: is_open
		do
			Result := internal_db.changes_count.to_integer_32
		end

	is_in_transaction: BOOLEAN
			-- Is database currently in a transaction?
		require
			is_open: is_open
		do
			Result := internal_db.is_in_transaction
		end

feature -- Status report

	is_open: BOOLEAN
			-- Is database connection open?
		do
			Result := not internal_db.is_closed
		end

	has_error: BOOLEAN
			-- Did last operation fail?
		do
			Result := last_structured_error /= Void
		ensure
			error_attached: Result implies last_structured_error /= Void
		end

feature -- Error status queries

	is_constraint_error: BOOLEAN
			-- Was last error a constraint violation?
		do
			Result := attached last_structured_error as l_err and then l_err.is_constraint_violation
		end

	is_busy_error: BOOLEAN
			-- Was last error due to database being busy/locked?
		do
			Result := attached last_structured_error as l_err and then l_err.is_busy
		end

	is_readonly_error: BOOLEAN
			-- Was last error due to readonly database?
		do
			Result := attached last_structured_error as l_err and then l_err.is_readonly
		end

feature -- Basic operations

	execute (a_sql: READABLE_STRING_8)
			-- Execute SQL statement (INSERT, UPDATE, DELETE, CREATE, etc)
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
			l_statement.execute
			check_and_set_error (a_sql)
		rescue
			set_error_from_exception (a_sql)
		end

	query (a_sql: READABLE_STRING_8): SIMPLE_SQL_RESULT
			-- Execute query and return results
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
		rescue
			set_error_from_exception (a_sql)
			create Result.make_empty
		end

feature -- Parameterized Operations (convenience methods)

	execute_with_args (a_sql: READABLE_STRING_8; a_args: ARRAY [detachable ANY])
			-- Execute SQL with parameters. Use ? placeholders.
			-- Supported types: INTEGER, INTEGER_64, REAL_64, STRING, BOOLEAN, Void (NULL)
			-- Example: execute_with_args ("INSERT INTO t (a, b) VALUES (?, ?)", <<123, "text">>)
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
		end

	query_with_args (a_sql: READABLE_STRING_8; a_args: ARRAY [detachable ANY]): SIMPLE_SQL_RESULT
			-- Execute query with parameters. Use ? placeholders.
			-- Supported types: INTEGER, INTEGER_64, REAL_64, STRING, BOOLEAN, Void (NULL)
			-- Example: query_with_args ("SELECT * FROM t WHERE id = ?", <<123>>)
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
		end

	begin_transaction
			-- Begin transaction (deferred mode)
		require
			is_open: is_open
		do
			clear_error
			internal_db.begin_transaction (True)
		end

	commit
			-- Commit current transaction
		require
			is_open: is_open
			in_transaction: is_in_transaction
		do
			clear_error
			internal_db.commit
		end

	rollback
			-- Rollback current transaction
		require
			is_open: is_open
			in_transaction: is_in_transaction
		do
			clear_error
			internal_db.rollback
		end

	close
			-- Close database connection
		do
			if not internal_db.is_closed then
				internal_db.close
			end
		ensure
			is_closed: not is_open
		end

feature {NONE} -- Error handling implementation

	clear_error
			-- Clear any previous error
		do
			last_structured_error := Void
		ensure
			no_error: not has_error
		end

	check_and_set_error (a_sql: READABLE_STRING_GENERAL)
			-- Check internal_db for error and set structured error if found
		do
			if internal_db.has_error then
				set_error_from_exception (a_sql)
			end
		end

	set_error_from_exception (a_sql: READABLE_STRING_GENERAL)
			-- Set structured error from internal_db exception
		local
			l_code: INTEGER
			l_message: STRING_32
		do
			if attached internal_db.last_exception as l_exception then
				l_code := l_exception.result_code
				if attached l_exception.description as l_desc then
					l_message := l_desc.to_string_32
				else
					l_message := "Unknown error"
				end
				create last_structured_error.make_with_sql (l_code, l_message, a_sql)
			else
				-- Exception without details
				create last_structured_error.make_with_sql (
					error_codes.error,
					"Unknown database error",
					a_sql
				)
			end
		ensure
			has_error: has_error
		end

feature -- Prepared Statements

	prepare (a_sql: READABLE_STRING_8): SIMPLE_SQL_PREPARED_STATEMENT
			-- Create prepared statement for given SQL
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
		require
			is_open: is_open
		do
			create Result.make (Current)
		ensure
			result_attached: Result /= Void
		end

	paginator (a_table: READABLE_STRING_8): SIMPLE_SQL_PAGINATOR
			-- Create paginator for cursor-based pagination.
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
		require
			is_open: is_open
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create l_result.make ("SELECT last_insert_rowid();", internal_db)
			if not l_result.rows.is_empty and then attached l_result.rows.first as l_row then
				if attached {INTEGER_64} l_row.item (1) as l_id then
					Result := l_id
				end
			end
		end

	commit_transaction
			-- Commit current transaction (alias for commit)
		require
			is_open: is_open
			in_transaction: is_in_transaction
		do
			clear_error
			internal_db.commit
		end

	rollback_transaction
			-- Rollback current transaction (alias for rollback)
		require
			is_open: is_open
			in_transaction: is_in_transaction
		do
			clear_error
			internal_db.rollback
		end

feature -- Query Monitoring (N+1 Detection)

	query_monitor: detachable SIMPLE_SQL_QUERY_MONITOR
			-- Query monitor for N+1 detection (Void when disabled).

	enable_query_monitor
			-- Enable N+1 query detection.
		do
			if query_monitor = Void then
				create query_monitor.make
			end
			if attached query_monitor as m then
				m.enable
			end
		ensure
			enabled: attached query_monitor as m and then m.is_enabled
		end

	disable_query_monitor
			-- Disable N+1 query detection.
		do
			if attached query_monitor as m then
				m.disable
			end
		end

	reset_query_monitor
			-- Reset all monitoring data.
		do
			if attached query_monitor as m then
				m.reset
			end
		end

feature {SIMPLE_SQL_BACKUP, SIMPLE_SQL_ONLINE_BACKUP, SIMPLE_SQL_RESULT, SIMPLE_SQL_PREPARED_STATEMENT, SIMPLE_SQL_SCHEMA, SIMPLE_SQL_JSON, SIMPLE_SQL_FTS5, SIMPLE_SQL_AUDIT} -- Implementation

	internal_db: SQLITE_DATABASE
			-- Underlying sqlite3 database connection

feature {NONE} -- Implementation

	dispose
			-- <Precursor>
		do
			if not internal_db.is_closed then
				internal_db.close
			end
		end

	bind_args (a_stmt: SIMPLE_SQL_PREPARED_STATEMENT; a_args: ARRAY [detachable ANY])
			-- Bind array of arguments to prepared statement.
		local
			i: INTEGER
		do
			from i := a_args.lower until i > a_args.upper loop
				if attached a_args.item (i) as l_arg then
					if attached {INTEGER_64} l_arg as l_int64 then
						a_stmt.bind_integer (i - a_args.lower + 1, l_int64)
					elseif attached {INTEGER_32} l_arg as l_int32 then
						a_stmt.bind_integer (i - a_args.lower + 1, l_int32.to_integer_64)
					elseif attached {REAL_64} l_arg as l_real then
						a_stmt.bind_real (i - a_args.lower + 1, l_real)
					elseif attached {READABLE_STRING_GENERAL} l_arg as l_str then
						a_stmt.bind_text (i - a_args.lower + 1, l_str)
					elseif attached {BOOLEAN} l_arg as l_bool then
						a_stmt.bind_integer (i - a_args.lower + 1, if l_bool then 1 else 0 end)
					elseif attached {MANAGED_POINTER} l_arg as l_blob then
						a_stmt.bind_blob (i - a_args.lower + 1, l_blob)
					end
				else
					a_stmt.bind_null (i - a_args.lower + 1)
				end
				i := i + 1
			end
		end

invariant
	internal_db_attached: internal_db /= Void
	file_name_attached: file_name /= Void

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		SIMPLE_SQL - High-level SQLite API for Eiffel
	]"

end
