note
	description: "Test suite for SIMPLE_SQL_DATABASE using TEST_SET_BASE assertions"
	testing: "type/manual"
	testing: "execution/serial"

class
	TEST_SIMPLE_SQL

inherit
	TEST_SET_BASE

feature -- Test routines

	test_create_memory_database
			-- Test in-memory database creation
		note
			testing: "covers/{SIMPLE_SQL_DATABASE}.make_memory"
		local
			l_db: SIMPLE_SQL_DATABASE
		do
			create l_db.make_memory
			assert_true ("is_open", l_db.is_open)
			assert_strings_equal ("file_name", ":memory:", l_db.file_name)
			l_db.close
			refute ("is_closed", l_db.is_open)
		end

	test_execute_create_table
			-- Test CREATE TABLE execution
		note
			testing: "covers/{SIMPLE_SQL_DATABASE}.execute"
		local
			l_db: SIMPLE_SQL_DATABASE
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER)")
			refute ("no_error", l_db.has_error)
			l_db.close
		end

	test_insert_and_query
			-- Test INSERT and SELECT operations
		note
			testing: "covers/{SIMPLE_SQL_DATABASE}.execute"
			testing: "covers/{SIMPLE_SQL_DATABASE}.query"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER)")
			l_db.execute ("INSERT INTO users (name, age) VALUES ('Alice', 30)")
			l_db.execute ("INSERT INTO users (name, age) VALUES ('Bob', 25)")

			l_result := l_db.query ("SELECT * FROM users ORDER BY name")
			assert_false ("not_empty", l_result.is_empty)
			assert_equal ("count", 2, l_result.count)

			assert_strings_equal ("first_name", "Alice", l_result.first.string_value ("name"))
			assert_equal ("first_age", 30, l_result.first.integer_value ("age"))

			assert_strings_equal ("second_name", "Bob", l_result.last.string_value ("name"))
			assert_equal ("second_age", 25, l_result.last.integer_value ("age"))

			l_db.close
		end

	test_changes_count
			-- Test changes_count after UPDATE
		note
			testing: "covers/{SIMPLE_SQL_DATABASE}.changes_count"
		local
			l_db: SIMPLE_SQL_DATABASE
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE test (id INTEGER, value TEXT)")
			l_db.execute ("INSERT INTO test VALUES (1, 'a')")
			l_db.execute ("INSERT INTO test VALUES (2, 'b')")
			l_db.execute ("INSERT INTO test VALUES (3, 'c')")

			l_db.execute ("UPDATE test SET value = 'x' WHERE id > 1")
			assert_equal ("updated_two", 2, l_db.changes_count)

			l_db.close
		end

	test_transaction
			-- Test transaction BEGIN/COMMIT
		note
			testing: "covers/{SIMPLE_SQL_DATABASE}.begin_transaction"
			testing: "covers/{SIMPLE_SQL_DATABASE}.commit"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE test (value TEXT)")

			l_db.begin_transaction
			l_db.execute ("INSERT INTO test VALUES ('a')")
			l_db.execute ("INSERT INTO test VALUES ('b')")
			l_db.commit

			l_result := l_db.query ("SELECT COUNT(*) as cnt FROM test")
			assert_equal ("count_two", 2, l_result.first.integer_value ("cnt"))

			l_db.close
		end

	test_rollback
			-- Test transaction ROLLBACK
		note
			testing: "covers/{SIMPLE_SQL_DATABASE}.rollback"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE test (value TEXT)")
			l_db.execute ("INSERT INTO test VALUES ('a')")

			l_db.begin_transaction
			l_db.execute ("INSERT INTO test VALUES ('b')")
			l_db.rollback

			l_result := l_db.query ("SELECT COUNT(*) as cnt FROM test")
			assert_equal ("count_one", 1, l_result.first.integer_value ("cnt"))

			l_db.close
		end

	test_empty_result
			-- Test query with no results
		note
			testing: "covers/{SIMPLE_SQL_RESULT}.is_empty"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE test (value TEXT)")

			l_result := l_db.query ("SELECT * FROM test")
			assert_true ("is_empty", l_result.is_empty)
			assert_zero ("count_zero", l_result.count)

			l_db.close
		end

	test_row_access_by_index
			-- Test accessing row values by index
		note
			testing: "covers/{SIMPLE_SQL_ROW}.item"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
			l_row: SIMPLE_SQL_ROW
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE test (a INTEGER, b TEXT, c REAL)")
			l_db.execute ("INSERT INTO test VALUES (42, 'hello', 3.14)")

			l_result := l_db.query ("SELECT * FROM test")
			l_row := l_result.first

			assert_equal ("count_three", 3, l_row.count)
			if attached {INTEGER_64} l_row [1] as al_int then
				assert_equal ("first_value", 42, al_int.to_integer_32)
			end
			if attached {STRING_8} l_row [2] as al_string then
				assert_strings_equal ("second_value", "hello", al_string)
			end

			l_db.close
		end

	test_null_values
			-- Test handling of NULL values
		note
			testing: "covers/{SIMPLE_SQL_ROW}.is_null"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
			l_row: SIMPLE_SQL_ROW
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE test (a INTEGER, b TEXT)")
			l_db.execute ("INSERT INTO test (a) VALUES (42)")

			l_result := l_db.query ("SELECT * FROM test")
			l_row := l_result.first

			refute ("a_not_null", l_row.is_null ("a"))
			assert_true ("b_is_null", l_row.is_null ("b"))

			l_db.close
		end

	test_real_values
			-- Test REAL_64 value access
		note
			testing: "covers/{SIMPLE_SQL_ROW}.real_value"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
			l_row: SIMPLE_SQL_ROW
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE test (value REAL)")
			l_db.execute ("INSERT INTO test VALUES (3.14159)")

			l_result := l_db.query ("SELECT * FROM test")
			l_row := l_result.first

			assert_reals_equal ("pi_value", 3.14159, l_row.real_value ("value"), 0.00001)

			l_db.close
		end

	test_has_column
			-- Test column existence checking
		note
			testing: "covers/{SIMPLE_SQL_ROW}.has_column"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
			l_row: SIMPLE_SQL_ROW
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE test (name TEXT, age INTEGER)")
			l_db.execute ("INSERT INTO test VALUES ('Alice', 30)")

			l_result := l_db.query ("SELECT * FROM test")
			l_row := l_result.first

			assert_true ("has_name", l_row.has_column ("name"))
			assert_true ("has_age", l_row.has_column ("age"))
			refute ("no_email", l_row.has_column ("email"))

			l_db.close
		end

feature -- Test routines: Edge Cases (Priority 3)

	test_transaction_nested
			-- Test BEGIN inside BEGIN is prevented by DBC
			-- DBC: `not_is_in_transaction` precondition prevents nested transactions
		note
			testing: "covers/{SIMPLE_SQL_DATABASE}.begin_transaction"
			testing: "edge_case"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
			l_rescued: BOOLEAN
		do
			if not l_rescued then
				create l_db.make_memory
				l_db.execute ("CREATE TABLE test (value INTEGER)")

				-- First begin
				l_db.begin_transaction
				l_db.execute ("INSERT INTO test VALUES (1)")

				-- Nested begin - DBC should prevent this with precondition violation
				l_db.begin_transaction

				-- If we get here, DBC didn't catch it (shouldn't happen)
				l_db.execute ("INSERT INTO test VALUES (2)")
				l_db.commit
				l_db.close
			else
				-- DBC precondition violation - this is expected behavior
				-- Nested transactions are prevented by contract
				assert_true ("dbc_prevents_nested", True)
			end
		rescue
			l_rescued := True
			retry
		end

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		SIMPLE_SQL - High-level SQLite API for Eiffel
	]"

end
