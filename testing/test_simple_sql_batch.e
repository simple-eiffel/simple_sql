note
	description: "Tests for SIMPLE_SQL_BATCH"
	testing: "type/manual"
	testing: "execution/serial"

class
	TEST_SIMPLE_SQL_BATCH

inherit
	TEST_SET_BASE

feature -- Test routines: Basic batch

	test_batch_begin_commit
			-- Test basic batch begin/commit
		local
			l_db: SIMPLE_SQL_DATABASE
			l_batch: SIMPLE_SQL_BATCH
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE test (value TEXT)")

			create l_batch.make (l_db)
			assert_false ("not_active", l_batch.is_active)

			l_batch.begin
			assert_true ("is_active", l_batch.is_active)
			assert_equal ("count_zero", 0, l_batch.operations_count)

			l_batch.add ("INSERT INTO test VALUES ('a')")
			l_batch.add ("INSERT INTO test VALUES ('b')")
			assert_equal ("count_two", 2, l_batch.operations_count)

			l_batch.commit
			assert_false ("not_active_after", l_batch.is_active)

			l_result := l_db.query ("SELECT COUNT(*) as cnt FROM test")
			assert_equal ("two_rows", 2, l_result.first.integer_value ("cnt"))

			l_db.close
		end

	test_batch_rollback
			-- Test batch rollback cancels all operations
		local
			l_db: SIMPLE_SQL_DATABASE
			l_batch: SIMPLE_SQL_BATCH
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE test (value TEXT)")
			l_db.execute ("INSERT INTO test VALUES ('initial')")

			create l_batch.make (l_db)
			l_batch.begin
			l_batch.add ("INSERT INTO test VALUES ('a')")
			l_batch.add ("INSERT INTO test VALUES ('b')")
			l_batch.rollback

			assert_false ("not_active", l_batch.is_active)
			assert_equal ("count_reset", 0, l_batch.operations_count)

			l_result := l_db.query ("SELECT COUNT(*) as cnt FROM test")
			assert_equal ("only_initial", 1, l_result.first.integer_value ("cnt"))

			l_db.close
		end

feature -- Test routines: Insert

	test_batch_insert
			-- Test batch insert with columns and values
		local
			l_db: SIMPLE_SQL_DATABASE
			l_batch: SIMPLE_SQL_BATCH
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE users (name TEXT, age INTEGER)")

			create l_batch.make (l_db)
			l_batch.begin
			l_batch.insert ("users", <<"name", "age">>, <<"Alice", 30>>)
			l_batch.insert ("users", <<"name", "age">>, <<"Bob", 25>>)
			l_batch.commit

			l_result := l_db.query ("SELECT * FROM users ORDER BY name")
			assert_equal ("two_users", 2, l_result.count)
			assert_strings_equal ("first_name", "Alice", l_result.first.string_value ("name"))
			assert_equal ("first_age", 30, l_result.first.integer_value ("age"))

			l_db.close
		end

	test_batch_insert_with_null
			-- Test batch insert with NULL values
		local
			l_db: SIMPLE_SQL_DATABASE
			l_batch: SIMPLE_SQL_BATCH
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE test (name TEXT, value TEXT)")

			create l_batch.make (l_db)
			l_batch.begin
			l_batch.insert ("test", <<"name", "value">>, <<"Alice", Void>>)
			l_batch.commit

			l_result := l_db.query ("SELECT * FROM test")
			assert_strings_equal ("name", "Alice", l_result.first.string_value ("name"))
			assert_true ("value_null", l_result.first.is_null ("value"))

			l_db.close
		end

feature -- Test routines: Update

	test_batch_update
			-- Test batch update
		local
			l_db: SIMPLE_SQL_DATABASE
			l_batch: SIMPLE_SQL_BATCH
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE users (id INTEGER, name TEXT, age INTEGER)")
			l_db.execute ("INSERT INTO users VALUES (1, 'Alice', 30)")
			l_db.execute ("INSERT INTO users VALUES (2, 'Bob', 25)")

			create l_batch.make (l_db)
			l_batch.begin
			l_batch.update ("users", <<"age">>, <<35>>, "id = 1")
			l_batch.update ("users", <<"name", "age">>, <<"Robert", 26>>, "id = 2")
			l_batch.commit

			l_result := l_db.query ("SELECT * FROM users ORDER BY id")
			assert_equal ("alice_age", 35, l_result.first.integer_value ("age"))
			assert_strings_equal ("bob_name", "Robert", l_result.last.string_value ("name"))
			assert_equal ("bob_age", 26, l_result.last.integer_value ("age"))

			l_db.close
		end

feature -- Test routines: Delete

	test_batch_delete
			-- Test batch delete
		local
			l_db: SIMPLE_SQL_DATABASE
			l_batch: SIMPLE_SQL_BATCH
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE test (id INTEGER, value TEXT)")
			l_db.execute ("INSERT INTO test VALUES (1, 'a')")
			l_db.execute ("INSERT INTO test VALUES (2, 'b')")
			l_db.execute ("INSERT INTO test VALUES (3, 'c')")

			create l_batch.make (l_db)
			l_batch.begin
			l_batch.delete ("test", "id = 1")
			l_batch.delete ("test", "id = 3")
			l_batch.commit

			l_result := l_db.query ("SELECT * FROM test")
			assert_equal ("one_row", 1, l_result.count)
			assert_strings_equal ("remaining", "b", l_result.first.string_value ("value"))

			l_db.close
		end

feature -- Test routines: Bulk operations

	test_insert_many
			-- Test insert_many for bulk inserts
		local
			l_db: SIMPLE_SQL_DATABASE
			l_batch: SIMPLE_SQL_BATCH
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE users (name TEXT, age INTEGER)")

			create l_batch.make (l_db)
			l_batch.insert_many ("users", <<"name", "age">>, <<
				<<"Alice", 30>>,
				<<"Bob", 25>>,
				<<"Carol", 35>>
			>>)

			l_result := l_db.query ("SELECT COUNT(*) as cnt FROM users")
			assert_equal ("three_users", 3, l_result.first.integer_value ("cnt"))

			l_result := l_db.query ("SELECT * FROM users ORDER BY age")
			assert_strings_equal ("youngest", "Bob", l_result.first.string_value ("name"))

			l_db.close
		end

	test_execute_many
			-- Test execute_many with parameterized SQL
		local
			l_db: SIMPLE_SQL_DATABASE
			l_batch: SIMPLE_SQL_BATCH
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE test (value TEXT)")

			create l_batch.make (l_db)
			l_batch.execute_many ("INSERT INTO test (value) VALUES (?)", <<
				<<"first">>,
				<<"second">>,
				<<"third">>
			>>)

			l_result := l_db.query ("SELECT COUNT(*) as cnt FROM test")
			assert_equal ("three_rows", 3, l_result.first.integer_value ("cnt"))

			l_db.close
		end

feature -- Test routines: Mixed operations

	test_mixed_batch_operations
			-- Test mixing insert, update, delete in one batch
		local
			l_db: SIMPLE_SQL_DATABASE
			l_batch: SIMPLE_SQL_BATCH
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE test (id INTEGER, value TEXT)")
			l_db.execute ("INSERT INTO test VALUES (1, 'original')")

			create l_batch.make (l_db)
			l_batch.begin
			l_batch.insert ("test", <<"id", "value">>, <<2, "new">>)
			l_batch.update ("test", <<"value">>, <<"modified">>, "id = 1")
			l_batch.delete ("test", "id = 999")  -- No-op delete
			l_batch.commit

			l_result := l_db.query ("SELECT * FROM test ORDER BY id")
			assert_equal ("two_rows", 2, l_result.count)
			assert_strings_equal ("modified", "modified", l_result.first.string_value ("value"))
			assert_strings_equal ("new", "new", l_result.last.string_value ("value"))

			l_db.close
		end

feature -- Test routines: Special characters

	test_batch_escaping
			-- Test special characters are properly escaped
		local
			l_db: SIMPLE_SQL_DATABASE
			l_batch: SIMPLE_SQL_BATCH
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE test (value TEXT)")

			create l_batch.make (l_db)
			l_batch.begin
			l_batch.insert ("test", <<"value">>, <<"O'Brien">>)
			l_batch.insert ("test", <<"value">>, <<"She said %"Hello%"">>)
			l_batch.commit

			l_result := l_db.query ("SELECT * FROM test ORDER BY rowid")
			assert_strings_equal ("quote", "O'Brien", l_result.first.string_value ("value"))

			l_db.close
		end

feature -- Test routines: Auto transaction

	test_insert_many_auto_transaction
			-- Test insert_many automatically wraps in transaction
		local
			l_db: SIMPLE_SQL_DATABASE
			l_batch: SIMPLE_SQL_BATCH
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE test (value INTEGER)")

			create l_batch.make (l_db)
			-- Not calling begin - insert_many should auto-wrap
			assert_false ("not_active_before", l_batch.is_active)

			l_batch.insert_many ("test", <<"value">>, <<
				<<1>>,
				<<2>>,
				<<3>>
			>>)

			assert_false ("not_active_after", l_batch.is_active)

			l_result := l_db.query ("SELECT SUM(value) as total FROM test")
			assert_equal ("sum", 6, l_result.first.integer_value ("total"))

			l_db.close
		end

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
