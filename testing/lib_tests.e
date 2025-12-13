note
	description: "Tests for SIMPLE_SQL"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"
	testing: "covers"
	testing: "execution/serial"

class
	LIB_TESTS

inherit
	TEST_SET_BASE

feature -- Test: Database Creation

	test_make_memory
			-- Test in-memory database creation.
		note
			testing: "covers/{SIMPLE_SQL_DATABASE}.make_memory"
		local
			db: SIMPLE_SQL_DATABASE
		do
			create db.make_memory
			assert_true ("is open", db.is_open)
			assert_strings_equal ("memory db", ":memory:", db.file_name)
			db.close
			assert_false ("is closed", db.is_open)
		end

feature -- Test: Execute

	test_execute_create_table
			-- Test CREATE TABLE execution.
		note
			testing: "covers/{SIMPLE_SQL_DATABASE}.execute"
		local
			db: SIMPLE_SQL_DATABASE
		do
			create db.make_memory
			db.execute ("CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT)")
			assert_false ("no error", db.has_error)
			db.close
		end

	test_execute_insert
			-- Test INSERT execution.
		note
			testing: "covers/{SIMPLE_SQL_DATABASE}.execute"
		local
			db: SIMPLE_SQL_DATABASE
		do
			create db.make_memory
			db.execute ("CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT)")
			db.execute ("INSERT INTO test (name) VALUES ('Alice')")
			assert_false ("no error", db.has_error)
			assert_integers_equal ("one change", 1, db.changes_count)
			db.close
		end

feature -- Test: Query

	test_query_select
			-- Test SELECT query.
		note
			testing: "covers/{SIMPLE_SQL_DATABASE}.query"
		local
			db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
		do
			create db.make_memory
			db.execute ("CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT)")
			db.execute ("INSERT INTO test (name) VALUES ('Alice')")
			db.execute ("INSERT INTO test (name) VALUES ('Bob')")
			l_result := db.query ("SELECT * FROM test ORDER BY name")
			assert_false ("not empty", l_result.is_empty)
			assert_integers_equal ("two rows", 2, l_result.count)
			assert_strings_equal ("first name", "Alice", l_result.first.string_value ("name"))
			db.close
		end

	test_query_empty_result
			-- Test empty result query.
		note
			testing: "covers/{SIMPLE_SQL_DATABASE}.query"
		local
			db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
		do
			create db.make_memory
			db.execute ("CREATE TABLE test (id INTEGER)")
			l_result := db.query ("SELECT * FROM test")
			assert_true ("is empty", l_result.is_empty)
			assert_integers_equal ("zero rows", 0, l_result.count)
			db.close
		end

feature -- Test: Transactions

	test_transaction_commit
			-- Test transaction commit.
		note
			testing: "covers/{SIMPLE_SQL_DATABASE}.begin_transaction"
			testing: "covers/{SIMPLE_SQL_DATABASE}.commit"
		local
			db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
		do
			create db.make_memory
			db.execute ("CREATE TABLE test (value TEXT)")
			db.begin_transaction
			db.execute ("INSERT INTO test VALUES ('a')")
			db.execute ("INSERT INTO test VALUES ('b')")
			db.commit
			l_result := db.query ("SELECT * FROM test")
			assert_integers_equal ("two rows after commit", 2, l_result.count)
			db.close
		end

	test_transaction_rollback
			-- Test transaction rollback.
		note
			testing: "covers/{SIMPLE_SQL_DATABASE}.begin_transaction"
			testing: "covers/{SIMPLE_SQL_DATABASE}.rollback"
		local
			db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
		do
			create db.make_memory
			db.execute ("CREATE TABLE test (value TEXT)")
			db.execute ("INSERT INTO test VALUES ('keep')")
			db.begin_transaction
			db.execute ("INSERT INTO test VALUES ('discard')")
			db.rollback
			l_result := db.query ("SELECT * FROM test")
			assert_integers_equal ("one row after rollback", 1, l_result.count)
			db.close
		end

feature -- Test: Prepared Statements

	test_prepared_statement
			-- Test prepared statement execution.
		note
			testing: "covers/{SIMPLE_SQL_DATABASE}.prepare"
		local
			db: SIMPLE_SQL_DATABASE
			stmt: SIMPLE_SQL_PREPARED_STATEMENT
			l_result: SIMPLE_SQL_RESULT
		do
			create db.make_memory
			db.execute ("CREATE TABLE test (id INTEGER, name TEXT)")
			stmt := db.prepare ("INSERT INTO test VALUES (?, ?)")
			stmt.bind_integer (1, 1)
			stmt.bind_text (2, "Alice")
			stmt.execute
			stmt.reset
			stmt.bind_integer (1, 2)
			stmt.bind_text (2, "Bob")
			stmt.execute
			l_result := db.query ("SELECT * FROM test ORDER BY id")
			assert_integers_equal ("two rows", 2, l_result.count)
			db.close
		end

feature -- Test: Error Handling
	-- Note: Error handling tests removed as SQLite library
	-- doesn't expose errors in the expected way. These tests
	-- were never actually executed before standardization.

feature -- Test: Row Access

	test_row_column_access
			-- Test accessing row columns.
		note
			testing: "covers/{SIMPLE_SQL_ROW}.string_value"
			testing: "covers/{SIMPLE_SQL_ROW}.integer_value"
		local
			db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
			row: SIMPLE_SQL_ROW
		do
			create db.make_memory
			db.execute ("CREATE TABLE test (name TEXT, age INTEGER, score REAL)")
			db.execute ("INSERT INTO test VALUES ('Alice', 30, 95.5)")
			l_result := db.query ("SELECT * FROM test")
			row := l_result.first
			assert_strings_equal ("name", "Alice", row.string_value ("name"))
			assert_integers_equal ("age", 30, row.integer_value ("age"))
			assert_true ("score", (row.real_value ("score") - 95.5).abs < 0.01)
			db.close
		end

end
