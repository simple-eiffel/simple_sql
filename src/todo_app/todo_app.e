note
	description: "[
		Todo application demonstrating SIMPLE_SQL library usage.

		This is a consumer example showing how to use:
		- SIMPLE_SQL_DATABASE for database operations
		- SIMPLE_SQL_REPOSITORY pattern for CRUD
		- Migrations for schema management
		- Query builders for complex queries
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TODO_APP

create
	make,
	make_with_database

feature {NONE} -- Initialization

	make
			-- Create todo app with in-memory database.
		do
			create database.make_memory
			create repository.make (database)
			repository.create_table
		ensure
			database_open: database.is_open
		end

	make_with_database (a_database: SIMPLE_SQL_DATABASE)
			-- Create todo app with existing database.
		require
			database_open: a_database.is_open
		do
			database := a_database
			create repository.make (database)
			repository.create_table
		ensure
			database_set: database = a_database
		end

feature -- Access

	database: SIMPLE_SQL_DATABASE
			-- Database connection.

	repository: TODO_REPOSITORY
			-- Todo item repository.

feature -- Commands: CRUD

	add_todo (a_title: READABLE_STRING_8; a_priority: INTEGER): TODO_ITEM
			-- Create and save a new todo item.
		require
			title_not_empty: not a_title.is_empty
			valid_priority: a_priority >= 1 and a_priority <= 5
		local
			l_item: TODO_ITEM
			l_id: INTEGER_64
		do
			create l_item.make_new (a_title, a_priority)
			l_id := repository.insert (l_item)
			check attached repository.find_by_id (l_id) as al_l_saved then
				Result := al_l_saved
			end
		ensure
			result_saved: not Result.is_new
			title_matches: Result.title.same_string (a_title)
			priority_matches: Result.priority = a_priority
		end

	add_todo_with_details (a_title: READABLE_STRING_8; a_description: detachable READABLE_STRING_8;
			a_priority: INTEGER; a_due_date: detachable READABLE_STRING_8): TODO_ITEM
			-- Create and save a new todo item with full details.
		require
			title_not_empty: not a_title.is_empty
			valid_priority: a_priority >= 1 and a_priority <= 5
		local
			l_item: TODO_ITEM
			l_id: INTEGER_64
		do
			create l_item.make_new (a_title, a_priority)
			l_item.set_description (a_description)
			l_item.set_due_date (a_due_date)
			l_id := repository.insert (l_item)
			check attached repository.find_by_id (l_id) as al_l_saved then
				Result := al_l_saved
			end
		ensure
			result_saved: not Result.is_new
		end

	complete_todo (a_id: INTEGER_64): BOOLEAN
			-- Mark a todo as completed.
		require
			valid_id: a_id > 0
		do
			Result := repository.mark_completed (a_id)
		end

	uncomplete_todo (a_id: INTEGER_64): BOOLEAN
			-- Mark a todo as not completed.
		require
			valid_id: a_id > 0
		do
			Result := repository.mark_incomplete (a_id)
		end

	delete_todo (a_id: INTEGER_64): BOOLEAN
			-- Delete a todo item.
		require
			valid_id: a_id > 0
		do
			Result := repository.delete (a_id)
		ensure
			gone_if_success: Result implies not repository.exists (a_id)
		end

	clear_completed: INTEGER
			-- Delete all completed todos, return count deleted.
		do
			Result := repository.delete_completed
		ensure
			non_negative: Result >= 0
		end

feature -- Queries

	all_todos: ARRAYED_LIST [TODO_ITEM]
			-- All todos ordered by priority.
		do
			Result := repository.find_all_ordered ("priority ASC, created_at DESC")
		end

	incomplete_todos: ARRAYED_LIST [TODO_ITEM]
			-- All incomplete todos.
		do
			Result := repository.find_incomplete
		end

	completed_todos: ARRAYED_LIST [TODO_ITEM]
			-- All completed todos.
		do
			Result := repository.find_completed
		end

	high_priority_todos: ARRAYED_LIST [TODO_ITEM]
			-- Todos with priority 1 or 2.
		do
			Result := repository.find_where_ordered ("priority <= 2 AND is_completed = 0", "priority ASC")
		end

	todos_due_today: ARRAYED_LIST [TODO_ITEM]
			-- Incomplete todos due today.
		do
			Result := repository.find_due_today
		end

	overdue_todos: ARRAYED_LIST [TODO_ITEM]
			-- Incomplete todos past due date.
		do
			Result := repository.find_overdue
		end

	find_todo (a_id: INTEGER_64): detachable TODO_ITEM
			-- Find todo by ID.
		require
			valid_id: a_id > 0
		do
			Result := repository.find_by_id (a_id)
		end

	search_todos (a_term: READABLE_STRING_8): ARRAYED_LIST [TODO_ITEM]
			-- Search todos by title (case-insensitive LIKE).
		require
			term_not_empty: not a_term.is_empty
		do
			Result := repository.find_where ("title LIKE '%%" + a_term + "%%'")
		end

feature -- Statistics

	total_count: INTEGER
			-- Total number of todos.
		do
			Result := repository.count
		end

	incomplete_count: INTEGER
			-- Number of incomplete todos.
		do
			Result := repository.incomplete_count
		end

	completed_count: INTEGER
			-- Number of completed todos.
		do
			Result := repository.completed_count
		end

	overdue_count: INTEGER
			-- Number of overdue todos.
		do
			Result := repository.overdue_count
		end

	completion_percentage: REAL_64
			-- Percentage of todos completed.
		local
			l_total: INTEGER
		do
			l_total := total_count
			if l_total > 0 then
				Result := (completed_count / l_total) * 100.0
			end
		ensure
			valid_range: Result >= 0.0 and Result <= 100.0
		end

feature -- Lifecycle

	close
			-- Close the database connection.
		do
			if database.is_open then
				database.close
			end
		ensure
			closed: not database.is_open
		end

invariant
	database_attached: database /= Void
	repository_attached: repository /= Void

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
