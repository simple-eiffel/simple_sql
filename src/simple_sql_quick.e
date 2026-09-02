note
	description: "[
		A zero-configuration facade over SIMPLE_SQL_DATABASE for beginners.
		Provides one-liner table creation, row insertion, update, deletion, and
		querying using string-based column/value tuples instead of raw SQL.
		Offers the simplest possible entry point into the simple_sql library.
	]"
	purpose: "Expose simplified one-liner SQLite operations for beginners"
	collaborators: "SIMPLE_SQL_DATABASE, SIMPLE_SQL_RESULT"
	design_pattern: "Facade"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_QUICK

create
	make

feature {NONE} -- Initialization

	make
			-- Create quick SQL facade.
		note
			semantic_role: "[
				Deferred initialization, actual database
				created on open or memory call.
			]"
		do
			-- Database created on open
		end

feature -- Database Operations

	open (a_path: STRING)
			-- Open or create database file.
		note
			semantic_role: "[
				Opens a persistent database file, the
				primary way to start working with Quick.
			]"
		require
			path_not_empty: not a_path.is_empty
		do
			create database.make (a_path)
		ensure
			is_connected: is_connected
		end

	memory
			-- Create in-memory database (lost when closed).
		note
			semantic_role: "[
				Creates an ephemeral in-memory database
				for testing and temporary work.
			]"
		do
			create database.make_memory
		ensure
			is_connected: is_connected
		end

	close
			-- Close database connection.
		note
			semantic_role: "[
				Releases database connection and clears
				the internal reference.
			]"
		do
			if attached database as al_db then
				al_db.close
			end
			database := Void
		ensure
			not_connected: not is_connected
		end

feature -- Status

	is_connected: BOOLEAN
			-- Is database connection open?
		note
			semantic_role: "[
				Connection state predicate used as
				precondition guard on all operations.
			]"
		do
			Result := attached database as db and then db.is_open
		end

	has_error: BOOLEAN
			-- Did last operation fail?
		note
			semantic_role: "[
				Error state predicate for checking
				operation success.
			]"
		do
			Result := attached database as db and then db.has_error
		end

	last_error: STRING
			-- Error message from last operation.
		note
			semantic_role: "[
				Error message accessor for simple
				diagnostic output.
			]"
		do
			if attached database as db and then attached db.last_error_message as al_msg then
				Result := al_msg.to_string_8
			else
				Result := ""
			end
		ensure
			result_exists: Result /= Void
		end

	rows_affected: INTEGER
			-- Number of rows affected by last INSERT/UPDATE/DELETE.
		note
			semantic_role: "[
				Modification count for verifying the
				effect of write operations.
			]"
		do
			if attached database as al_db then
				Result := al_db.rows_affected
			end
		end

feature -- Simple Queries

	query (a_sql: STRING): ARRAYED_LIST [STRING_TABLE [ANY]]
			-- Execute SELECT query and return list of row dictionaries.
			-- Example: db.query ("SELECT * FROM users WHERE age > 21")
		note
			semantic_role: "[
				Simplified query returning dictionary
				rows instead of SIMPLE_SQL_ROW objects.
			]"
		require
			is_connected: is_connected
			sql_not_empty: not a_sql.is_empty
		local
			l_row: STRING_TABLE [ANY]
			l_res: SIMPLE_SQL_RESULT
			i: INTEGER
		do
			create Result.make (10)
			if attached database as al_db then
				l_res := al_db.run_query (a_sql)
				across l_res.rows as ic_row loop
					create l_row.make (ic_row.count)
					from i := 1 until i > ic_row.count loop
						if attached ic_row [i] as al_val then
							l_row.put (al_val, ic_row.column_name (i))
						end
						i := i + 1
					end
					Result.extend (l_row)
				end
			end
		ensure
			result_exists: Result /= Void
		end

	query_value (a_sql: STRING): detachable ANY
			-- Execute query and return single value (first column of first row).
			-- Example: db.query_value ("SELECT COUNT(*) FROM users")
		note
			semantic_role: "[
				Scalar query shortcut for aggregate
				and single-value lookups.
			]"
		require
			is_connected: is_connected
			sql_not_empty: not a_sql.is_empty
		local
			l_res: SIMPLE_SQL_RESULT
		do
			if attached database as al_db then
				l_res := al_db.run_query (a_sql)
				if not l_res.rows.is_empty and then attached l_res.rows.first as al_row then
					Result := al_row [1]
				end
			end
		end

	execute (a_sql: STRING)
			-- Execute SQL statement (INSERT, UPDATE, DELETE, CREATE, etc.).
		note
			semantic_role: "[
				Raw SQL execution for statements that
				do not return results.
			]"
		require
			is_connected: is_connected
			sql_not_empty: not a_sql.is_empty
		do
			if attached database as al_db then
				al_db.execute (a_sql)
			end
		end

feature -- Table Operations

	table_exists (a_table: STRING): BOOLEAN
			-- Does table exist?
		note
			semantic_role: "[
				Table existence check for guarding
				create_table and other DDL operations.
			]"
		require
			is_connected: is_connected
			table_not_empty: not a_table.is_empty
		do
			if attached query_value ("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='" + a_table + "'") as al_v then
				Result := al_v.out.to_integer > 0
			end
		end

	create_table (a_table: STRING; a_columns: ARRAY [STRING])
			-- Create table with columns.
			-- Example: db.create_table ("users", <<"id INTEGER PRIMARY KEY", "name TEXT", "age INTEGER">>)
		note
			semantic_role: "[
				DDL helper generating CREATE TABLE IF
				NOT EXISTS from column definition
				strings.
			]"
		require
			is_connected: is_connected
			table_not_empty: not a_table.is_empty
			has_columns: a_columns.count > 0
		local
			l_sql: STRING
			l_first: BOOLEAN
		do
			l_sql := "CREATE TABLE IF NOT EXISTS " + a_table + " ("
			l_first := True
			across a_columns as col loop
				if not l_first then
					l_sql.append (", ")
				end
				l_sql.append (col)
				l_first := False
			end
			l_sql.append (")")
			execute (l_sql)
		end

	drop_table (a_table: STRING)
			-- Drop table if exists.
		note
			semantic_role: "[
				DDL helper for unconditional table
				removal.
			]"
		require
			is_connected: is_connected
			table_not_empty: not a_table.is_empty
		do
			execute ("DROP TABLE IF EXISTS " + a_table)
		end

feature -- Row Operations

	insert (a_table: STRING; a_values: ARRAY [TUPLE [column: STRING; value: STRING]])
			-- Insert row into table.
			-- Example: db.insert ("users", <<["name", "alice"], ["age", "30"]>>)
		note
			semantic_role: "[
				Simplified row insertion using
				string-typed column/value tuples.
			]"
		require
			is_connected: is_connected
			table_not_empty: not a_table.is_empty
			has_values: a_values.count > 0
		local
			l_columns, l_vals, l_sql: STRING
			l_first: BOOLEAN
		do
			create l_columns.make_empty
			create l_vals.make_empty
			l_first := True
			across a_values as pair loop
				if not l_first then
					l_columns.append (", ")
					l_vals.append (", ")
				end
				l_columns.append (pair.column)
				l_vals.append ("'" + escape_string (pair.value) + "'")
				l_first := False
			end
			l_sql := "INSERT INTO " + a_table + " (" + l_columns + ") VALUES (" + l_vals + ")"
			execute (l_sql)
		end

	update (a_table: STRING; a_values: ARRAY [TUPLE [column: STRING; value: STRING]]; a_where: STRING)
			-- Update rows matching condition.
			-- Example: db.update ("users", <<["age", "31"]>>, "name = 'alice'")
		note
			semantic_role: "[
				Simplified row update using string-typed
				column/value tuples with WHERE clause.
			]"
		require
			is_connected: is_connected
			table_not_empty: not a_table.is_empty
			has_values: a_values.count > 0
			where_not_empty: not a_where.is_empty
		local
			l_sets, l_sql: STRING
			l_first: BOOLEAN
		do
			create l_sets.make_empty
			l_first := True
			across a_values as pair loop
				if not l_first then
					l_sets.append (", ")
				end
				l_sets.append (pair.column + " = '" + escape_string (pair.value) + "'")
				l_first := False
			end
			l_sql := "UPDATE " + a_table + " SET " + l_sets + " WHERE " + a_where
			execute (l_sql)
		end

	delete (a_table: STRING; a_where: STRING)
			-- Delete rows matching condition.
			-- Example: db.delete ("users", "age < 18")
		note
			semantic_role: "[
				Simplified row deletion with WHERE
				clause.
			]"
		require
			is_connected: is_connected
			table_not_empty: not a_table.is_empty
			where_not_empty: not a_where.is_empty
		do
			execute ("DELETE FROM " + a_table + " WHERE " + a_where)
		end

	count (a_table: STRING): INTEGER
			-- Count rows in table.
		note
			semantic_role: "[
				Convenience row counter for quick table
				size checks.
			]"
		require
			is_connected: is_connected
			table_not_empty: not a_table.is_empty
		do
			if attached query_value ("SELECT COUNT(*) FROM " + a_table) as al_v then
				Result := al_v.out.to_integer
			end
		end

feature -- Transactions

	begin_transaction
			-- Start transaction.
		note
			semantic_role: "[
				Starts a transaction for grouping
				multiple Quick operations atomically.
			]"
		require
			is_connected: is_connected
		do
			execute ("BEGIN TRANSACTION")
		end

	commit
			-- Commit transaction.
		note
			semantic_role: "[
				Makes all changes within the current
				Quick transaction permanent.
			]"
		require
			is_connected: is_connected
		do
			execute ("COMMIT")
		end

	rollback
			-- Rollback transaction.
		note
			semantic_role: "[
				Discards all changes within the current
				Quick transaction.
			]"
		require
			is_connected: is_connected
		do
			execute ("ROLLBACK")
		end

feature -- Advanced Access

	database: detachable SIMPLE_SQL_DATABASE
			-- Access underlying database for advanced operations.

feature {NONE} -- Implementation

	escape_string (a_value: STRING): STRING
			-- Escape single quotes for SQL safety.
		note
			semantic_role: "[
				Minimal SQL injection prevention by
				doubling single quotes in string
				literals.
			]"
		do
			Result := a_value.twin
			Result.replace_substring_all ("'", "''")
		end

invariant
	error_message_when_error: has_error implies not last_error.is_empty

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		simple_sql - High-level SQLite API for Eiffel
		https://github.com/simple-eiffel/simple_sql
	]"

end
