note
	description: "[
		Automatic audit/change tracking for database tables.

		Provides automatic change capture via triggers that record:
		- Operation type (INSERT, UPDATE, DELETE)
		- Timestamp of change
		- Old and new values as JSON
		- List of changed fields

		Example:
			audit := db.audit
			audit.enable_for_table ("users")

			-- Changes are now automatically tracked
			db.execute ("UPDATE users SET age = 31 WHERE id = 1")

			-- Query audit history
			changes := audit.get_changes_for_record ("users", 1)
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_AUDIT

create
	make

feature {NONE} -- Initialization

	make (a_database: SIMPLE_SQL_DATABASE)
			-- Initialize with database connection
		require
			database_not_void: a_database /= Void
			database_open: a_database.is_open
		do
			database := a_database
		ensure
			database_set: database = a_database
		end

feature -- Access

	database: SIMPLE_SQL_DATABASE
			-- Database connection

feature -- Status

	is_enabled (a_table: STRING_8): BOOLEAN
			-- Is auditing enabled for table?
			-- Checks if INSERT/UPDATE/DELETE triggers exist
		require
			table_not_empty: not a_table.is_empty
		local
			l_count: INTEGER
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query (
				"SELECT COUNT(*) as cnt FROM sqlite_master WHERE type='trigger' AND name LIKE '" + a_table + "_audit_%%'"
			)
			check query_succeeded: not database.has_error end
			check result_not_empty: not l_result.is_empty end
			if not l_result.is_empty then
				l_count := l_result.first.integer_value ("cnt")
				Result := l_count >= 3
			end
		end


	has_audit_table (a_table: STRING_8): BOOLEAN
			-- Does audit table exist for given table?
		require
			table_not_empty: not a_table.is_empty
		do
			Result := database.schema.table_exists (audit_table_name (a_table))
		end

	is_valid_operation (a_operation: STRING_8): BOOLEAN
			-- Is operation one of INSERT, UPDATE, DELETE?
		do
			Result := a_operation.is_case_insensitive_equal ("INSERT") or
			          a_operation.is_case_insensitive_equal ("UPDATE") or
			          a_operation.is_case_insensitive_equal ("DELETE")
		end

feature -- Configuration

	enable_for_table (a_table: STRING_8)
			-- Enable auditing for table
			-- Creates audit table and triggers if they don't exist
		require
			table_not_empty: not a_table.is_empty
			table_exists: database.schema.table_exists (a_table)
		do
			if not has_audit_table (a_table) then
				create_audit_table (a_table)
				check audit_table_created: not database.has_error end
			end
			if not is_enabled (a_table) then
				create_triggers (a_table)
			end
		ensure
			enabled: is_enabled (a_table)
			has_table: has_audit_table (a_table)
		end

	disable_for_table (a_table: STRING_8)
			-- Disable auditing for table
			-- Drops triggers but preserves audit table and history
		require
			table_not_empty: not a_table.is_empty
		do
			drop_triggers (a_table)
		ensure
			disabled: not is_enabled (a_table)
		end

	drop_audit_table (a_table: STRING_8)
			-- Drop audit table and all triggers
			-- WARNING: This permanently deletes all audit history
		require
			table_not_empty: not a_table.is_empty
		do
			disable_for_table (a_table)
			database.execute ("DROP TABLE IF EXISTS " + audit_table_name (a_table))
		ensure
			no_table: not has_audit_table (a_table)
			no_triggers: not is_enabled (a_table)
		end

feature -- Querying

	get_changes_for_record (a_table: STRING_8; a_record_id: INTEGER_64): SIMPLE_SQL_RESULT
			-- Get all audit entries for specific record
		require
			table_not_empty: not a_table.is_empty
			has_audit: has_audit_table (a_table)
		local
			l_stmt: SIMPLE_SQL_PREPARED_STATEMENT
		do
			l_stmt := database.prepare (
				"SELECT * FROM " + audit_table_name (a_table) + " WHERE record_id = ? ORDER BY audit_id DESC"
			)
			l_stmt.bind_integer (1, a_record_id)
			Result := l_stmt.execute_returning_result
		end

	get_changes_in_range (a_table: STRING_8; a_start: STRING_8; a_end: STRING_8): SIMPLE_SQL_RESULT
			-- Get changes within time range
			-- Times should be in ISO 8601 format: "YYYY-MM-DD HH:MM:SS"
		require
			table_not_empty: not a_table.is_empty
			has_audit: has_audit_table (a_table)
			start_not_empty: not a_start.is_empty
			end_not_empty: not a_end.is_empty
		local
			l_stmt: SIMPLE_SQL_PREPARED_STATEMENT
		do
			l_stmt := database.prepare (
				"SELECT * FROM " + audit_table_name (a_table) +
				" WHERE timestamp BETWEEN ? AND ? ORDER BY audit_id DESC"
			)
			l_stmt.bind_text (1, a_start)
			l_stmt.bind_text (2, a_end)
			Result := l_stmt.execute_returning_result
		end

	get_latest_changes (a_table: STRING_8; a_limit: INTEGER): SIMPLE_SQL_RESULT
			-- Get most recent N changes
		require
			table_not_empty: not a_table.is_empty
			has_audit: has_audit_table (a_table)
			limit_positive: a_limit > 0
		local
			l_stmt: SIMPLE_SQL_PREPARED_STATEMENT
		do
			l_stmt := database.prepare (
				"SELECT * FROM " + audit_table_name (a_table) + " ORDER BY audit_id DESC LIMIT ?"
			)
			l_stmt.bind_integer (1, a_limit.to_integer_64)
			Result := l_stmt.execute_returning_result
		end

	get_changes_by_operation (a_table: STRING_8; a_operation: STRING_8): SIMPLE_SQL_RESULT
			-- Get changes by operation type
			-- a_operation: "INSERT", "UPDATE", or "DELETE"
		require
			table_not_empty: not a_table.is_empty
			has_audit: has_audit_table (a_table)
			valid_operation: is_valid_operation (a_operation)
		local
			l_stmt: SIMPLE_SQL_PREPARED_STATEMENT
		do
			l_stmt := database.prepare (
				"SELECT * FROM " + audit_table_name (a_table) + " WHERE operation = ? ORDER BY audit_id DESC"
			)
			l_stmt.bind_text (1, a_operation)
			Result := l_stmt.execute_returning_result
		end

feature -- Analysis

	get_changed_fields (a_table: STRING_8; a_audit_id: INTEGER_64): ARRAY [STRING_32]
			-- Get list of fields that changed in this audit entry
			-- Compares old_values and new_values JSON to determine changes
			-- Returns empty array for INSERT/DELETE operations
		require
			table_not_empty: not a_table.is_empty
			has_audit: has_audit_table (a_table)
		local
			l_stmt: SIMPLE_SQL_PREPARED_STATEMENT
			l_old_json, l_new_json: detachable STRING_32
			l_json: SIMPLE_JSON
			l_old_val, l_new_val: detachable SIMPLE_JSON_VALUE
			l_old_obj, l_new_obj: SIMPLE_JSON_OBJECT
			l_keys: LINKED_LIST [STRING_32]
			l_changed: ARRAYED_LIST [STRING_32]
			l_old_item, l_new_item: detachable SIMPLE_JSON_VALUE
			l_index: INTEGER
			l_result: SIMPLE_SQL_RESULT
		do
			l_stmt := database.prepare (
				"SELECT old_values, new_values FROM " + audit_table_name (a_table) + " WHERE audit_id = ?"
			)
			l_stmt.bind_integer (1, a_audit_id)
			l_result := l_stmt.execute_returning_result

			create l_changed.make (0)

			if not l_result.is_empty then
				l_old_json := l_result.first.string_value ("old_values")
				l_new_json := l_result.first.string_value ("new_values")

				-- Both must be present and valid for comparison
				if attached l_old_json as l_old and then attached l_new_json as l_new then
					if not l_old.is_empty and not l_new.is_empty then
						create l_json
						l_old_val := l_json.parse (l_old)
						l_new_val := l_json.parse (l_new)

						if attached l_old_val as l_ov and then attached l_new_val as l_nv then
							if l_ov.is_object and l_nv.is_object then
								l_old_obj := l_ov.as_object
								l_new_obj := l_nv.as_object
								l_keys := l_old_obj.keys

								-- Compare each field
								from
									l_keys.start
								until
									l_keys.after
								loop
									l_old_item := l_old_obj.item (l_keys.item)
									l_new_item := l_new_obj.item (l_keys.item)

									-- Check if values differ (simple string comparison)
									if attached l_old_item as l_oi and then attached l_new_item as l_ni then
										if not l_oi.to_json_string.same_string (l_ni.to_json_string) then
											l_changed.extend (l_keys.item)
										end
									elseif (l_old_item = Void) /= (l_new_item = Void) then
										-- One is NULL, other isn't
										l_changed.extend (l_keys.item)
									end

									l_keys.forth
								end
							end
						end
					end
				end
			end

			-- Convert to array
			if l_changed.is_empty then
				create Result.make_empty
			else
				create Result.make_filled ("", 1, l_changed.count)
				from
					l_index := 1
					l_changed.start
				until
					l_changed.after
				loop
					Result [l_index] := l_changed.item
					l_index := l_index + 1
					l_changed.forth
				end
			end
		end

feature {NONE} -- Implementation

	audit_table_name (a_table: STRING_8): STRING_8
			-- Generate audit table name for given table
		do
			create Result.make_from_string (a_table)
			Result.append ("_audit")
		ensure
			result_not_empty: not Result.is_empty
		end

	create_audit_table (a_table: STRING_8)
			-- Create audit table for tracking changes
		require
			table_not_empty: not a_table.is_empty
		local
			l_sql: STRING_8
		do
			create l_sql.make_from_string ("CREATE TABLE IF NOT EXISTS ")
			l_sql.append (audit_table_name (a_table))
			l_sql.append (" (%N")
			l_sql.append ("    audit_id INTEGER PRIMARY KEY AUTOINCREMENT,%N")
			l_sql.append ("    operation TEXT NOT NULL,%N")
			l_sql.append ("    timestamp TEXT NOT NULL DEFAULT (datetime('now')),%N")
			l_sql.append ("    record_id INTEGER NOT NULL,%N")
			l_sql.append ("    old_values TEXT,%N")
			l_sql.append ("    new_values TEXT,%N")
			l_sql.append ("    changed_fields TEXT,%N")
			l_sql.append ("    user_context TEXT%N")
			l_sql.append (")")

			database.execute (l_sql)

			-- Create index on record_id for fast lookups
			database.execute (
				"CREATE INDEX IF NOT EXISTS idx_" + audit_table_name (a_table) + "_record " +
				"ON " + audit_table_name (a_table) + " (record_id)"
			)

			-- Create index on timestamp for time-range queries
			database.execute (
				"CREATE INDEX IF NOT EXISTS idx_" + audit_table_name (a_table) + "_timestamp " +
				"ON " + audit_table_name (a_table) + " (timestamp)"
			)
		end

	create_triggers (a_table: STRING_8)
			-- Create INSERT, UPDATE, DELETE triggers for audit tracking
			-- Each trigger creation uses check assertions to ensure success
		require
			table_not_empty: not a_table.is_empty
		do
			create_insert_trigger (a_table)
			create_update_trigger (a_table)
			create_delete_trigger (a_table)
		end

	create_insert_trigger (a_table: STRING_8)
			-- Create INSERT trigger
		require
			table_not_empty: not a_table.is_empty
		local
			l_sql: STRING_8
			l_columns: ARRAY [SIMPLE_SQL_COLUMN_INFO]
			l_json_pairs: STRING_8
			i: INTEGER
		do
			l_columns := get_table_columns (a_table)

			create l_json_pairs.make_empty

			-- Build json_object pairs: 'col1', NEW.col1, 'col2', NEW.col2, ...
			from i := l_columns.lower until i > l_columns.upper loop
				if i > l_columns.lower then
					l_json_pairs.append (", ")
				end
				l_json_pairs.append ("%'" + l_columns [i].name + "%', NEW.")
				l_json_pairs.append (l_columns [i].name)
				i := i + 1
			end

			create l_sql.make_from_string ("CREATE TRIGGER IF NOT EXISTS ")
			l_sql.append (a_table + "_audit_insert ")
			l_sql.append ("AFTER INSERT ON " + a_table + " ")
			l_sql.append ("FOR EACH ROW BEGIN ")
			l_sql.append ("INSERT INTO " + audit_table_name (a_table) + " ")
			l_sql.append ("(operation, record_id, new_values) ")
			l_sql.append ("VALUES ('INSERT', NEW." + get_primary_key (a_table) + ", json_object(" + l_json_pairs + ")); END;")

			-- Execute trigger DDL (BEGIN...END required for is_complete_statement check)
			database.execute (l_sql)

			check no_sql_error: not database.has_error end

			-- Verify trigger was created
			check trigger_created:
				database.query ("SELECT 1 FROM sqlite_master WHERE type='trigger' AND name='" + a_table + "_audit_insert'").count = 1
			end


		end

	create_update_trigger (a_table: STRING_8)
			-- Create UPDATE trigger with old and new values
			-- Note: changed_fields is computed in Eiffel from JSON comparison
		require
			table_not_empty: not a_table.is_empty
		local
			l_sql: STRING_8
			l_columns: ARRAY [SIMPLE_SQL_COLUMN_INFO]
			l_old_pairs, l_new_pairs: STRING_8
			i: INTEGER
		do
			l_columns := get_table_columns (a_table)
			create l_old_pairs.make_empty
			create l_new_pairs.make_empty

			-- Build JSON pairs for old and new values
			from i := l_columns.lower until i > l_columns.upper loop
				if i > l_columns.lower then
					l_old_pairs.append (", ")
					l_new_pairs.append (", ")
				end
				l_old_pairs.append ("%'" + l_columns [i].name + "%', OLD.")
				l_old_pairs.append (l_columns [i].name)
				l_new_pairs.append ("%'" + l_columns [i].name + "%', NEW.")
				l_new_pairs.append (l_columns [i].name)
				i := i + 1
			end

			create l_sql.make_from_string ("CREATE TRIGGER IF NOT EXISTS ")
			l_sql.append (a_table + "_audit_update ")
			l_sql.append ("AFTER UPDATE ON " + a_table + " ")
			l_sql.append ("FOR EACH ROW BEGIN ")
			l_sql.append ("INSERT INTO " + audit_table_name (a_table) + " ")
			l_sql.append ("(operation, record_id, old_values, new_values) ")
			l_sql.append ("VALUES ('UPDATE', NEW." + get_primary_key (a_table) + ", ")
			l_sql.append ("json_object(" + l_old_pairs + "), ")
			l_sql.append ("json_object(" + l_new_pairs + ")); END;")

			-- Execute trigger DDL
			database.execute (l_sql)
			check no_sql_error: not database.has_error end


			-- Verify trigger actually exists in sqlite_master
			check trigger_created:
				database.query ("SELECT 1 FROM sqlite_master WHERE type='trigger' AND name='" + a_table + "_audit_update'").count = 1
			end
		end

	create_delete_trigger (a_table: STRING_8)
			-- Create DELETE trigger
		require
			table_not_empty: not a_table.is_empty
		local
			l_sql: STRING_8
			l_columns: ARRAY [SIMPLE_SQL_COLUMN_INFO]
			l_json_pairs: STRING_8
			i: INTEGER
		do
			l_columns := get_table_columns (a_table)
			create l_json_pairs.make_empty

			-- Build json_object pairs: 'col1', OLD.col1, 'col2', OLD.col2, ...
			from i := l_columns.lower until i > l_columns.upper loop
				if i > l_columns.lower then
					l_json_pairs.append (", ")
				end
				l_json_pairs.append ("%'" + l_columns [i].name + "%', OLD.")
				l_json_pairs.append (l_columns [i].name)
				i := i + 1
			end

			create l_sql.make_from_string ("CREATE TRIGGER IF NOT EXISTS ")
			l_sql.append (a_table + "_audit_delete ")
			l_sql.append ("AFTER DELETE ON " + a_table + " ")
			l_sql.append ("FOR EACH ROW BEGIN ")
			l_sql.append ("INSERT INTO " + audit_table_name (a_table) + " ")
			l_sql.append ("(operation, record_id, old_values) ")
			l_sql.append ("VALUES ('DELETE', OLD." + get_primary_key (a_table) + ", json_object(" + l_json_pairs + ")); END;")

			-- Execute trigger DDL
			database.execute (l_sql)
			check no_sql_error: not database.has_error end


			-- Verify trigger actually exists in sqlite_master
			check trigger_created:
				database.query ("SELECT 1 FROM sqlite_master WHERE type='trigger' AND name='" + a_table + "_audit_delete'").count = 1
			end
		end

	drop_triggers (a_table: STRING_8)
			-- Drop all audit triggers for table
		require
			table_not_empty: not a_table.is_empty
		do
			database.execute ("DROP TRIGGER IF EXISTS " + a_table + "_audit_insert")
			database.execute ("DROP TRIGGER IF EXISTS " + a_table + "_audit_update")
			database.execute ("DROP TRIGGER IF EXISTS " + a_table + "_audit_delete")
		end

	get_table_columns (a_table: STRING_8): ARRAY [SIMPLE_SQL_COLUMN_INFO]
			-- Get column information for table
		require
			table_not_empty: not a_table.is_empty
		local
			l_columns: ARRAYED_LIST [SIMPLE_SQL_COLUMN_INFO]
			i: INTEGER
		do
			l_columns := database.schema.columns (a_table)
			create Result.make_filled (l_columns.first, 1, l_columns.count)
			from
				i := 1
				l_columns.start
			until
				l_columns.after
			loop
				Result [i] := l_columns.item
				i := i + 1
				l_columns.forth
			end
		end

	get_primary_key (a_table: STRING_8): STRING_8
			-- Get primary key column name (assumes first PK column)
		require
			table_not_empty: not a_table.is_empty
		local
			l_columns: ARRAY [SIMPLE_SQL_COLUMN_INFO]
			i: INTEGER
			l_found: BOOLEAN
		do
			l_columns := get_table_columns (a_table)
			create Result.make_from_string ("id")  -- Default

			from i := l_columns.lower until i > l_columns.upper or l_found loop
				if l_columns [i].is_primary_key then
					Result := l_columns [i].name.to_string_8
					l_found := True
				end
				i := i + 1
			end
		ensure
			result_not_empty: not Result.is_empty
		end

invariant
	database_not_void: database /= Void
	is_interface_usable: database.internal_db.is_interface_usable

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		SIMPLE_SQL - High-level SQLite API for Eiffel
		Audit/Change Tracking
	]"

end
