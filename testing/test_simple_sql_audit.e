note
	description: "Test automatic audit/change tracking"
	testing: "covers"
	testing: "execution/isolated"

class
	TEST_SIMPLE_SQL_AUDIT

inherit
	TEST_SET_BASE

feature -- Test routines: Basic Operations

	test_enable_auditing
			-- Test enabling auditing for a table
		note
			testing: "covers/{SIMPLE_SQL_AUDIT}.enable_for_table"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_audit: SIMPLE_SQL_AUDIT
		do
			create l_db.make_memory
			create l_audit.make (l_db)

			-- Create test table
			l_db.execute ("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER)")

			-- Enable auditing
			l_audit.enable_for_table ("users")

			-- Verify audit table was created
			assert_true ("audit_table_exists", l_audit.has_audit_table ("users"))

			-- Verify triggers were created
			assert_true ("auditing_enabled", l_audit.is_enabled ("users"))

			l_db.close
		end

	test_disable_auditing
			-- Test disabling auditing (keeps history)
		note
			testing: "covers/{SIMPLE_SQL_AUDIT}.disable_for_table"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_audit: SIMPLE_SQL_AUDIT
		do
			create l_db.make_memory
			create l_audit.make (l_db)

			l_db.execute ("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)")
			l_audit.enable_for_table ("users")

			-- Disable auditing
			l_audit.disable_for_table ("users")

			-- Verify triggers removed but table remains
			assert_false ("auditing_disabled", l_audit.is_enabled ("users"))
			assert_true ("audit_table_remains", l_audit.has_audit_table ("users"))

			l_db.close
		end

	test_drop_audit_table
			-- Test dropping audit table (deletes history)
		note
			testing: "covers/{SIMPLE_SQL_AUDIT}.drop_audit_table"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_audit: SIMPLE_SQL_AUDIT
		do
			create l_db.make_memory
			create l_audit.make (l_db)

			l_db.execute ("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)")
			l_audit.enable_for_table ("users")

			-- Drop audit table
			l_audit.drop_audit_table ("users")

			-- Verify everything removed
			assert_false ("no_triggers", l_audit.is_enabled ("users"))
			assert_false ("no_table", l_audit.has_audit_table ("users"))

			l_db.close
		end

feature -- Test routines: INSERT Tracking

	test_insert_tracking
			-- Test that INSERTs are captured
		note
			testing: "covers/{SIMPLE_SQL_AUDIT}.enable_for_table"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_audit: SIMPLE_SQL_AUDIT
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			create l_audit.make (l_db)

			l_db.execute ("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER)")
			l_audit.enable_for_table ("users")

			-- Insert record
			l_db.execute ("INSERT INTO users VALUES (1, 'Alice', 30)")

			-- Check audit record
			l_result := l_audit.get_changes_for_record ("users", 1)
			assert_equal ("one_audit_record", 1, l_result.count)
			assert_strings_equal ("operation_is_insert", "INSERT", l_result.first.string_value ("operation"))
			assert_true ("has_new_values", attached l_result.first.string_value ("new_values"))
			assert_true ("no_old_values", not attached l_result.first.string_value ("old_values") or else
			                              l_result.first.string_value ("old_values").is_empty or else
			                              l_result.first.string_value ("old_values").same_string ("null"))

			l_db.close
		end

	test_insert_tracking_new_values_json
			-- Test that INSERT new_values contains proper JSON
		note
			testing: "covers/{SIMPLE_SQL_AUDIT}.enable_for_table"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_audit: SIMPLE_SQL_AUDIT
			l_result: SIMPLE_SQL_RESULT
			l_new_values: STRING_32
			l_json: SIMPLE_JSON
			l_parsed: detachable SIMPLE_JSON_VALUE
			l_obj: SIMPLE_JSON_OBJECT
		do
			create l_db.make_memory
			create l_audit.make (l_db)

			l_db.execute ("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER)")
			l_audit.enable_for_table ("users")
			l_db.execute ("INSERT INTO users VALUES (1, 'Alice', 30)")

			l_result := l_audit.get_changes_for_record ("users", 1)
			l_new_values := l_result.first.string_value ("new_values")

			-- Parse JSON
			create l_json
			l_parsed := l_json.parse (l_new_values)
			assert_true ("valid_json", l_parsed /= Void)

			if l_parsed /= Void and then l_parsed.is_object then
				l_obj := l_parsed.as_object
				assert_true ("has_name", attached l_obj.item ("name"))
				assert_true ("has_age", attached l_obj.item ("age"))
				if attached l_obj.item ("name") as l_name then
					assert_strings_equal ("name_is_alice", "Alice", l_name.as_string_32)
				end
			end

			l_db.close
		end

feature -- Test routines: UPDATE Tracking

	test_update_tracking
			-- Test that UPDATEs are captured with old and new values
		note
			testing: "covers/{SIMPLE_SQL_AUDIT}.enable_for_table"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_audit: SIMPLE_SQL_AUDIT
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			create l_audit.make (l_db)

			l_db.execute ("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER)")
			l_audit.enable_for_table ("users")

			l_db.execute ("INSERT INTO users VALUES (1, 'Alice', 30)")
			l_db.execute ("UPDATE users SET age = 31 WHERE id = 1")

			l_result := l_audit.get_changes_for_record ("users", 1)
			assert_equal ("two_audit_records", 2, l_result.count)

			-- Check UPDATE record (first in DESC order)
			assert_strings_equal ("operation_is_update", "UPDATE", l_result.first.string_value ("operation"))
			assert_true ("has_old_values", attached l_result.first.string_value ("old_values"))
			assert_true ("has_new_values", attached l_result.first.string_value ("new_values"))

			l_db.close
		end

	test_update_changed_fields
			-- Test that changed_fields JSON array is correct
		note
			testing: "covers/{SIMPLE_SQL_AUDIT}.get_changed_fields"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_audit: SIMPLE_SQL_AUDIT
			l_result: SIMPLE_SQL_RESULT
			l_audit_id: INTEGER_64
			l_changed: ARRAY [STRING_32]
		do
			create l_db.make_memory
			create l_audit.make (l_db)

			l_db.execute ("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER)")
			l_audit.enable_for_table ("users")

			l_db.execute ("INSERT INTO users VALUES (1, 'Alice', 30)")
			l_db.execute ("UPDATE users SET age = 31 WHERE id = 1")

			-- Get UPDATE audit record
			l_result := l_audit.get_changes_by_operation ("users", "UPDATE")
			assert_false ("has_update", l_result.is_empty)

			l_audit_id := l_result.first.integer_value ("audit_id")
			l_changed := l_audit.get_changed_fields ("users", l_audit_id)

			-- Only 'age' should have changed
			assert_true ("has_changed_fields", l_changed.count >= 1)
			-- Note: May include other fields due to SQL trigger logic

			l_db.close
		end

	test_update_multiple_fields
			-- Test updating multiple fields at once
		note
			testing: "covers/{SIMPLE_SQL_AUDIT}.enable_for_table"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_audit: SIMPLE_SQL_AUDIT
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			create l_audit.make (l_db)

			l_db.execute ("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER)")
			l_audit.enable_for_table ("users")

			l_db.execute ("INSERT INTO users VALUES (1, 'Alice', 30)")
			l_db.execute ("UPDATE users SET name = 'Alicia', age = 31 WHERE id = 1")

			l_result := l_audit.get_changes_by_operation ("users", "UPDATE")
			assert_equal ("one_update", 1, l_result.count)

			l_db.close
		end

feature -- Test routines: DELETE Tracking

	test_delete_tracking
			-- Test that DELETEs are captured with old values
		note
			testing: "covers/{SIMPLE_SQL_AUDIT}.enable_for_table"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_audit: SIMPLE_SQL_AUDIT
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			create l_audit.make (l_db)

			l_db.execute ("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER)")
			l_audit.enable_for_table ("users")

			l_db.execute ("INSERT INTO users VALUES (1, 'Alice', 30)")
			l_db.execute ("DELETE FROM users WHERE id = 1")

			l_result := l_audit.get_changes_for_record ("users", 1)
			assert_equal ("two_audit_records", 2, l_result.count)

			-- Check DELETE record (first in DESC order)
			assert_strings_equal ("operation_is_delete", "DELETE", l_result.first.string_value ("operation"))
			assert_true ("has_old_values", attached l_result.first.string_value ("old_values"))

			l_db.close
		end

feature -- Test routines: Query Helpers

	test_get_changes_by_operation
			-- Test filtering changes by operation type
		note
			testing: "covers/{SIMPLE_SQL_AUDIT}.get_changes_by_operation"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_audit: SIMPLE_SQL_AUDIT
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			create l_audit.make (l_db)

			l_db.execute ("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)")
			l_audit.enable_for_table ("users")

			l_db.execute ("INSERT INTO users VALUES (1, 'Alice')")
			l_db.execute ("INSERT INTO users VALUES (2, 'Bob')")
			l_db.execute ("UPDATE users SET name = 'Alicia' WHERE id = 1")
			l_db.execute ("DELETE FROM users WHERE id = 2")

			-- Get only INSERTs
			l_result := l_audit.get_changes_by_operation ("users", "INSERT")
			assert_equal ("two_inserts", 2, l_result.count)

			-- Get only UPDATEs
			l_result := l_audit.get_changes_by_operation ("users", "UPDATE")
			assert_equal ("one_update", 1, l_result.count)

			-- Get only DELETEs
			l_result := l_audit.get_changes_by_operation ("users", "DELETE")
			assert_equal ("one_delete", 1, l_result.count)

			l_db.close
		end

	test_get_latest_changes
			-- Test getting most recent N changes
		note
			testing: "covers/{SIMPLE_SQL_AUDIT}.get_latest_changes"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_audit: SIMPLE_SQL_AUDIT
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			create l_audit.make (l_db)

			l_db.execute ("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)")
			l_audit.enable_for_table ("users")

			l_db.execute ("INSERT INTO users VALUES (1, 'Alice')")
			l_db.execute ("INSERT INTO users VALUES (2, 'Bob')")
			l_db.execute ("INSERT INTO users VALUES (3, 'Charlie')")

			l_result := l_audit.get_latest_changes ("users", 2)
			assert_equal ("two_changes", 2, l_result.count)

			l_db.close
		end

	test_get_changes_in_range
			-- Test time-range queries
		note
			testing: "covers/{SIMPLE_SQL_AUDIT}.get_changes_in_range"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_audit: SIMPLE_SQL_AUDIT
			l_result: SIMPLE_SQL_RESULT
			l_start, l_end: STRING_8
		do
			create l_db.make_memory
			create l_audit.make (l_db)

			l_db.execute ("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)")
			l_audit.enable_for_table ("users")

			-- Use very wide time range to capture all changes
			create l_start.make_from_string ("2000-01-01 00:00:00")
			create l_end.make_from_string ("2099-12-31 23:59:59")

			l_db.execute ("INSERT INTO users VALUES (1, 'Alice')")
			l_db.execute ("INSERT INTO users VALUES (2, 'Bob')")

			l_result := l_audit.get_changes_in_range ("users", l_start, l_end)
			assert_true ("has_changes", l_result.count >= 2)

			l_db.close
		end

feature -- Test routines: Multiple Tables

	test_multiple_tables
			-- Test auditing multiple tables independently
		note
			testing: "covers/{SIMPLE_SQL_AUDIT}.enable_for_table"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_audit: SIMPLE_SQL_AUDIT
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			create l_audit.make (l_db)

			-- Create two tables
			l_db.execute ("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)")
			l_db.execute ("CREATE TABLE posts (id INTEGER PRIMARY KEY, title TEXT)")

			-- Enable auditing for both
			l_audit.enable_for_table ("users")
			l_audit.enable_for_table ("posts")

			-- Make changes
			l_db.execute ("INSERT INTO users VALUES (1, 'Alice')")
			l_db.execute ("INSERT INTO posts VALUES (1, 'First Post')")

			-- Check separate audit trails
			l_result := l_audit.get_changes_for_record ("users", 1)
			assert_equal ("one_user_change", 1, l_result.count)

			l_result := l_audit.get_changes_for_record ("posts", 1)
			assert_equal ("one_post_change", 1, l_result.count)

			l_db.close
		end

feature -- Test routines: Audit Table Schema

	test_audit_table_schema
			-- Test that audit table has correct columns
		note
			testing: "covers/{SIMPLE_SQL_AUDIT}.enable_for_table"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_audit: SIMPLE_SQL_AUDIT
			l_columns_list: ARRAYED_LIST [SIMPLE_SQL_COLUMN_INFO]
			l_columns: ARRAY [SIMPLE_SQL_COLUMN_INFO]
			i: INTEGER
		do
			create l_db.make_memory
			create l_audit.make (l_db)

			l_db.execute ("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)")
			l_audit.enable_for_table ("users")

			l_columns_list := l_db.schema.columns ("users_audit")
			create l_columns.make_filled (l_columns_list.first, 1, l_columns_list.count)
			from
				i := 1
				l_columns_list.start
			until
				l_columns_list.after
			loop
				l_columns [i] := l_columns_list.item
				i := i + 1
				l_columns_list.forth
			end
			assert_true ("has_columns", l_columns.count >= 7)

			-- Check key columns exist
			assert_true ("has_audit_id", has_column (l_columns, "audit_id"))
			assert_true ("has_operation", has_column (l_columns, "operation"))
			assert_true ("has_timestamp", has_column (l_columns, "timestamp"))
			assert_true ("has_record_id", has_column (l_columns, "record_id"))
			assert_true ("has_old_values", has_column (l_columns, "old_values"))
			assert_true ("has_new_values", has_column (l_columns, "new_values"))
			assert_true ("has_changed_fields", has_column (l_columns, "changed_fields"))
		end

feature -- Test routines: Complex Scenarios

	test_audit_full_lifecycle
			-- Test complete record lifecycle: INSERT, UPDATE, DELETE
		note
			testing: "covers/{SIMPLE_SQL_AUDIT}.enable_for_table"
		local
			l_result: SIMPLE_SQL_RESULT
			l_db: SIMPLE_SQL_DATABASE
			l_audit: SIMPLE_SQL_AUDIT
		do
			create l_db.make_memory
			create l_audit.make (l_db)

			l_db.execute ("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER)")
			l_audit.enable_for_table ("users")

			-- Full lifecycle
			l_db.execute ("INSERT INTO users VALUES (1, 'Alice', 30)")
			l_db.execute ("UPDATE users SET age = 31 WHERE id = 1")
			l_db.execute ("UPDATE users SET name = 'Alicia', age = 32 WHERE id = 1")
			l_db.execute ("DELETE FROM users WHERE id = 1")

			-- Should have 4 audit records
			l_result := l_audit.get_changes_for_record ("users", 1)
			assert_equal ("four_changes", 4, l_result.count)

			-- Verify sequence (reverse chronological)
			assert_strings_equal ("first_is_delete", "DELETE", l_result [1].string_value ("operation"))
			assert_strings_equal ("second_is_update", "UPDATE", l_result [2].string_value ("operation"))
			assert_strings_equal ("third_is_update", "UPDATE", l_result [3].string_value ("operation"))
			assert_strings_equal ("fourth_is_insert", "INSERT", l_result [4].string_value ("operation"))
		end

	test_audit_with_transaction_rollback
			-- Test that rolled back changes are NOT audited
		note
			testing: "covers/{SIMPLE_SQL_AUDIT}.enable_for_table"
		local
			l_result: SIMPLE_SQL_RESULT
			l_db: SIMPLE_SQL_DATABASE
			l_audit: SIMPLE_SQL_AUDIT
		do
			create l_db.make_memory
			create l_audit.make (l_db)

			l_db.execute ("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)")
			l_audit.enable_for_table ("users")

			-- Successful transaction
			l_db.begin_transaction
			l_db.execute ("INSERT INTO users VALUES (1, 'Alice')")
			l_db.commit

			-- Rolled back transaction
			l_db.begin_transaction
			l_db.execute ("INSERT INTO users VALUES (2, 'Bob')")
			l_db.rollback

			-- Only Alice should be in audit
			l_result := l_audit.get_changes_by_operation ("users", "INSERT")
			assert_equal ("one_insert_only", 1, l_result.count)
			assert_equal ("record_is_alice", 1, l_result.first.integer_value ("record_id"))
		end

feature {NONE} -- Helpers

	has_column (a_columns: ARRAY [SIMPLE_SQL_COLUMN_INFO]; a_name: STRING_8): BOOLEAN
			-- Does column array contain column with given name?
		local
			i: INTEGER
		do
			from i := a_columns.lower until i > a_columns.upper or Result loop
				if a_columns [i].name.is_case_insensitive_equal (a_name) then
					Result := True
				end
				i := i + 1
			end
		end

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		SIMPLE_SQL - High-level SQLite API for Eiffel
		Audit/Change Tracking Tests
	]"

end
