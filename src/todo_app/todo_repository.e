note
	description: "Repository for TODO_ITEM entities using SIMPLE_SQL_REPOSITORY"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TODO_REPOSITORY

inherit
	SIMPLE_SQL_REPOSITORY [TODO_ITEM]

create
	make

feature -- Constants

	table_name: STRING_8 = "todos"
			-- <Precursor>

	primary_key_column: STRING_8 = "id"
			-- <Precursor>

feature -- Schema

	create_table
			-- Create the todos table if it doesn't exist.
			-- Includes extended fields for full task management.
		do
			database.execute ("[
				CREATE TABLE IF NOT EXISTS todos (
					id INTEGER PRIMARY KEY AUTOINCREMENT,
					title TEXT NOT NULL,
					description TEXT,
					priority INTEGER NOT NULL DEFAULT 3,
					is_completed INTEGER NOT NULL DEFAULT 0,
					due_date TEXT,
					status TEXT NOT NULL DEFAULT 'pending',
					context TEXT NOT NULL DEFAULT '',
					energy_level INTEGER NOT NULL DEFAULT 2,
					estimated_minutes INTEGER NOT NULL DEFAULT 0,
					actual_minutes INTEGER NOT NULL DEFAULT 0,
					parent_id INTEGER NOT NULL DEFAULT 0,
					created_at TEXT NOT NULL DEFAULT (datetime('now')),
					updated_at TEXT NOT NULL DEFAULT (datetime('now'))
				)
			]")
		ensure
			table_exists: database.schema.table_exists (table_name)
		end

	migrate_schema
			-- Add new columns if they don't exist (for existing databases).
		do
			-- SQLite doesn't support IF NOT EXISTS for columns, so we ignore errors
			database.execute ("ALTER TABLE todos ADD COLUMN status TEXT NOT NULL DEFAULT 'pending'")
			database.execute ("ALTER TABLE todos ADD COLUMN context TEXT NOT NULL DEFAULT ''")
			database.execute ("ALTER TABLE todos ADD COLUMN energy_level INTEGER NOT NULL DEFAULT 2")
			database.execute ("ALTER TABLE todos ADD COLUMN estimated_minutes INTEGER NOT NULL DEFAULT 0")
			database.execute ("ALTER TABLE todos ADD COLUMN actual_minutes INTEGER NOT NULL DEFAULT 0")
			database.execute ("ALTER TABLE todos ADD COLUMN parent_id INTEGER NOT NULL DEFAULT 0")
		end

	drop_table
			-- Drop the todos table if it exists.
		do
			database.execute ("DROP TABLE IF EXISTS todos")
		ensure
			table_gone: not database.schema.table_exists (table_name)
		end

feature -- Query: Custom

	find_incomplete: ARRAYED_LIST [TODO_ITEM]
			-- Find all incomplete todos ordered by priority.
		do
			Result := find_where_ordered ("is_completed = 0", "priority ASC, due_date ASC")
		ensure
			result_attached: Result /= Void
			all_incomplete: across Result as ic all not ic.is_completed end
		end

	find_completed: ARRAYED_LIST [TODO_ITEM]
			-- Find all completed todos.
		do
			Result := find_where ("is_completed = 1")
		ensure
			result_attached: Result /= Void
			all_completed: across Result as ic all ic.is_completed end
		end

	find_by_priority (a_priority: INTEGER): ARRAYED_LIST [TODO_ITEM]
			-- Find all todos with given priority.
		require
			valid_priority: a_priority >= 1 and a_priority <= 5
		do
			Result := find_where ("priority = " + a_priority.out)
		ensure
			result_attached: Result /= Void
			all_have_priority: across Result as ic all ic.priority = a_priority end
		end

	find_overdue: ARRAYED_LIST [TODO_ITEM]
			-- Find all incomplete todos past their due date.
		do
			Result := find_where ("is_completed = 0 AND due_date < date('now') AND due_date IS NOT NULL")
		ensure
			result_attached: Result /= Void
		end

	find_due_today: ARRAYED_LIST [TODO_ITEM]
			-- Find all incomplete todos due today.
		do
			Result := find_where ("is_completed = 0 AND due_date = date('now')")
		ensure
			result_attached: Result /= Void
		end

	find_children (a_parent_id: INTEGER_64): ARRAYED_LIST [TODO_ITEM]
			-- Find all subtasks of a given parent task.
		require
			valid_parent: a_parent_id > 0
		do
			Result := find_where_ordered ("parent_id = " + a_parent_id.out, "priority ASC")
		ensure
			result_attached: Result /= Void
			all_children: across Result as ic all ic.parent_id = a_parent_id end
		end

	find_root_tasks: ARRAYED_LIST [TODO_ITEM]
			-- Find all top-level tasks (no parent).
		do
			Result := find_where_ordered ("parent_id = 0", "priority ASC, due_date ASC")
		ensure
			result_attached: Result /= Void
			all_roots: across Result as ic all ic.parent_id = 0 end
		end

	find_by_status (a_status: READABLE_STRING_8): ARRAYED_LIST [TODO_ITEM]
			-- Find all tasks with given status.
		require
			valid_status: not a_status.is_empty
		do
			Result := find_where_ordered ("status = '" + a_status + "'", "priority ASC, due_date ASC")
		ensure
			result_attached: Result /= Void
		end

	find_by_context (a_context: READABLE_STRING_8): ARRAYED_LIST [TODO_ITEM]
			-- Find all tasks with given context.
		require
			context_not_empty: not a_context.is_empty
		do
			Result := find_where_ordered ("context = '" + a_context + "'", "priority ASC, due_date ASC")
		ensure
			result_attached: Result /= Void
		end

	find_active: ARRAYED_LIST [TODO_ITEM]
			-- Find all active (not completed, not archived) tasks.
		do
			Result := find_where_ordered ("status NOT IN ('completed', 'archived')", "priority ASC, due_date ASC")
		ensure
			result_attached: Result /= Void
		end

	find_in_progress: ARRAYED_LIST [TODO_ITEM]
			-- Find all tasks currently in progress.
		do
			Result := find_where ("status = 'in_progress'")
		ensure
			result_attached: Result /= Void
		end

	find_waiting: ARRAYED_LIST [TODO_ITEM]
			-- Find all tasks in waiting/blocked status.
		do
			Result := find_where ("status = 'waiting'")
		ensure
			result_attached: Result /= Void
		end

feature -- Command: Custom

	mark_completed (a_id: INTEGER_64): BOOLEAN
			-- Mark a todo as completed.
		require
			valid_id: a_id > 0
		local
			l_columns: HASH_TABLE [detachable ANY, STRING_8]
		do
			create l_columns.make (2)
			l_columns.put (1, "is_completed")
			l_columns.put ("datetime('now')", "updated_at")
			Result := update_where (l_columns, "id = " + a_id.out) = 1
		end

	mark_incomplete (a_id: INTEGER_64): BOOLEAN
			-- Mark a todo as incomplete.
		require
			valid_id: a_id > 0
		local
			l_columns: HASH_TABLE [detachable ANY, STRING_8]
		do
			create l_columns.make (2)
			l_columns.put (0, "is_completed")
			l_columns.put ("datetime('now')", "updated_at")
			Result := update_where (l_columns, "id = " + a_id.out) = 1
		end

	delete_completed: INTEGER
			-- Delete all completed todos.
		do
			Result := delete_where ("is_completed = 1")
		ensure
			non_negative: Result >= 0
		end

	set_status (a_id: INTEGER_64; a_status: READABLE_STRING_8): BOOLEAN
			-- Update task status.
		require
			valid_id: a_id > 0
			valid_status: not a_status.is_empty
		local
			l_columns: HASH_TABLE [detachable ANY, STRING_8]
			l_is_completed: INTEGER
		do
			create l_columns.make (3)
			l_columns.put (a_status, "status")
			if a_status.same_string ("completed") then
				l_is_completed := 1
			else
				l_is_completed := 0
			end
			l_columns.put (l_is_completed, "l_is_completed")
			l_columns.put ("datetime('now')", "updated_at")
			Result := update_where (l_columns, "id = " + a_id.out) = 1
		end

	set_parent (a_id: INTEGER_64; a_parent_id: INTEGER_64): BOOLEAN
			-- Set parent task (make subtask).
		require
			valid_id: a_id > 0
			valid_parent: a_parent_id >= 0
			not_self: a_id /= a_parent_id
		local
			l_columns: HASH_TABLE [detachable ANY, STRING_8]
		do
			create l_columns.make (2)
			l_columns.put (a_parent_id, "parent_id")
			l_columns.put ("datetime('now')", "updated_at")
			Result := update_where (l_columns, "id = " + a_id.out) = 1
		end

feature -- Statistics

	incomplete_count: INTEGER
			-- Number of incomplete todos.
		do
			Result := count_where ("is_completed = 0")
		ensure
			non_negative: Result >= 0
		end

	completed_count: INTEGER
			-- Number of completed todos.
		do
			Result := count_where ("is_completed = 1")
		ensure
			non_negative: Result >= 0
		end

	overdue_count: INTEGER
			-- Number of overdue incomplete todos.
		do
			Result := count_where ("is_completed = 0 AND due_date < date('now') AND due_date IS NOT NULL")
		ensure
			non_negative: Result >= 0
		end

feature {NONE} -- Implementation

	row_to_entity (a_row: SIMPLE_SQL_ROW): TODO_ITEM
			-- <Precursor>
		local
			l_id: INTEGER_64
			l_title: STRING_8
			l_description: detachable STRING_8
			l_priority: INTEGER
			l_status: STRING_8
			l_due_date: detachable STRING_8
			l_context: STRING_8
			l_energy_level: INTEGER
			l_estimated_minutes, l_actual_minutes: INTEGER
			l_parent_id: INTEGER_64
			l_created_at, l_updated_at: STRING_8
		do
			l_id := a_row.integer_64_value ("l_id")
			l_title := a_row.string_value ("l_title").to_string_8

			if not a_row.is_null ("l_description") then
				l_description := a_row.string_value ("l_description").to_string_8
			end

			l_priority := a_row.integer_value ("l_priority")

			-- Read status, with fallback for old databases
			if a_row.has_column ("l_status") and then not a_row.is_null ("l_status") then
				l_status := a_row.string_value ("l_status").to_string_8
			else
				-- Legacy: derive from is_completed
				if a_row.integer_value ("is_completed") = 1 then
					l_status := "completed"
				else
					l_status := "pending"
				end
			end

			if not a_row.is_null ("l_due_date") then
				l_due_date := a_row.string_value ("l_due_date").to_string_8
			end

			-- Read new columns with defaults for old databases
			if a_row.has_column ("l_context") and then not a_row.is_null ("l_context") then
				l_context := a_row.string_value ("l_context").to_string_8
			else
				l_context := ""
			end

			if a_row.has_column ("l_energy_level") then
				l_energy_level := a_row.integer_value ("l_energy_level")
				if l_energy_level < 1 or l_energy_level > 3 then
					l_energy_level := 2
				end
			else
				l_energy_level := 2
			end

			if a_row.has_column ("l_estimated_minutes") then
				l_estimated_minutes := a_row.integer_value ("l_estimated_minutes")
			end

			if a_row.has_column ("l_actual_minutes") then
				l_actual_minutes := a_row.integer_value ("l_actual_minutes")
			end

			if a_row.has_column ("l_parent_id") then
				l_parent_id := a_row.integer_64_value ("l_parent_id")
			end

			l_created_at := a_row.string_value ("l_created_at").to_string_8
			l_updated_at := a_row.string_value ("l_updated_at").to_string_8

			create Result.make_full (l_id, l_title, l_description, l_priority, l_status,
				l_due_date, l_context, l_energy_level, l_estimated_minutes, l_actual_minutes,
				l_parent_id, l_created_at, l_updated_at)
		end

	entity_to_columns (a_entity: TODO_ITEM): HASH_TABLE [detachable ANY, STRING_8]
			-- <Precursor>
		do
			create Result.make (12)
			Result.put (a_entity.title, "title")
			Result.put (a_entity.description, "description")
			Result.put (a_entity.priority, "priority")
			if a_entity.is_completed then
				Result.put (1, "is_completed")
			else
				Result.put (0, "is_completed")
			end
			Result.put (a_entity.due_date, "due_date")
			Result.put (a_entity.status, "status")
			Result.put (a_entity.context, "context")
			Result.put (a_entity.energy_level, "energy_level")
			Result.put (a_entity.estimated_minutes, "estimated_minutes")
			Result.put (a_entity.actual_minutes, "actual_minutes")
			Result.put (a_entity.parent_id, "parent_id")
			-- Note: created_at and updated_at are handled by database defaults
		end

	entity_id (a_entity: TODO_ITEM): INTEGER_64
			-- <Precursor>
		do
			Result := a_entity.id
		end

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
