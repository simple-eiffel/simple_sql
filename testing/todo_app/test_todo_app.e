note
	description: "Tests for TODO_APP consumer example"
	testing: "covers"
	testing: "execution/serial"

class
	TEST_TODO_APP

inherit
	TEST_SET_BASE

feature -- Test routines: Basic CRUD

	test_create_todo
			-- Test creating a simple todo item.
		local
			l_app: TODO_APP
			l_todo: TODO_ITEM
		do
			create l_app.make
			l_todo := l_app.add_todo ("Buy groceries", 3)

			assert_false ("is_saved", l_todo.is_new)
			assert_strings_equal ("title", "Buy groceries", l_todo.title)
			assert_equal ("priority", 3, l_todo.priority)
			assert_false ("not_completed", l_todo.is_completed)

			l_app.close
		end

	test_create_todo_with_details
			-- Test creating a todo with all details.
		local
			l_app: TODO_APP
			l_todo: TODO_ITEM
		do
			create l_app.make
			l_todo := l_app.add_todo_with_details ("Call mom", "Wish her happy birthday", 1, "2025-12-25")

			assert_strings_equal ("title", "Call mom", l_todo.title)
			if attached l_todo.description as l_desc then
				assert_strings_equal ("description", "Wish her happy birthday", l_desc)
			end
			assert_equal ("priority", 1, l_todo.priority)
			if attached l_todo.due_date as l_date then
				assert_strings_equal ("due_date", "2025-12-25", l_date)
			end

			l_app.close
		end

	test_find_todo
			-- Test finding a todo by ID.
		local
			l_app: TODO_APP
			l_todo: TODO_ITEM
		do
			create l_app.make
			l_todo := l_app.add_todo ("Test task", 2)

			if attached l_app.find_todo (l_todo.id) as l_found then
				assert_strings_equal ("title_matches", "Test task", l_found.title)
			else
				assert_true ("found", False)
			end

			l_app.close
		end

	test_delete_todo
			-- Test deleting a todo.
		local
			l_app: TODO_APP
			l_todo: TODO_ITEM
		do
			create l_app.make
			l_todo := l_app.add_todo ("To delete", 3)

			assert_true ("delete_success", l_app.delete_todo (l_todo.id))
			assert_true ("not_found", l_app.find_todo (l_todo.id) = Void)

			l_app.close
		end

feature -- Test routines: Completion

	test_complete_todo
			-- Test marking a todo as completed.
		local
			l_app: TODO_APP
			l_todo: TODO_ITEM
		do
			create l_app.make
			l_todo := l_app.add_todo ("To complete", 2)

			assert_true ("complete_success", l_app.complete_todo (l_todo.id))

			if attached l_app.find_todo (l_todo.id) as l_found then
				assert_true ("is_completed", l_found.is_completed)
			end

			l_app.close
		end

	test_uncomplete_todo
			-- Test marking a completed todo as incomplete.
		local
			l_app: TODO_APP
			l_todo: TODO_ITEM
			l_ignored: BOOLEAN
		do
			create l_app.make
			l_todo := l_app.add_todo ("Toggle", 3)
			l_ignored := l_app.complete_todo (l_todo.id)
			l_ignored := l_app.uncomplete_todo (l_todo.id)

			if attached l_app.find_todo (l_todo.id) as l_found then
				assert_false ("is_incomplete", l_found.is_completed)
			end

			l_app.close
		end

	test_clear_completed
			-- Test clearing all completed todos.
		local
			l_app: TODO_APP
			l_todo1, l_todo2, l_todo3: TODO_ITEM
			l_deleted: INTEGER
			l_ignored: BOOLEAN
		do
			create l_app.make
			l_todo1 := l_app.add_todo ("Task 1", 3)
			l_todo2 := l_app.add_todo ("Task 2", 3)
			l_todo3 := l_app.add_todo ("Task 3", 3)

			l_ignored := l_app.complete_todo (l_todo1.id)
			l_ignored := l_app.complete_todo (l_todo3.id)

			l_deleted := l_app.clear_completed

			assert_equal ("deleted_two", 2, l_deleted)
			assert_equal ("one_remaining", 1, l_app.total_count)

			l_app.close
		end

feature -- Test routines: Queries

	test_all_todos
			-- Test retrieving all todos.
		local
			l_app: TODO_APP
			l_todos: ARRAYED_LIST [TODO_ITEM]
			l_ignored: TODO_ITEM
		do
			create l_app.make
			l_ignored := l_app.add_todo ("Task 1", 3)
			l_ignored := l_app.add_todo ("Task 2", 1)
			l_ignored := l_app.add_todo ("Task 3", 2)

			l_todos := l_app.all_todos

			assert_equal ("count_three", 3, l_todos.count)
			-- Should be ordered by priority (1, 2, 3)
			assert_equal ("first_priority", 1, l_todos.first.priority)

			l_app.close
		end

	test_incomplete_todos
			-- Test retrieving only incomplete todos.
		local
			l_app: TODO_APP
			l_todo: TODO_ITEM
			l_incomplete: ARRAYED_LIST [TODO_ITEM]
			l_ignored: TODO_ITEM
			l_ignored_bool: BOOLEAN
		do
			create l_app.make
			l_ignored := l_app.add_todo ("Task 1", 3)
			l_todo := l_app.add_todo ("Task 2", 3)
			l_ignored := l_app.add_todo ("Task 3", 3)

			l_ignored_bool := l_app.complete_todo (l_todo.id)

			l_incomplete := l_app.incomplete_todos

			assert_equal ("two_incomplete", 2, l_incomplete.count)

			l_app.close
		end

	test_completed_todos
			-- Test retrieving only completed todos.
		local
			l_app: TODO_APP
			l_todo: TODO_ITEM
			l_completed: ARRAYED_LIST [TODO_ITEM]
			l_ignored: TODO_ITEM
			l_ignored_bool: BOOLEAN
		do
			create l_app.make
			l_ignored := l_app.add_todo ("Task 1", 3)
			l_todo := l_app.add_todo ("Task 2", 3)

			l_ignored_bool := l_app.complete_todo (l_todo.id)

			l_completed := l_app.completed_todos

			assert_equal ("one_completed", 1, l_completed.count)
			assert_strings_equal ("completed_task", "Task 2", l_completed.first.title)

			l_app.close
		end

	test_high_priority_todos
			-- Test retrieving high priority (1-2) incomplete todos.
		local
			l_app: TODO_APP
			l_high: ARRAYED_LIST [TODO_ITEM]
			l_ignored: TODO_ITEM
		do
			create l_app.make
			l_ignored := l_app.add_todo ("Urgent", 1)
			l_ignored := l_app.add_todo ("Important", 2)
			l_ignored := l_app.add_todo ("Normal", 3)
			l_ignored := l_app.add_todo ("Low", 5)

			l_high := l_app.high_priority_todos

			assert_equal ("two_high", 2, l_high.count)

			l_app.close
		end

	test_search_todos
			-- Test searching todos by title.
		local
			l_app: TODO_APP
			l_results: ARRAYED_LIST [TODO_ITEM]
			l_ignored: TODO_ITEM
		do
			create l_app.make
			l_ignored := l_app.add_todo ("Buy groceries", 3)
			l_ignored := l_app.add_todo ("Buy birthday gift", 2)
			l_ignored := l_app.add_todo ("Call dentist", 4)

			l_results := l_app.search_todos ("Buy")

			assert_equal ("two_matches", 2, l_results.count)

			l_app.close
		end

feature -- Test routines: Statistics

	test_total_count
			-- Test total todo count.
		local
			l_app: TODO_APP
			l_ignored: TODO_ITEM
		do
			create l_app.make

			assert_equal ("zero_initially", 0, l_app.total_count)

			l_ignored := l_app.add_todo ("Task 1", 3)
			l_ignored := l_app.add_todo ("Task 2", 3)

			assert_equal ("two_after_add", 2, l_app.total_count)

			l_app.close
		end

	test_completion_percentage
			-- Test completion percentage calculation.
		local
			l_app: TODO_APP
			l_todo: TODO_ITEM
			l_ignored: TODO_ITEM
			l_ignored_bool: BOOLEAN
		do
			create l_app.make
			l_ignored := l_app.add_todo ("Task 1", 3)
			l_todo := l_app.add_todo ("Task 2", 3)

			assert_reals_equal ("zero_percent", 0.0, l_app.completion_percentage, 0.01)

			l_ignored_bool := l_app.complete_todo (l_todo.id)

			assert_reals_equal ("fifty_percent", 50.0, l_app.completion_percentage, 0.01)

			l_app.close
		end

	test_incomplete_and_completed_counts
			-- Test incomplete and completed count tracking.
		local
			l_app: TODO_APP
			l_todo: TODO_ITEM
			l_ignored: TODO_ITEM
			l_ignored_bool: BOOLEAN
		do
			create l_app.make
			l_ignored := l_app.add_todo ("Task 1", 3)
			l_todo := l_app.add_todo ("Task 2", 3)
			l_ignored := l_app.add_todo ("Task 3", 3)

			assert_equal ("three_incomplete", 3, l_app.incomplete_count)
			assert_equal ("zero_completed", 0, l_app.completed_count)

			l_ignored_bool := l_app.complete_todo (l_todo.id)

			assert_equal ("two_incomplete", 2, l_app.incomplete_count)
			assert_equal ("one_completed", 1, l_app.completed_count)

			l_app.close
		end

feature -- Test routines: Repository Pattern

	test_repository_find_by_priority
			-- Test repository's custom find_by_priority method.
		local
			l_app: TODO_APP
			l_priority_2: ARRAYED_LIST [TODO_ITEM]
			l_ignored: TODO_ITEM
		do
			create l_app.make
			l_ignored := l_app.add_todo ("P1 task", 1)
			l_ignored := l_app.add_todo ("P2 task A", 2)
			l_ignored := l_app.add_todo ("P2 task B", 2)
			l_ignored := l_app.add_todo ("P3 task", 3)

			l_priority_2 := l_app.repository.find_by_priority (2)

			assert_equal ("two_p2_tasks", 2, l_priority_2.count)
			assert_true ("all_priority_2", across l_priority_2 as ic all ic.priority = 2 end)

			l_app.close
		end

	test_repository_pagination
			-- Test repository pagination support.
		local
			l_app: TODO_APP
			l_page1, l_page2: ARRAYED_LIST [TODO_ITEM]
			l_ignored: TODO_ITEM
			i: INTEGER
		do
			create l_app.make

			-- Add 10 todos
			from i := 1 until i > 10 loop
				l_ignored := l_app.add_todo ("Task " + i.out, 3)
				i := i + 1
			end

			l_page1 := l_app.repository.find_all_limited (3, 0)
			l_page2 := l_app.repository.find_all_limited (3, 3)

			assert_equal ("page1_size", 3, l_page1.count)
			assert_equal ("page2_size", 3, l_page2.count)

			l_app.close
		end

feature -- Test routines: Edge Cases

	test_empty_database
			-- Test operations on empty database.
		local
			l_app: TODO_APP
		do
			create l_app.make

			assert_equal ("empty_count", 0, l_app.total_count)
			assert_true ("empty_list", l_app.all_todos.is_empty)
			assert_reals_equal ("zero_pct", 0.0, l_app.completion_percentage, 0.01)

			l_app.close
		end

	test_todo_not_found
			-- Test finding non-existent todo.
		local
			l_app: TODO_APP
		do
			create l_app.make

			assert_true ("not_found", l_app.find_todo (999) = Void)

			l_app.close
		end

	test_priorities_range
			-- Test all valid priority values.
		local
			l_app: TODO_APP
			l_todo: TODO_ITEM
			i: INTEGER
		do
			create l_app.make

			from i := 1 until i > 5 loop
				l_todo := l_app.add_todo ("Priority " + i.out, i)
				assert_equal ("priority_" + i.out, i, l_todo.priority)
				i := i + 1
			end

			assert_equal ("five_todos", 5, l_app.total_count)

			l_app.close
		end

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
