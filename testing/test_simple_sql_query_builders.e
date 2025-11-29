note
	description: "Tests for SIMPLE_SQL_SELECT_BUILDER, INSERT_BUILDER, UPDATE_BUILDER, DELETE_BUILDER"
	testing: "type/manual"
	testing: "execution/serial"

class
	TEST_SIMPLE_SQL_QUERY_BUILDERS

inherit
	TEST_SET_BASE

feature -- Test routines: SELECT Builder SQL Generation

	test_select_all
			-- Test SELECT * generation
		local
			l_builder: SIMPLE_SQL_SELECT_BUILDER
		do
			create l_builder.make
			assert_strings_equal ("select_all", "SELECT * FROM users",
				l_builder.select_all.from_table ("users").to_sql)
		end

	test_select_columns
			-- Test SELECT specific columns
		local
			l_builder: SIMPLE_SQL_SELECT_BUILDER
		do
			create l_builder.make
			assert_strings_equal ("select_cols", "SELECT name, age FROM users",
				l_builder.select_column ("name").select_column ("age").from_table ("users").to_sql)
		end

	test_select_distinct
			-- Test SELECT DISTINCT
		local
			l_builder: SIMPLE_SQL_SELECT_BUILDER
		do
			create l_builder.make
			assert_strings_equal ("distinct", "SELECT DISTINCT name FROM users",
				l_builder.distinct.select_column ("name").from_table ("users").to_sql)
		end

	test_select_where
			-- Test WHERE clause
		local
			l_builder: SIMPLE_SQL_SELECT_BUILDER
		do
			create l_builder.make
			assert_strings_equal ("where", "SELECT * FROM users WHERE age > 18",
				l_builder.select_all.from_table ("users").where ("age > 18").to_sql)
		end

	test_select_where_equals
			-- Test WHERE column = value
		local
			l_builder: SIMPLE_SQL_SELECT_BUILDER
		do
			create l_builder.make
			assert_strings_equal ("where_eq", "SELECT * FROM users WHERE name = 'Alice'",
				l_builder.select_all.from_table ("users").where_equals ("name", "Alice").to_sql)
		end

	test_select_and_where
			-- Test AND WHERE
		local
			l_builder: SIMPLE_SQL_SELECT_BUILDER
		do
			create l_builder.make
			assert_strings_equal ("and_where", "SELECT * FROM users WHERE age > 18 AND status = 'active'",
				l_builder.select_all.from_table ("users").where ("age > 18").and_where ("status = 'active'").to_sql)
		end

	test_select_or_where
			-- Test OR WHERE
		local
			l_builder: SIMPLE_SQL_SELECT_BUILDER
		do
			create l_builder.make
			assert_strings_equal ("or_where", "SELECT * FROM users WHERE role = 'admin' OR role = 'mod'",
				l_builder.select_all.from_table ("users").where ("role = 'admin'").or_where ("role = 'mod'").to_sql)
		end

	test_select_order_by
			-- Test ORDER BY
		local
			l_builder: SIMPLE_SQL_SELECT_BUILDER
		do
			create l_builder.make
			assert_strings_equal ("order", "SELECT * FROM users ORDER BY name",
				l_builder.select_all.from_table ("users").order_by ("name").to_sql)
		end

	test_select_order_by_desc
			-- Test ORDER BY DESC
		local
			l_builder: SIMPLE_SQL_SELECT_BUILDER
		do
			create l_builder.make
			assert_strings_equal ("order_desc", "SELECT * FROM users ORDER BY created_at DESC",
				l_builder.select_all.from_table ("users").order_by_desc ("created_at").to_sql)
		end

	test_select_limit_offset
			-- Test LIMIT and OFFSET
		local
			l_builder: SIMPLE_SQL_SELECT_BUILDER
		do
			create l_builder.make
			assert_strings_equal ("limit_offset", "SELECT * FROM users LIMIT 10 OFFSET 20",
				l_builder.select_all.from_table ("users").limit (10).offset (20).to_sql)
		end

	test_select_group_by
			-- Test GROUP BY
		local
			l_builder: SIMPLE_SQL_SELECT_BUILDER
		do
			create l_builder.make
			assert_strings_equal ("group", "SELECT status, COUNT(*) FROM users GROUP BY status",
				l_builder.select_column ("status").select_column ("COUNT(*)").from_table ("users").group_by ("status").to_sql)
		end

	test_select_join
			-- Test JOIN
		local
			l_builder: SIMPLE_SQL_SELECT_BUILDER
		do
			create l_builder.make
			assert_string_contains ("has_join",
				l_builder.select_all.from_table ("users").join ("orders", "orders.user_id = users.id").to_sql,
				"JOIN orders ON orders.user_id = users.id")
		end

	test_select_left_join
			-- Test LEFT JOIN
		local
			l_builder: SIMPLE_SQL_SELECT_BUILDER
		do
			create l_builder.make
			assert_string_contains ("has_left_join",
				l_builder.select_all.from_table ("users").left_join ("orders", "orders.user_id = users.id").to_sql,
				"LEFT JOIN orders ON orders.user_id = users.id")
		end

feature -- Test routines: SELECT Builder Execution

	test_select_execute
			-- Test executing SELECT query
		local
			l_db: SIMPLE_SQL_DATABASE
			l_result: detachable SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE users (id INTEGER, name TEXT)")
			l_db.execute ("INSERT INTO users VALUES (1, 'Alice')")
			l_db.execute ("INSERT INTO users VALUES (2, 'Bob')")

			l_result := l_db.select_builder.select_all.from_table ("users").order_by ("name").execute
			if attached l_result as l_r then
				assert_equal ("count", 2, l_r.count)
				assert_strings_equal ("first", "Alice", l_r.first.string_value ("name"))
			else
				assert_true ("result_attached", False)
			end

			l_db.close
		end

	test_select_count
			-- Test count() shortcut
		local
			l_db: SIMPLE_SQL_DATABASE
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE users (id INTEGER)")
			l_db.execute ("INSERT INTO users VALUES (1)")
			l_db.execute ("INSERT INTO users VALUES (2)")
			l_db.execute ("INSERT INTO users VALUES (3)")

			assert_equal ("count_3", 3, l_db.select_builder.from_table ("users").count)

			l_db.close
		end

	test_select_exists
			-- Test exists() shortcut
		local
			l_db: SIMPLE_SQL_DATABASE
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE users (id INTEGER, name TEXT)")
			l_db.execute ("INSERT INTO users VALUES (1, 'Alice')")

			assert_true ("exists", l_db.select_builder.from_table ("users").where_equals ("name", "Alice").exists)
			assert_false ("not_exists", l_db.select_builder.from_table ("users").where_equals ("name", "Nobody").exists)

			l_db.close
		end

feature -- Test routines: INSERT Builder

	test_insert_to_sql
			-- Test INSERT SQL generation
		local
			l_builder: SIMPLE_SQL_INSERT_BUILDER
		do
			create l_builder.make
			assert_strings_equal ("insert", "INSERT INTO users (name, age) VALUES ('Alice', 30)",
				l_builder.into ("users").columns_list (<<"name", "age">>).values (<<"Alice", 30>>).to_sql)
		end

	test_insert_with_set
			-- Test INSERT using set() method
		local
			l_builder: SIMPLE_SQL_INSERT_BUILDER
		do
			create l_builder.make
			assert_strings_equal ("insert_set", "INSERT INTO users (name, age) VALUES ('Bob', 25)",
				l_builder.into ("users").set ("name", "Bob").set ("age", 25).to_sql)
		end

	test_insert_execute
			-- Test executing INSERT
		local
			l_db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
			l_rows: INTEGER
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)")

			l_rows := l_db.insert_builder.into ("users").set ("name", "Alice").execute

			l_result := l_db.query ("SELECT name FROM users")
			assert_strings_equal ("inserted", "Alice", l_result.first.string_value ("name"))

			l_db.close
		end

	test_insert_returning_id
			-- Test INSERT returning last ID
		local
			l_db: SIMPLE_SQL_DATABASE
			l_id: INTEGER_64
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)")

			l_id := l_db.insert_builder.into ("users").set ("name", "Alice").execute_returning_id
			assert_equal ("first_id", {INTEGER_64} 1, l_id)

			l_id := l_db.insert_builder.into ("users").set ("name", "Bob").execute_returning_id
			assert_equal ("second_id", {INTEGER_64} 2, l_id)

			l_db.close
		end

feature -- Test routines: UPDATE Builder

	test_update_to_sql
			-- Test UPDATE SQL generation
		local
			l_builder: SIMPLE_SQL_UPDATE_BUILDER
		do
			create l_builder.make
			assert_strings_equal ("update", "UPDATE users SET name = 'Bob' WHERE id = 1",
				l_builder.table ("users").set ("name", "Bob").where_equals ("id", 1).to_sql)
		end

	test_update_multiple_columns
			-- Test UPDATE multiple columns
		local
			l_builder: SIMPLE_SQL_UPDATE_BUILDER
		do
			create l_builder.make
			assert_strings_equal ("multi_update", "UPDATE users SET name = 'Bob', age = 30 WHERE id = 1",
				l_builder.table ("users").set ("name", "Bob").set ("age", 30).where_equals ("id", 1).to_sql)
		end

	test_update_increment
			-- Test UPDATE increment
		local
			l_builder: SIMPLE_SQL_UPDATE_BUILDER
		do
			create l_builder.make
			assert_string_contains ("increment",
				l_builder.table ("products").increment ("views").where_equals ("id", 1).to_sql,
				"views = views + 1")
		end

	test_update_decrement_by
			-- Test UPDATE decrement_by
		local
			l_builder: SIMPLE_SQL_UPDATE_BUILDER
		do
			create l_builder.make
			assert_string_contains ("decrement",
				l_builder.table ("products").decrement_by ("stock", 5).where_equals ("id", 1).to_sql,
				"stock = stock - 5")
		end

	test_update_execute
			-- Test executing UPDATE
		local
			l_db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
			l_count: INTEGER
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE users (id INTEGER, name TEXT)")
			l_db.execute ("INSERT INTO users VALUES (1, 'Alice')")

			l_count := l_db.update_builder.table ("users").set ("name", "Alicia").where_equals ("id", 1).execute

			assert_equal ("one_updated", 1, l_count)

			l_result := l_db.query ("SELECT name FROM users WHERE id = 1")
			assert_strings_equal ("updated", "Alicia", l_result.first.string_value ("name"))

			l_db.close
		end

feature -- Test routines: DELETE Builder

	test_delete_to_sql
			-- Test DELETE SQL generation
		local
			l_builder: SIMPLE_SQL_DELETE_BUILDER
		do
			create l_builder.make
			assert_strings_equal ("delete", "DELETE FROM users WHERE id = 1",
				l_builder.from_table ("users").where_equals ("id", 1).to_sql)
		end

	test_delete_with_and
			-- Test DELETE with AND clause
		local
			l_builder: SIMPLE_SQL_DELETE_BUILDER
		do
			create l_builder.make
			assert_strings_equal ("delete_and", "DELETE FROM logs WHERE level = 'debug' AND created_at < '2024-01-01'",
				l_builder.from_table ("logs").where_equals ("level", "debug").and_where ("created_at < '2024-01-01'").to_sql)
		end

	test_delete_execute
			-- Test executing DELETE
		local
			l_db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
			l_count: INTEGER
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE users (id INTEGER, name TEXT)")
			l_db.execute ("INSERT INTO users VALUES (1, 'Alice')")
			l_db.execute ("INSERT INTO users VALUES (2, 'Bob')")

			l_count := l_db.delete_builder.from_table ("users").where_equals ("id", 1).execute

			assert_equal ("one_deleted", 1, l_count)

			l_result := l_db.query ("SELECT COUNT(*) as cnt FROM users")
			assert_equal ("one_remaining", 1, l_result.first.integer_value ("cnt"))

			l_db.close
		end

	test_delete_execute_all
			-- Test DELETE all rows
		local
			l_db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
			l_count: INTEGER
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE temp (id INTEGER)")
			l_db.execute ("INSERT INTO temp VALUES (1)")
			l_db.execute ("INSERT INTO temp VALUES (2)")

			l_count := l_db.delete_builder.from_table ("temp").execute_all

			assert_equal ("two_deleted", 2, l_count)

			l_result := l_db.query ("SELECT COUNT(*) as cnt FROM temp")
			assert_equal ("none_remaining", 0, l_result.first.integer_value ("cnt"))

			l_db.close
		end

feature -- Test routines: Builder reset

	test_select_reset
			-- Test builder reset clears state
		local
			l_builder: SIMPLE_SQL_SELECT_BUILDER
			l_ignored: SIMPLE_SQL_SELECT_BUILDER
		do
			create l_builder.make
			l_ignored := l_builder.select_column ("name").from_table ("users").where ("id = 1")
			l_builder.reset

			assert_strings_equal ("after_reset", "SELECT *", l_builder.to_sql)
		end

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
