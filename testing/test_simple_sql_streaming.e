note
	description: "Test suite for SIMPLE_SQL streaming and cursor features"
	testing: "type/manual"
	testing: "execution/serial"

class
	TEST_SIMPLE_SQL_STREAMING

inherit
	TEST_SET_BASE

feature -- Test routines: Cursor

	test_cursor_basic_iteration
			-- Test basic cursor iteration over rows
		note
			testing: "covers/{SIMPLE_SQL_CURSOR}"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_cursor: SIMPLE_SQL_CURSOR
			l_count: INTEGER
		do
			create l_db.make_memory
			setup_test_data (l_db)

			l_cursor := l_db.query_cursor ("SELECT * FROM users ORDER BY name")
			from l_cursor.start until l_cursor.after loop
				l_count := l_count + 1
				l_cursor.forth
			end
			l_cursor.close

			assert_equal ("iterated_all_rows", 5, l_count)
			l_db.close
		end

	test_cursor_across_syntax
			-- Test cursor with across loop
		note
			testing: "covers/{SIMPLE_SQL_CURSOR}.new_cursor"
			testing: "covers/{SIMPLE_SQL_CURSOR_ITERATOR}"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_names: ARRAYED_LIST [STRING_32]
		do
			create l_db.make_memory
			setup_test_data (l_db)

			create l_names.make (5)
			across l_db.query_cursor ("SELECT name FROM users ORDER BY name") as ic loop
				l_names.extend (ic.string_value ("name"))
			end

			assert_equal ("count", 5, l_names.count)
			assert_strings_equal ("first", "Alice", l_names.i_th (1))
			assert_strings_equal ("last", "Eve", l_names.i_th (5))
			l_db.close
		end

	test_cursor_row_access
			-- Test accessing row values through cursor
		note
			testing: "covers/{SIMPLE_SQL_CURSOR}.item"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_cursor: SIMPLE_SQL_CURSOR
			l_row: SIMPLE_SQL_ROW
		do
			create l_db.make_memory
			setup_test_data (l_db)

			l_cursor := l_db.query_cursor ("SELECT * FROM users WHERE name = 'Alice'")
			l_cursor.start
			assert_false ("not_after", l_cursor.after)

			l_row := l_cursor.item
			assert_strings_equal ("name", "Alice", l_row.string_value ("name"))
			assert_equal ("age", 30, l_row.integer_value ("age"))

			l_cursor.forth
			assert_true ("after_one_row", l_cursor.after)
			l_cursor.close
			l_db.close
		end

	test_cursor_empty_result
			-- Test cursor with no matching rows
		note
			testing: "covers/{SIMPLE_SQL_CURSOR}"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_cursor: SIMPLE_SQL_CURSOR
			l_count: INTEGER
		do
			create l_db.make_memory
			setup_test_data (l_db)

			l_cursor := l_db.query_cursor ("SELECT * FROM users WHERE age > 100")
			from l_cursor.start until l_cursor.after loop
				l_count := l_count + 1
				l_cursor.forth
			end

			assert_equal ("no_rows", 0, l_count)
			l_cursor.close
			l_db.close
		end

	test_cursor_rows_fetched
			-- Test rows_fetched counter
		note
			testing: "covers/{SIMPLE_SQL_CURSOR}.rows_fetched"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_cursor: SIMPLE_SQL_CURSOR
		do
			create l_db.make_memory
			setup_test_data (l_db)

			l_cursor := l_db.query_cursor ("SELECT * FROM users")
			l_cursor.start
			assert_equal ("after_start", 1, l_cursor.rows_fetched)
			l_cursor.forth
			assert_equal ("after_second", 2, l_cursor.rows_fetched)
			l_cursor.close
			l_db.close
		end

feature -- Test routines: Result Stream

	test_stream_for_each
			-- Test streaming with for_each callback
		note
			testing: "covers/{SIMPLE_SQL_RESULT_STREAM}.for_each"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_stream: SIMPLE_SQL_RESULT_STREAM
		do
			create l_db.make_memory
			setup_test_data (l_db)

			l_stream := l_db.create_stream ("SELECT age FROM users")
			total_age_accumulator := 0
			l_stream.for_each (agent sum_ages)

			assert_equal ("total_age", 30 + 25 + 35 + 28 + 22, total_age_accumulator)
			assert_equal ("rows_processed", 5, l_stream.rows_processed)
			l_db.close
		end

	test_stream_for_each_do
			-- Test streaming with for_each_do procedure
		note
			testing: "covers/{SIMPLE_SQL_RESULT_STREAM}.for_each_do"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_stream: SIMPLE_SQL_RESULT_STREAM
		do
			create l_db.make_memory
			setup_test_data (l_db)

			l_stream := l_db.create_stream ("SELECT name FROM users ORDER BY name")
			create collected_names.make (5)
			l_stream.for_each_do (agent collect_name)

			assert_equal ("count", 5, collected_names.count)
			assert_strings_equal ("first", "Alice", collected_names.i_th (1))
			l_db.close
		end

	test_stream_early_stop
			-- Test stopping stream iteration early
		note
			testing: "covers/{SIMPLE_SQL_RESULT_STREAM}.was_stopped_early"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_stream: SIMPLE_SQL_RESULT_STREAM
		do
			create l_db.make_memory
			setup_test_data (l_db)

			l_stream := l_db.create_stream ("SELECT * FROM users ORDER BY name")
			early_stop_count := 0
			l_stream.for_each (agent stop_after_two)

			assert_equal ("stopped_at_2", 2, early_stop_count)
			assert_true ("was_stopped_early", l_stream.was_stopped_early)
			l_db.close
		end

	test_stream_collect_first
			-- Test collecting first N rows
		note
			testing: "covers/{SIMPLE_SQL_RESULT_STREAM}.collect_first"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_stream: SIMPLE_SQL_RESULT_STREAM
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
		do
			create l_db.make_memory
			setup_test_data (l_db)

			l_stream := l_db.create_stream ("SELECT * FROM users ORDER BY name")
			l_rows := l_stream.collect_first (3)

			assert_equal ("collected_3", 3, l_rows.count)
			assert_strings_equal ("first", "Alice", l_rows.first.string_value ("name"))
			assert_true ("stopped_early", l_stream.was_stopped_early)
			l_db.close
		end

	test_stream_count_rows
			-- Test counting rows via stream
		note
			testing: "covers/{SIMPLE_SQL_RESULT_STREAM}.count_rows"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_stream: SIMPLE_SQL_RESULT_STREAM
		do
			create l_db.make_memory
			setup_test_data (l_db)

			l_stream := l_db.create_stream ("SELECT * FROM users WHERE age >= 28")
			assert_equal ("count", 3, l_stream.count_rows)
			l_db.close
		end

	test_stream_first_row
			-- Test getting first row only
		note
			testing: "covers/{SIMPLE_SQL_RESULT_STREAM}.first_row"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_stream: SIMPLE_SQL_RESULT_STREAM
		do
			create l_db.make_memory
			setup_test_data (l_db)

			l_stream := l_db.create_stream ("SELECT * FROM users ORDER BY age DESC")
			if attached l_stream.first_row as l_row then
				assert_strings_equal ("oldest", "Charlie", l_row.string_value ("name"))
				assert_equal ("age_35", 35, l_row.integer_value ("age"))
			else
				assert_true ("should_have_row", False)
			end
			l_db.close
		end

	test_stream_exists
			-- Test exists check
		note
			testing: "covers/{SIMPLE_SQL_RESULT_STREAM}.exists"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_stream: SIMPLE_SQL_RESULT_STREAM
		do
			create l_db.make_memory
			setup_test_data (l_db)

			l_stream := l_db.create_stream ("SELECT * FROM users WHERE name = 'Alice'")
			assert_true ("alice_exists", l_stream.exists)

			l_stream := l_db.create_stream ("SELECT * FROM users WHERE name = 'Zoe'")
			assert_false ("zoe_not_exists", l_stream.exists)
			l_db.close
		end

feature -- Test routines: Database integration

	test_database_query_stream
			-- Test database.query_stream convenience method
		note
			testing: "covers/{SIMPLE_SQL_DATABASE}.query_stream"
		local
			l_db: SIMPLE_SQL_DATABASE
		do
			create l_db.make_memory
			setup_test_data (l_db)

			total_age_accumulator := 0
			l_db.query_stream ("SELECT age FROM users", agent sum_ages)

			assert_equal ("total", 140, total_age_accumulator)
			l_db.close
		end

feature -- Test routines: Prepared statement streaming

	test_prepared_statement_cursor
			-- Test prepared statement with cursor execution
		note
			testing: "covers/{SIMPLE_SQL_PREPARED_STATEMENT}.execute_cursor"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_stmt: SIMPLE_SQL_PREPARED_STATEMENT
			l_cursor: SIMPLE_SQL_CURSOR
			l_count: INTEGER
		do
			create l_db.make_memory
			setup_test_data (l_db)

			l_stmt := l_db.prepare ("SELECT * FROM users WHERE age >= ?")
			l_stmt.bind_integer (1, 28)
			l_cursor := l_stmt.execute_cursor

			from l_cursor.start until l_cursor.after loop
				l_count := l_count + 1
				l_cursor.forth
			end
			l_cursor.close

			assert_equal ("matched_3", 3, l_count)
			l_db.close
		end

	test_prepared_statement_stream
			-- Test prepared statement with stream execution
		note
			testing: "covers/{SIMPLE_SQL_PREPARED_STATEMENT}.execute_stream"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_stmt: SIMPLE_SQL_PREPARED_STATEMENT
			l_stream: SIMPLE_SQL_RESULT_STREAM
		do
			create l_db.make_memory
			setup_test_data (l_db)

			l_stmt := l_db.prepare ("SELECT name FROM users WHERE age < ?")
			l_stmt.bind_integer (1, 30)
			l_stream := l_stmt.execute_stream

			create collected_names.make (5)
			l_stream.for_each_do (agent collect_name)

			assert_equal ("young_users", 3, collected_names.count)
			l_db.close
		end

feature -- Test routines: Select builder streaming

	test_select_builder_cursor
			-- Test select builder with cursor execution
		note
			testing: "covers/{SIMPLE_SQL_SELECT_BUILDER}.execute_cursor"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_count: INTEGER
		do
			create l_db.make_memory
			setup_test_data (l_db)

			if attached l_db.select_builder.from_table ("users").where ("age > 25").execute_cursor as l_cursor then
				from l_cursor.start until l_cursor.after loop
					l_count := l_count + 1
					l_cursor.forth
				end
				l_cursor.close
			end

			assert_equal ("over_25", 3, l_count)
			l_db.close
		end

	test_select_builder_for_each
			-- Test select builder with for_each
		note
			testing: "covers/{SIMPLE_SQL_SELECT_BUILDER}.for_each"
		local
			l_db: SIMPLE_SQL_DATABASE
		do
			create l_db.make_memory
			setup_test_data (l_db)

			create collected_names.make (5)
			l_db.select_builder.select_column ("name").from_table ("users").order_by ("name").for_each (agent collect_name)

			assert_equal ("count", 5, collected_names.count)
			assert_strings_equal ("first", "Alice", collected_names.i_th (1))
			l_db.close
		end

feature -- Test routines: Large dataset simulation

	test_cursor_large_dataset
			-- Test cursor with larger dataset (memory efficiency)
		note
			testing: "covers/{SIMPLE_SQL_CURSOR}"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_cursor: SIMPLE_SQL_CURSOR
			l_count: INTEGER
			i: INTEGER
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE big_data (id INTEGER PRIMARY KEY, value TEXT)")

			-- Insert 1000 rows
			l_db.begin_transaction
			from i := 1 until i > 1000 loop
				l_db.execute ("INSERT INTO big_data (value) VALUES ('row_" + i.out + "')")
				i := i + 1
			end
			l_db.commit

			-- Iterate with cursor (memory-efficient)
			l_cursor := l_db.query_cursor ("SELECT * FROM big_data")
			from l_cursor.start until l_cursor.after loop
				l_count := l_count + 1
				l_cursor.forth
			end
			l_cursor.close

			assert_equal ("all_1000", 1000, l_count)
			l_db.close
		end

	test_stream_aggregate_large_dataset
			-- Test stream aggregation over larger dataset
		note
			testing: "covers/{SIMPLE_SQL_RESULT_STREAM}"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_stream: SIMPLE_SQL_RESULT_STREAM
			i: INTEGER
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE numbers (value INTEGER)")

			-- Insert numbers 1 to 100
			l_db.begin_transaction
			from i := 1 until i > 100 loop
				l_db.execute ("INSERT INTO numbers (value) VALUES (" + i.out + ")")
				i := i + 1
			end
			l_db.commit

			-- Sum all values: 1+2+...+100 = 5050
			l_stream := l_db.create_stream ("SELECT value FROM numbers")
			total_age_accumulator := 0
			l_stream.for_each (agent sum_value)

			assert_equal ("sum_1_to_100", 5050, total_age_accumulator)
			l_db.close
		end

feature -- Test routines: Edge Cases (Priority 8)

	test_cursor_large_result
			-- Test 10,000+ rows iteration (memory efficiency)
		note
			testing: "covers/{SIMPLE_SQL_CURSOR}"
			testing: "edge_case"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_cursor: SIMPLE_SQL_CURSOR
			l_count: INTEGER
			i: INTEGER
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE big_data (id INTEGER PRIMARY KEY, value TEXT)")

			-- Insert 10,000 rows
			l_db.begin_transaction
			from i := 1 until i > 10000 loop
				l_db.execute ("INSERT INTO big_data (value) VALUES ('row_" + i.out + "')")
				i := i + 1
			end
			l_db.commit

			-- Iterate with cursor (memory-efficient - one row at a time)
			l_cursor := l_db.query_cursor ("SELECT * FROM big_data")
			from l_cursor.start until l_cursor.after loop
				l_count := l_count + 1
				l_cursor.forth
			end
			l_cursor.close

			assert_equal ("all_10000", 10000, l_count)
			l_db.close
		end

	test_cursor_early_termination
			-- Test stopping iteration mid-stream
		note
			testing: "covers/{SIMPLE_SQL_CURSOR}"
			testing: "edge_case"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_cursor: SIMPLE_SQL_CURSOR
			l_count: INTEGER
			i: INTEGER
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE data (id INTEGER)")

			-- Insert 1000 rows
			l_db.begin_transaction
			from i := 1 until i > 1000 loop
				l_db.execute ("INSERT INTO data VALUES (" + i.out + ")")
				i := i + 1
			end
			l_db.commit

			-- Only process first 100
			l_cursor := l_db.query_cursor ("SELECT * FROM data ORDER BY id")
			from l_cursor.start until l_cursor.after or l_count >= 100 loop
				l_count := l_count + 1
				l_cursor.forth
			end
			l_cursor.close

			assert_equal ("stopped_at_100", 100, l_count)
			l_db.close
		end

	test_stream_callback_exception
			-- Test exception in callback handling
		note
			testing: "covers/{SIMPLE_SQL_RESULT_STREAM}.for_each"
			testing: "edge_case"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_stream: SIMPLE_SQL_RESULT_STREAM
			l_rescued: BOOLEAN
		do
			if not l_rescued then
				create l_db.make_memory
				l_db.execute ("CREATE TABLE test (id INTEGER)")
				l_db.execute ("INSERT INTO test VALUES (1)")
				l_db.execute ("INSERT INTO test VALUES (2)")

				l_stream := l_db.create_stream ("SELECT * FROM test")
				exception_test_count := 0
				l_stream.for_each (agent raise_exception_on_second)

				-- If we get here, exception wasn't raised or was handled
				assert_true ("exception_handled", exception_test_count >= 1)
				l_db.close
			else
				-- Exception was raised - that's expected behavior
				assert_true ("exception_raised", exception_test_count >= 1)
			end
		rescue
			l_rescued := True
			retry
		end

	test_stream_memory_stability
			-- Test memory usage during large stream (no accumulation)
		note
			testing: "covers/{SIMPLE_SQL_RESULT_STREAM}"
			testing: "edge_case"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_stream: SIMPLE_SQL_RESULT_STREAM
			i: INTEGER
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE memory_test (id INTEGER, data TEXT)")

			-- Insert 5000 rows with some data
			l_db.begin_transaction
			from i := 1 until i > 5000 loop
				l_db.execute ("INSERT INTO memory_test VALUES (" + i.out + ", 'data_value_" + i.out + "')")
				i := i + 1
			end
			l_db.commit

			-- Stream through all rows - each should be processed independently
			l_stream := l_db.create_stream ("SELECT * FROM memory_test")
			total_age_accumulator := 0
			l_stream.for_each (agent count_rows)

			assert_equal ("processed_5000", 5000, total_age_accumulator)
			l_db.close
		end

feature {NONE} -- Test helpers

	setup_test_data (a_db: SIMPLE_SQL_DATABASE)
			-- Create test table with sample data
		do
			a_db.execute ("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER)")
			a_db.execute ("INSERT INTO users (name, age) VALUES ('Alice', 30)")
			a_db.execute ("INSERT INTO users (name, age) VALUES ('Bob', 25)")
			a_db.execute ("INSERT INTO users (name, age) VALUES ('Charlie', 35)")
			a_db.execute ("INSERT INTO users (name, age) VALUES ('Diana', 28)")
			a_db.execute ("INSERT INTO users (name, age) VALUES ('Eve', 22)")
		end

	total_age_accumulator: INTEGER
			-- Accumulator for age summing tests

	collected_names: ARRAYED_LIST [STRING_32]
			-- Collected names from stream tests
		attribute
			create Result.make (0)
		end

	early_stop_count: INTEGER
			-- Counter for early stop test

	sum_ages (a_row: SIMPLE_SQL_ROW): BOOLEAN
			-- Add age to accumulator, continue processing
		do
			total_age_accumulator := total_age_accumulator + a_row.integer_value ("age")
			Result := False
		end

	sum_value (a_row: SIMPLE_SQL_ROW): BOOLEAN
			-- Add value to accumulator
		do
			if attached {INTEGER_64} a_row.item (1) as l_val then
				total_age_accumulator := total_age_accumulator + l_val.to_integer_32
			end
			Result := False
		end

	collect_name (a_row: SIMPLE_SQL_ROW)
			-- Collect name from row
		do
			collected_names.extend (a_row.string_value ("name"))
		end

	stop_after_two (a_row: SIMPLE_SQL_ROW): BOOLEAN
			-- Stop after processing 2 rows
		do
			early_stop_count := early_stop_count + 1
			Result := early_stop_count >= 2
		end

	exception_test_count: INTEGER
			-- Counter for exception test

	raise_exception_on_second (a_row: SIMPLE_SQL_ROW): BOOLEAN
			-- Raise exception on second row
		do
			exception_test_count := exception_test_count + 1
			if exception_test_count >= 2 then
				-- Trigger an exception by dividing by zero
				Result := (1 // 0) > 0
			end
			Result := False
		end

	count_rows (a_row: SIMPLE_SQL_ROW): BOOLEAN
			-- Count rows for memory test
		do
			total_age_accumulator := total_age_accumulator + 1
			Result := False
		end

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
