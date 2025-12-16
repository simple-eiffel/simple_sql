note
	description: "[
		Zero-configuration SQLite facade for beginners.

		One-liner database operations - no SQL knowledge required for basic tasks.
		For full control, use SIMPLE_SQL_DATABASE directly.

		Quick Start Examples:
			create db.make

			-- Open/create a database file
			db.open ("mydata.db")

			-- Or use in-memory database
			db.memory

			-- Simple queries
			across db.query ("SELECT * FROM users") as row loop
				print (row.item ("name").out + "%N")
			end

			-- Insert data with a table
			db.insert ("users", <<"name", "alice">>, <<"age", "30">>)

			-- Execute any SQL
			db.execute ("UPDATE users SET age = 31 WHERE name = 'alice'")

			-- Cleanup
			db.close
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_QUICK

create
	make

feature {NONE} -- Initialization

	make
			-- Create quick SQL facade.
		do
			-- Database created on open
		end

feature -- Database Operations

	open (a_path: STRING)
			-- Open or create database file.
		require
			path_not_empty: not a_path.is_empty
		do
			create database.make (a_path)
		ensure
			is_connected: is_connected
		end

	memory
			-- Create in-memory database (lost when closed).
		do
			create database.make_memory
		ensure
			is_connected: is_connected
		end

	close
			-- Close database connection.
		do
			if attached database as db then
				db.close
			end
			database := Void
		ensure
			not_connected: not is_connected
		end

feature -- Status

	is_connected: BOOLEAN
			-- Is database connection open?
		do
			Result := attached database as db and then db.is_open
		end

	has_error: BOOLEAN
			-- Did last operation fail?
		do
			Result := attached database as db and then db.has_error
		end

	last_error: STRING
			-- Error message from last operation.
		do
			if attached database as db and then attached db.last_error_message as msg then
				Result := msg.to_string_8
			else
				Result := ""
			end
		ensure
			result_exists: Result /= Void
		end

	rows_affected: INTEGER
			-- Number of rows affected by last INSERT/UPDATE/DELETE.
		do
			if attached database as db then
				Result := db.rows_affected
			end
		end

feature -- Simple Queries

	query (a_sql: STRING): ARRAYED_LIST [STRING_TABLE [ANY]]
			-- Execute SELECT query and return list of row dictionaries.
			-- Example: db.query ("SELECT * FROM users WHERE age > 21")
		require
			is_connected: is_connected
			sql_not_empty: not a_sql.is_empty
		local
			l_row: STRING_TABLE [ANY]
		do
			create Result.make (10)
			if attached database as db then
				if attached db.query (a_sql) as cursor then
					from cursor.start until cursor.after loop
						create l_row.make (cursor.column_count)
						across 1 |..| cursor.column_count as i loop
							if attached cursor.column_name (i) as col_name then
								l_row.put (cursor.value (i), col_name)
							end
						end
						Result.extend (l_row)
						cursor.forth
					end
				end
			end
		ensure
			result_exists: Result /= Void
		end

	query_value (a_sql: STRING): detachable ANY
			-- Execute query and return single value (first column of first row).
			-- Example: db.query_value ("SELECT COUNT(*) FROM users")
		require
			is_connected: is_connected
			sql_not_empty: not a_sql.is_empty
		do
			if attached database as db then
				if attached db.query (a_sql) as cursor then
					cursor.start
					if not cursor.after then
						Result := cursor.value (1)
					end
				end
			end
		end

	execute (a_sql: STRING)
			-- Execute SQL statement (INSERT, UPDATE, DELETE, CREATE, etc.).
		require
			is_connected: is_connected
			sql_not_empty: not a_sql.is_empty
		do
			if attached database as db then
				db.execute (a_sql)
			end
		end

feature -- Table Operations

	table_exists (a_table: STRING): BOOLEAN
			-- Does table exist?
		require
			is_connected: is_connected
			table_not_empty: not a_table.is_empty
		do
			if attached query_value ("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='" + a_table + "'") as v then
				Result := v.out.to_integer > 0
			end
		end

	create_table (a_table: STRING; a_columns: ARRAY [STRING])
			-- Create table with columns.
			-- Example: db.create_table ("users", <<"id INTEGER PRIMARY KEY", "name TEXT", "age INTEGER">>)
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
		require
			is_connected: is_connected
			table_not_empty: not a_table.is_empty
			where_not_empty: not a_where.is_empty
		do
			execute ("DELETE FROM " + a_table + " WHERE " + a_where)
		end

	count (a_table: STRING): INTEGER
			-- Count rows in table.
		require
			is_connected: is_connected
			table_not_empty: not a_table.is_empty
		do
			if attached query_value ("SELECT COUNT(*) FROM " + a_table) as v then
				Result := v.out.to_integer
			end
		end

feature -- Transactions

	begin_transaction
			-- Start transaction.
		require
			is_connected: is_connected
		do
			execute ("BEGIN TRANSACTION")
		end

	commit
			-- Commit transaction.
		require
			is_connected: is_connected
		do
			execute ("COMMIT")
		end

	rollback
			-- Rollback transaction.
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
		do
			Result := a_value.twin
			Result.replace_substring_all ("'", "''")
		end

invariant
	error_message_when_error: has_error implies not last_error.is_empty

end
