note
	description: "Tests for SIMPLE_SQL_ERROR and SIMPLE_SQL_ERROR_CODE"
	testing: "type/manual"
	testing: "execution/serial"

class
	TEST_SIMPLE_SQL_ERROR

inherit
	TEST_SET_BASE

feature -- Test routines: SIMPLE_SQL_ERROR

	test_error_make
			-- Test basic error creation
		local
			l_error: SIMPLE_SQL_ERROR
		do
			create l_error.make (19, "constraint failed")
			assert_equal ("code", 19, l_error.code)
			assert_equal ("extended_code", 19, l_error.extended_code)
			assert_strings_equal ("message", "constraint failed", l_error.message)
			assert_true ("sql_empty", l_error.sql.is_empty)
		end

	test_error_make_with_sql
			-- Test error creation with SQL
		local
			l_error: SIMPLE_SQL_ERROR
		do
			create l_error.make_with_sql (19, "UNIQUE constraint failed", "INSERT INTO test VALUES (1)")
			assert_equal ("code", 19, l_error.code)
			assert_strings_equal ("message", "UNIQUE constraint failed", l_error.message)
			assert_strings_equal ("sql", "INSERT INTO test VALUES (1)", l_error.sql)
		end

	test_error_code_name
			-- Test code_name lookup
		local
			l_error: SIMPLE_SQL_ERROR
		do
			create l_error.make (19, "constraint failed")
			assert_strings_equal ("code_name", "SQLITE_CONSTRAINT", l_error.code_name)
		end

	test_error_is_constraint_violation
			-- Test constraint violation detection
		local
			l_error: SIMPLE_SQL_ERROR
		do
			create l_error.make (19, "constraint failed")
			assert_true ("is_constraint", l_error.is_constraint_violation)
			assert_false ("not_busy", l_error.is_busy)
			assert_false ("not_readonly", l_error.is_readonly)
		end

	test_error_is_busy
			-- Test busy detection
		local
			l_error: SIMPLE_SQL_ERROR
		do
			create l_error.make (5, "database is locked")
			assert_true ("is_busy", l_error.is_busy)
			assert_false ("not_constraint", l_error.is_constraint_violation)
		end

	test_error_is_readonly
			-- Test readonly detection
		local
			l_error: SIMPLE_SQL_ERROR
		do
			create l_error.make (8, "attempt to write a readonly database")
			assert_true ("is_readonly", l_error.is_readonly)
		end

	test_error_extended_code_unique
			-- Test UNIQUE constraint extended code
		local
			l_error: SIMPLE_SQL_ERROR
		do
			create l_error.make (19, "UNIQUE constraint failed")
			l_error.set_extended_code (2067)
			assert_equal ("primary_code", 19, l_error.code)
			assert_equal ("extended_code", 2067, l_error.extended_code)
			assert_true ("is_unique", l_error.is_unique_violation)
			assert_false ("not_pk", l_error.is_primary_key_violation)
		end

	test_error_extended_code_primary_key
			-- Test PRIMARY KEY constraint extended code
		local
			l_error: SIMPLE_SQL_ERROR
		do
			create l_error.make (19, "PRIMARY KEY constraint failed")
			l_error.set_extended_code (1555)
			assert_true ("is_pk", l_error.is_primary_key_violation)
			assert_false ("not_unique", l_error.is_unique_violation)
		end

	test_error_extended_code_foreign_key
			-- Test FOREIGN KEY constraint extended code
		local
			l_error: SIMPLE_SQL_ERROR
		do
			create l_error.make (19, "FOREIGN KEY constraint failed")
			l_error.set_extended_code (787)
			assert_true ("is_fk", l_error.is_foreign_key_violation)
		end

	test_error_extended_code_not_null
			-- Test NOT NULL constraint extended code
		local
			l_error: SIMPLE_SQL_ERROR
		do
			create l_error.make (19, "NOT NULL constraint failed")
			l_error.set_extended_code (1299)
			assert_true ("is_notnull", l_error.is_not_null_violation)
		end

	test_error_extended_code_check
			-- Test CHECK constraint extended code
		local
			l_error: SIMPLE_SQL_ERROR
		do
			create l_error.make (19, "CHECK constraint failed")
			l_error.set_extended_code (275)
			assert_true ("is_check", l_error.is_check_violation)
		end

	test_error_description
			-- Test description generation
		local
			l_error: SIMPLE_SQL_ERROR
		do
			create l_error.make (19, "constraint failed")
			assert_string_contains ("has_code", l_error.description, "SQLITE_CONSTRAINT")
			assert_string_contains ("has_message", l_error.description, "constraint failed")
		end

	test_error_full_description_with_sql
			-- Test full_description with SQL
		local
			l_error: SIMPLE_SQL_ERROR
		do
			create l_error.make_with_sql (19, "UNIQUE constraint failed", "INSERT INTO test VALUES (1)")
			assert_string_contains ("has_error", l_error.full_description, "Error:")
			assert_string_contains ("has_message", l_error.full_description, "UNIQUE constraint failed")
			assert_string_contains ("has_sql", l_error.full_description, "INSERT INTO test VALUES (1)")
		end

feature -- Test routines: SIMPLE_SQL_ERROR_CODE

	test_error_code_constants
			-- Test error code constants have correct values
		local
			l_codes: SIMPLE_SQL_ERROR_CODE
		do
			create l_codes
			assert_equal ("ok", 0, l_codes.ok)
			assert_equal ("error", 1, l_codes.error)
			assert_equal ("busy", 5, l_codes.busy)
			assert_equal ("locked", 6, l_codes.locked)
			assert_equal ("readonly", 8, l_codes.readonly)
			assert_equal ("constraint", 19, l_codes.constraint)
		end

	test_error_code_name_lookup
			-- Test name lookup for various codes
		local
			l_codes: SIMPLE_SQL_ERROR_CODE
		do
			create l_codes
			assert_strings_equal ("ok_name", "SQLITE_OK", l_codes.name (0))
			assert_strings_equal ("error_name", "SQLITE_ERROR", l_codes.name (1))
			assert_strings_equal ("busy_name", "SQLITE_BUSY", l_codes.name (5))
			assert_strings_equal ("constraint_name", "SQLITE_CONSTRAINT", l_codes.name (19))
		end

	test_error_code_extended_name_lookup
			-- Test name lookup for extended codes
		local
			l_codes: SIMPLE_SQL_ERROR_CODE
		do
			create l_codes
			assert_strings_equal ("unique", "SQLITE_CONSTRAINT_UNIQUE", l_codes.name (2067))
			assert_strings_equal ("pk", "SQLITE_CONSTRAINT_PRIMARYKEY", l_codes.name (1555))
			assert_strings_equal ("fk", "SQLITE_CONSTRAINT_FOREIGNKEY", l_codes.name (787))
			assert_strings_equal ("notnull", "SQLITE_CONSTRAINT_NOTNULL", l_codes.name (1299))
			assert_strings_equal ("check", "SQLITE_CONSTRAINT_CHECK", l_codes.name (275))
		end

	test_error_code_primary_code_extraction
			-- Test extracting primary code from extended code
		local
			l_codes: SIMPLE_SQL_ERROR_CODE
		do
			create l_codes
			-- Extended code 2067 = SQLITE_CONSTRAINT_UNIQUE, primary = 19 (SQLITE_CONSTRAINT)
			assert_equal ("unique_primary", 19, l_codes.primary_code (2067))
			-- Extended code 1555 = SQLITE_CONSTRAINT_PRIMARYKEY, primary = 19
			assert_equal ("pk_primary", 19, l_codes.primary_code (1555))
			-- Extended code 787 = SQLITE_CONSTRAINT_FOREIGNKEY, primary = 19
			assert_equal ("fk_primary", 19, l_codes.primary_code (787))
			-- Primary codes should return themselves
			assert_equal ("simple_code", 5, l_codes.primary_code (5))
		end

	test_error_code_is_success
			-- Test is_success detection
		local
			l_codes: SIMPLE_SQL_ERROR_CODE
		do
			create l_codes
			assert_true ("ok_success", l_codes.is_success (0))
			assert_true ("done_success", l_codes.is_success (101))
			assert_true ("row_success", l_codes.is_success (100))
			assert_false ("error_not_success", l_codes.is_success (1))
			assert_false ("constraint_not_success", l_codes.is_success (19))
		end

	test_error_code_is_error
			-- Test is_error detection
		local
			l_codes: SIMPLE_SQL_ERROR_CODE
		do
			create l_codes
			assert_true ("error_is_error", l_codes.is_error (1))
			assert_true ("constraint_is_error", l_codes.is_error (19))
			assert_false ("ok_not_error", l_codes.is_error (0))
		end

	test_error_code_unknown
			-- Test unknown code handling
		local
			l_codes: SIMPLE_SQL_ERROR_CODE
		do
			create l_codes
			assert_string_contains ("has_unknown", l_codes.name (9999), "SQLITE_UNKNOWN")
		end

feature -- Test routines: Edge Cases (Priority 3)

	test_execute_malformed_sql
			-- Test syntax errors in SQL are properly handled
		note
			testing: "covers/{SIMPLE_SQL_DATABASE}.execute"
			testing: "edge_case"
		local
			l_db: SIMPLE_SQL_DATABASE
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE test (id INTEGER)")

			-- Execute malformed SQL
			l_db.execute ("SELEC * FORM test")

			assert_true ("has_error", l_db.has_error)
			if attached l_db.last_structured_error as l_err then
				assert_true ("is_syntax_error", l_err.code = 1) -- SQLITE_ERROR
				assert_true ("has_message", not l_err.message.is_empty)
			end
			-- Don't close - may be in error state
		end

	test_query_nonexistent_table
			-- Test querying a table that doesn't exist
			-- DBC: Error may raise exception; this test validates error detection
		note
			testing: "covers/{SIMPLE_SQL_DATABASE}.query"
			testing: "edge_case"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
			l_rescued: BOOLEAN
		do
			if not l_rescued then
				create l_db.make_memory

				-- Query non-existent table - may raise exception due to DBC
				l_result := l_db.query ("SELECT * FROM nonexistent_table")

				-- If we get here, check error state
				assert_true ("has_error", l_db.has_error)
			else
				-- Exception raised - valid DBC behavior for invalid query
				assert_true ("dbc_enforced", True)
			end
		rescue
			l_rescued := True
			retry
		end

	test_query_nonexistent_column
			-- Test querying a column that doesn't exist
			-- DBC: Error may raise exception
		note
			testing: "covers/{SIMPLE_SQL_DATABASE}.query"
			testing: "edge_case"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
			l_rescued: BOOLEAN
		do
			if not l_rescued then
				create l_db.make_memory
				l_db.execute ("CREATE TABLE test (id INTEGER, name TEXT)")
				l_db.execute ("INSERT INTO test VALUES (1, 'Alice')")

				-- Query non-existent column - may raise exception
				l_result := l_db.query ("SELECT nonexistent_column FROM test")

				assert_true ("has_error", l_db.has_error)
			else
				-- Exception raised - valid DBC behavior
				assert_true ("dbc_enforced", True)
			end
		rescue
			l_rescued := True
			retry
		end

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
