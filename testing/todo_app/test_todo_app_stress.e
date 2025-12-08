note
	description: "Stress tests for TODO_APP exercising SIMPLE_SQL library"
	testing: "covers"
	testing: "execution/serial"

class
	TEST_TODO_APP_STRESS

inherit
	TEST_SET_BASE

feature -- Test routines: Volume Stress

	test_volume_10000_todos
			-- Test inserting and querying 10,000 todos.
		local
			l_app: TODO_APP
			l_ignored: TODO_ITEM
			i: INTEGER
			l_all: ARRAYED_LIST [TODO_ITEM]
		do
			create l_app.make

			-- Insert 10,000 todos
			from i := 1 until i > 10000 loop
				l_ignored := l_app.add_todo ("Task " + i.out, (i \\ 5) + 1)
				i := i + 1
			end

			assert_equal ("count_10000", 10000, l_app.total_count)

			-- Query all
			l_all := l_app.all_todos
			assert_equal ("all_10000", 10000, l_all.count)

			l_app.close
		end

	test_volume_pagination_large
			-- Test pagination through 10,000 records.
		local
			l_app: TODO_APP
			l_ignored: TODO_ITEM
			l_page: ARRAYED_LIST [TODO_ITEM]
			i, l_offset, l_total_fetched: INTEGER
		do
			create l_app.make

			-- Insert 10,000 todos
			from i := 1 until i > 10000 loop
				l_ignored := l_app.add_todo ("Task " + i.out, 3)
				i := i + 1
			end

			-- Paginate through in batches of 500
			from l_offset := 0 until l_offset >= 10000 loop
				l_page := l_app.repository.find_all_limited (500, l_offset)
				l_total_fetched := l_total_fetched + l_page.count
				l_offset := l_offset + 500
			end

			assert_equal ("fetched_all", 10000, l_total_fetched)

			l_app.close
		end

	test_volume_streaming_cursor
			-- Test streaming cursor through large result set.
		local
			l_app: TODO_APP
			l_ignored: TODO_ITEM
			l_cursor: SIMPLE_SQL_CURSOR
			i, l_count: INTEGER
		do
			create l_app.make

			-- Insert 5,000 todos
			from i := 1 until i > 5000 loop
				l_ignored := l_app.add_todo ("Task " + i.out, 3)
				i := i + 1
			end

			-- Stream through with cursor
			l_cursor := l_app.database.query_cursor ("SELECT * FROM todos")
			from l_cursor.start until l_cursor.after loop
				l_count := l_count + 1
				l_cursor.forth
			end
			l_cursor.close

			assert_equal ("streamed_5000", 5000, l_count)

			l_app.close
		end

feature -- Test routines: Transaction Stress

	test_transaction_bulk_complete
			-- Test bulk completion in transaction.
		local
			l_app: TODO_APP
			l_ignored: TODO_ITEM
			i: INTEGER
		do
			create l_app.make

			-- Insert 100 todos
			from i := 1 until i > 100 loop
				l_ignored := l_app.add_todo ("Task " + i.out, 3)
				i := i + 1
			end

			-- Bulk complete in transaction
			l_app.database.begin_transaction
			l_app.database.execute ("UPDATE todos SET is_completed = 1")
			l_app.database.commit

			assert_equal ("all_completed", 100, l_app.completed_count)
			assert_equal ("none_incomplete", 0, l_app.incomplete_count)

			l_app.close
		end

	test_transaction_rollback_on_failure
			-- Test rollback preserves data integrity.
		local
			l_app: TODO_APP
			l_ignored: TODO_ITEM
			i: INTEGER
			l_count_before: INTEGER
		do
			create l_app.make

			-- Insert 50 todos
			from i := 1 until i > 50 loop
				l_ignored := l_app.add_todo ("Task " + i.out, 3)
				i := i + 1
			end

			l_count_before := l_app.total_count

			-- Start transaction, make changes, then rollback
			l_app.database.begin_transaction
			l_app.database.execute ("DELETE FROM todos WHERE id <= 25")
			l_app.database.rollback

			-- Count should be unchanged
			assert_equal ("count_preserved", l_count_before, l_app.total_count)

			l_app.close
		end

	test_transaction_batch_insert
			-- Test batch insert with transaction wrapping.
		local
			l_app: TODO_APP
			l_batch: SIMPLE_SQL_BATCH
			i: INTEGER
		do
			create l_app.make
			create l_batch.make (l_app.database)

			-- Batch insert 1000 todos
			l_batch.begin
			from i := 1 until i > 1000 loop
				l_app.database.execute ("INSERT INTO todos (title, priority) VALUES ('Batch " + i.out + "', 3)")
				i := i + 1
			end
			l_batch.commit

			assert_equal ("batch_1000", 1000, l_app.total_count)

			l_app.close
		end

feature -- Test routines: Rapid CRUD Cycles

	test_rapid_crud_cycles
			-- Test rapid create-update-delete cycles.
		local
			l_app: TODO_APP
			l_todo: TODO_ITEM
			l_ignored_bool: BOOLEAN
			i: INTEGER
		do
			create l_app.make

			-- 500 rapid CRUD cycles
			from i := 1 until i > 500 loop
				-- Create
				l_todo := l_app.add_todo ("Rapid " + i.out, 3)
				-- Update (complete)
				l_ignored_bool := l_app.complete_todo (l_todo.id)
				-- Delete
				l_ignored_bool := l_app.delete_todo (l_todo.id)
				i := i + 1
			end

			-- Should be empty after all cycles
			assert_equal ("all_deleted", 0, l_app.total_count)

			l_app.close
		end

	test_rapid_update_same_record
			-- Test rapid updates to same record.
		local
			l_app: TODO_APP
			l_todo: TODO_ITEM
			l_ignored_bool: BOOLEAN
			i: INTEGER
		do
			create l_app.make
			l_todo := l_app.add_todo ("Toggle me", 3)

			-- Toggle complete/incomplete 1000 times
			from i := 1 until i > 1000 loop
				if i \\ 2 = 1 then
					l_ignored_bool := l_app.complete_todo (l_todo.id)
				else
					l_ignored_bool := l_app.uncomplete_todo (l_todo.id)
				end
				i := i + 1
			end

			-- Should be incomplete (1000 is even)
			if attached l_app.find_todo (l_todo.id) as l_found then
				assert_false ("final_incomplete", l_found.is_completed)
			end

			l_app.close
		end

feature -- Test routines: Query Stress

	test_query_with_many_conditions
			-- Test complex queries with multiple conditions.
		local
			l_app: TODO_APP
			l_ignored: TODO_ITEM
			l_results: ARRAYED_LIST [TODO_ITEM]
			i: INTEGER
		do
			create l_app.make

			-- Insert varied todos
			from i := 1 until i > 1000 loop
				l_ignored := l_app.add_todo_with_details (
					"Task " + i.out,
					"Description for task " + i.out,
					(i \\ 5) + 1,
					"2025-" + ((i \\ 12) + 1).out + "-15"
				)
				i := i + 1
			end

			-- Complex query: priority 1-2, not completed
			l_results := l_app.repository.find_where ("priority <= 2 AND is_completed = 0")
			assert_true ("found_high_priority", l_results.count > 0)

			-- All results should have priority 1 or 2
			assert_true ("all_high", across l_results as ic all ic.priority <= 2 end)

			l_app.close
		end

	test_search_large_dataset
			-- Test search performance on large dataset.
		local
			l_app: TODO_APP
			l_ignored: TODO_ITEM
			l_results: ARRAYED_LIST [TODO_ITEM]
			i: INTEGER
		do
			create l_app.make

			-- Insert 2000 todos with varied titles
			from i := 1 until i > 2000 loop
				if i \\ 10 = 0 then
					l_ignored := l_app.add_todo ("URGENT: Task " + i.out, 1)
				else
					l_ignored := l_app.add_todo ("Regular task " + i.out, 3)
				end
				i := i + 1
			end

			-- Search for URGENT
			l_results := l_app.search_todos ("URGENT")
			assert_equal ("found_200_urgent", 200, l_results.count)

			l_app.close
		end

feature -- Test routines: Prepared Statement Stress

	test_prepared_statement_reuse
			-- Test prepared statement reuse for many inserts.
		local
			l_app: TODO_APP
			l_stmt: SIMPLE_SQL_PREPARED_STATEMENT
			i: INTEGER
		do
			create l_app.make

			-- Prepare once, execute many times
			l_stmt := l_app.database.prepare ("INSERT INTO todos (title, priority) VALUES (?, ?)")

			from i := 1 until i > 1000 loop
				l_stmt.bind_text (1, "Prepared " + i.out)
				l_stmt.bind_integer (2, (i \\ 5) + 1)
				l_stmt.execute
				l_stmt.reset
				i := i + 1
			end

			assert_equal ("prepared_1000", 1000, l_app.total_count)

			l_app.close
		end

feature -- Test routines: FTS5 Search (if enabled)

	test_fts5_description_search
			-- Test FTS5 full-text search on descriptions.
		note
			testing: "covers/{SIMPLE_SQL_FTS5}"
		local
			l_app: TODO_APP
			l_fts5: SIMPLE_SQL_FTS5
			l_result: SIMPLE_SQL_RESULT
			i: INTEGER
		do
			create l_app.make
			create l_fts5.make (l_app.database)

			if l_fts5.is_fts5_available then
				-- Create FTS5 table for descriptions
				l_fts5.create_table ("todo_search", <<"title", "description">>)

				-- Insert searchable todos
				from i := 1 until i > 100 loop
					if i \\ 10 = 0 then
						l_fts5.insert ("todo_search", <<"title", "description">>,
							<<"Important meeting", "Discuss project timeline and deliverables">>)
					else
						l_fts5.insert ("todo_search", <<"title", "description">>,
							<<"Regular task", "Just a normal task description">>)
					end
					i := i + 1
				end

				-- Search for "project"
				l_result := l_fts5.search ("todo_search", "project")
				assert_equal ("found_10_project", 10, l_result.count)

				-- Search for "timeline"
				l_result := l_fts5.search ("todo_search", "timeline")
				assert_equal ("found_10_timeline", 10, l_result.count)
			end

			l_app.close
		end

feature -- Test routines: JSON Metadata

	test_json_metadata_storage
			-- Test storing JSON metadata in descriptions.
		local
			l_app: TODO_APP
			l_json: SIMPLE_SQL_JSON
			l_todo: TODO_ITEM
		do
			create l_app.make
			create l_json.make (l_app.database)

			-- Store JSON in description
			l_todo := l_app.add_todo_with_details (
				"Task with metadata",
				"{%"tags%": [%"urgent%", %"review%"], %"assignee%": %"john%"}",
				1,
				Void
			)

			-- Query and extract JSON
			if attached l_app.find_todo (l_todo.id) as l_found then
				if attached l_found.description as l_desc then
					if attached l_json.extract (l_desc, "$.assignee") as l_extracted then
						assert_strings_equal ("assignee", "john", l_extracted)
					end
				end
			end

			l_app.close
		end

	test_json_aggregate_todos
			-- Test JSON aggregation of todo data.
		local
			l_app: TODO_APP
			l_json: SIMPLE_SQL_JSON
			l_ignored: TODO_ITEM
			l_json_array: STRING_8
			i: INTEGER
		do
			create l_app.make
			create l_json.make (l_app.database)

			-- Insert some todos
			from i := 1 until i > 5 loop
				l_ignored := l_app.add_todo ("Task " + i.out, i)
				i := i + 1
			end

			-- Aggregate titles to JSON array
			l_json_array := l_json.aggregate_to_array ("todos", "title", Void)
			assert_true ("has_array", l_json_array.count > 0)
			assert_true ("starts_bracket", l_json_array.starts_with ("["))

			l_app.close
		end

feature -- Test routines: Audit Trail

	test_audit_tracking
			-- Test audit trail for todo changes.
		local
			l_app: TODO_APP
			l_audit: SIMPLE_SQL_AUDIT
			l_todo: TODO_ITEM
			l_changes: SIMPLE_SQL_RESULT
			l_ignored_bool: BOOLEAN
		do
			create l_app.make
			create l_audit.make (l_app.database)

			-- Enable auditing
			l_audit.enable_for_table ("todos")

			-- Create a todo
			l_todo := l_app.add_todo ("Audited task", 2)

			-- Modify it
			l_ignored_bool := l_app.complete_todo (l_todo.id)

			-- Delete it
			l_ignored_bool := l_app.delete_todo (l_todo.id)

			-- Check audit trail
			l_changes := l_audit.get_changes_for_record ("todos", l_todo.id.to_integer_32)

			-- Should have INSERT, UPDATE, DELETE
			assert_equal ("three_changes", 3, l_changes.count)

			l_app.close
		end

feature -- Test routines: Migration Simulation

	test_schema_migration_add_column
			-- Test simulated schema migration adding a column.
		local
			l_app: TODO_APP
			l_schema: SIMPLE_SQL_SCHEMA
			l_columns: ARRAYED_LIST [SIMPLE_SQL_COLUMN_INFO]
			l_has_tags: BOOLEAN
		do
			create l_app.make
			create l_schema.make (l_app.database)

			-- Add a new column via ALTER TABLE
			l_app.database.execute ("ALTER TABLE todos ADD COLUMN tags TEXT")

			-- Verify column exists
			l_columns := l_schema.columns ("todos")
			across l_columns as ic loop
				if ic.name.same_string ("tags") then
					l_has_tags := True
				end
			end

			assert_true ("has_tags_column", l_has_tags)

			-- Use the new column
			l_app.database.execute ("UPDATE todos SET tags = 'test' WHERE id = 1")

			l_app.close
		end

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
