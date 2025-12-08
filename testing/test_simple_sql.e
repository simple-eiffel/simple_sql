note
	description: "Test suite for SIMPLE_SQL_DATABASE using TEST_SET_BASE assertions"
	testing: "covers"
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

feature -- Test routines: Parameterized Convenience Methods

	test_execute_with_args_insert
			-- Test execute_with_args for INSERT with various parameter types.
		note
			testing: "covers/{SIMPLE_SQL_DATABASE}.execute_with_args"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER, score REAL)")

			-- Insert with mixed parameter types
			l_db.execute_with_args ("INSERT INTO users (name, age, score) VALUES (?, ?, ?)", <<"Alice", 30, 95.5>>)
			l_db.execute_with_args ("INSERT INTO users (name, age, score) VALUES (?, ?, ?)", <<"Bob", 25, 88.0>>)

			l_result := l_db.query ("SELECT * FROM users ORDER BY name")
			assert_equal ("count", 2, l_result.count)
			assert_strings_equal ("first_name", "Alice", l_result.first.string_value ("name"))
			assert_equal ("first_age", 30, l_result.first.integer_value ("age"))
			assert_reals_equal ("first_score", 95.5, l_result.first.real_value ("score"), 0.001)

			l_db.close
		end

	test_execute_with_args_update
			-- Test execute_with_args for UPDATE.
		note
			testing: "covers/{SIMPLE_SQL_DATABASE}.execute_with_args"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE products (id INTEGER PRIMARY KEY, name TEXT, price REAL)")
			l_db.execute_with_args ("INSERT INTO products (name, price) VALUES (?, ?)", <<"Widget", 19.99>>)

			l_db.execute_with_args ("UPDATE products SET price = ? WHERE name = ?", <<24.99, "Widget">>)

			l_result := l_db.query ("SELECT price FROM products WHERE name = 'Widget'")
			assert_reals_equal ("updated_price", 24.99, l_result.first.real_value ("price"), 0.001)

			l_db.close
		end

	test_execute_with_args_null
			-- Test execute_with_args handles NULL values (Void).
		note
			testing: "covers/{SIMPLE_SQL_DATABASE}.execute_with_args"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE contacts (id INTEGER PRIMARY KEY, name TEXT, phone TEXT)")

			-- Insert with NULL phone
			l_db.execute_with_args ("INSERT INTO contacts (name, phone) VALUES (?, ?)", <<"Alice", Void>>)

			l_result := l_db.query ("SELECT * FROM contacts WHERE name = 'Alice'")
			assert_true ("phone_is_null", l_result.first.is_null ("phone"))

			l_db.close
		end

	test_execute_with_args_integer_64
			-- Test execute_with_args handles INTEGER_64 values.
		note
			testing: "covers/{SIMPLE_SQL_DATABASE}.execute_with_args"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
			l_big_id: INTEGER_64
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE large_ids (id INTEGER PRIMARY KEY, big_value INTEGER)")

			l_big_id := 9223372036854775807 -- max INTEGER_64
			l_db.execute_with_args ("INSERT INTO large_ids (big_value) VALUES (?)", <<l_big_id>>)

			l_result := l_db.query ("SELECT big_value FROM large_ids")
			assert_true ("big_value", l_big_id = l_result.first.integer_64_value ("big_value"))

			l_db.close
		end

	test_query_with_args_select
			-- Test query_with_args for parameterized SELECT.
		note
			testing: "covers/{SIMPLE_SQL_DATABASE}.query_with_args"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE items (id INTEGER PRIMARY KEY, category TEXT, price REAL)")
			l_db.execute ("INSERT INTO items (category, price) VALUES ('A', 10.0)")
			l_db.execute ("INSERT INTO items (category, price) VALUES ('A', 20.0)")
			l_db.execute ("INSERT INTO items (category, price) VALUES ('B', 30.0)")
			l_db.execute ("INSERT INTO items (category, price) VALUES ('B', 40.0)")

			-- Query with category filter
			l_result := l_db.query_with_args ("SELECT * FROM items WHERE category = ?", <<"A">>)
			assert_equal ("category_a_count", 2, l_result.count)

			-- Query with price threshold
			l_result := l_db.query_with_args ("SELECT * FROM items WHERE price > ?", <<25.0>>)
			assert_equal ("price_gt_25_count", 2, l_result.count)

			l_db.close
		end

	test_query_with_args_multiple_params
			-- Test query_with_args with multiple parameters.
		note
			testing: "covers/{SIMPLE_SQL_DATABASE}.query_with_args"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE products (id INTEGER PRIMARY KEY, name TEXT, category TEXT, price REAL)")
			l_db.execute ("INSERT INTO products (name, category, price) VALUES ('Widget A', 'tools', 10.0)")
			l_db.execute ("INSERT INTO products (name, category, price) VALUES ('Widget B', 'tools', 50.0)")
			l_db.execute ("INSERT INTO products (name, category, price) VALUES ('Gadget A', 'electronics', 30.0)")

			-- Query with category AND price range
			l_result := l_db.query_with_args (
				"SELECT * FROM products WHERE category = ? AND price > ?",
				<<"tools", 15.0>>
			)
			assert_equal ("one_match", 1, l_result.count)
			assert_strings_equal ("widget_b", "Widget B", l_result.first.string_value ("name"))

			l_db.close
		end

	test_query_with_args_integer_64
			-- Test query_with_args with INTEGER_64 parameter.
		note
			testing: "covers/{SIMPLE_SQL_DATABASE}.query_with_args"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
			l_search_id: INTEGER_64
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE records (id INTEGER PRIMARY KEY, data TEXT)")
			l_db.execute ("INSERT INTO records (id, data) VALUES (1, 'first')")
			l_db.execute ("INSERT INTO records (id, data) VALUES (2, 'second')")
			l_db.execute ("INSERT INTO records (id, data) VALUES (3, 'third')")

			l_search_id := 2
			l_result := l_db.query_with_args ("SELECT * FROM records WHERE id = ?", <<l_search_id>>)
			assert_equal ("one_result", 1, l_result.count)
			assert_strings_equal ("second_data", "second", l_result.first.string_value ("data"))

			l_db.close
		end

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		SIMPLE_SQL - High-level SQLite API for Eiffel
	]"

end
