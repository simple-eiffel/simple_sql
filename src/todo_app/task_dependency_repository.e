note
	description: "[
		TASK_DEPENDENCY_REPOSITORY - Repository for task dependencies.

		Manages CPM-style dependencies between tasks:
		- Create/delete dependencies
		- Find predecessors/successors of a task
		- Detect blocked tasks
		- Detect circular dependencies
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TASK_DEPENDENCY_REPOSITORY

create
	make

feature {NONE} -- Initialization

	make (a_db: SIMPLE_SQL_DATABASE)
			-- Initialize with database connection.
		require
			db_attached: a_db /= Void
		do
			db := a_db
		ensure
			db_set: db = a_db
		end

feature -- Access

	db: SIMPLE_SQL_DATABASE
			-- Database connection.

feature -- Table Management

	create_table
			-- Create the task_dependency table if it doesn't exist.
		do
			db.run_sql ("[
				CREATE TABLE IF NOT EXISTS task_dependency (
					id INTEGER PRIMARY KEY AUTOINCREMENT,
					predecessor_id INTEGER NOT NULL,
					successor_id INTEGER NOT NULL,
					dependency_type TEXT DEFAULT 'finish_to_start',
					created_at TEXT DEFAULT (datetime('now')),
					FOREIGN KEY (predecessor_id) REFERENCES todo_item(id) ON DELETE CASCADE,
					FOREIGN KEY (successor_id) REFERENCES todo_item(id) ON DELETE CASCADE,
					UNIQUE(predecessor_id, successor_id)
				)
			]")
			db.run_sql ("CREATE INDEX IF NOT EXISTS idx_dep_predecessor ON task_dependency(predecessor_id)")
			db.run_sql ("CREATE INDEX IF NOT EXISTS idx_dep_successor ON task_dependency(successor_id)")
		end

	drop_table
			-- Drop the task_dependency table.
		do
			db.run_sql ("DROP TABLE IF EXISTS task_dependency")
		end

feature -- CRUD Operations

	insert (a_dep: TASK_DEPENDENCY): INTEGER_64
			-- Insert new dependency and return its ID.
		require
			dep_is_new: a_dep.is_new
			no_self_reference: a_dep.predecessor_id /= a_dep.successor_id
			no_circular: not would_create_cycle (a_dep.predecessor_id, a_dep.successor_id)
		local
			l_sql: STRING_8
		do
			create l_sql.make (200)
			l_sql.append ("INSERT INTO task_dependency (predecessor_id, successor_id, dependency_type) VALUES (")
			l_sql.append_integer_64 (a_dep.predecessor_id)
			l_sql.append (", ")
			l_sql.append_integer_64 (a_dep.successor_id)
			l_sql.append (", '")
			l_sql.append (a_dep.dependency_type)
			l_sql.append ("')")
			db.run_sql (l_sql)
			Result := db.last_insert_id
			a_dep.set_id (Result)
		ensure
			has_id: a_dep.id > 0
		end

	delete (a_id: INTEGER_64): BOOLEAN
			-- Delete dependency by ID. Return True if deleted.
		local
			l_sql: STRING_8
		do
			create l_sql.make (50)
			l_sql.append ("DELETE FROM task_dependency WHERE id = ")
			l_sql.append_integer_64 (a_id)
			db.run_sql (l_sql)
			Result := db.changes > 0
		end

	delete_by_tasks (a_predecessor_id, a_successor_id: INTEGER_64): BOOLEAN
			-- Delete dependency between two specific tasks.
		local
			l_sql: STRING_8
		do
			create l_sql.make (100)
			l_sql.append ("DELETE FROM task_dependency WHERE predecessor_id = ")
			l_sql.append_integer_64 (a_predecessor_id)
			l_sql.append (" AND successor_id = ")
			l_sql.append_integer_64 (a_successor_id)
			db.run_sql (l_sql)
			Result := db.changes > 0
		end

	delete_all_for_task (a_task_id: INTEGER_64): INTEGER
			-- Delete all dependencies involving a task (as predecessor or successor).
			-- Return count of deleted dependencies.
		local
			l_sql: STRING_8
		do
			create l_sql.make (100)
			l_sql.append ("DELETE FROM task_dependency WHERE predecessor_id = ")
			l_sql.append_integer_64 (a_task_id)
			l_sql.append (" OR successor_id = ")
			l_sql.append_integer_64 (a_task_id)
			db.run_sql (l_sql)
			Result := db.changes
		end

feature -- Queries

	find_by_id (a_id: INTEGER_64): detachable TASK_DEPENDENCY
			-- Find dependency by ID.
		local
			l_sql: STRING_8
			l_result: SIMPLE_SQL_RESULT
		do
			create l_sql.make (100)
			l_sql.append ("SELECT id, predecessor_id, successor_id, dependency_type FROM task_dependency WHERE id = ")
			l_sql.append_integer_64 (a_id)
			l_result := db.fetch (l_sql)
			if not l_result.is_empty then
				Result := row_to_dependency (l_result.first)
			end
		end

	find_predecessors (a_task_id: INTEGER_64): ARRAYED_LIST [TASK_DEPENDENCY]
			-- Find all dependencies where given task is the successor.
			-- These are the tasks that must complete before this task.
		local
			l_sql: STRING_8
			l_result: SIMPLE_SQL_RESULT
			i: INTEGER
		do
			create Result.make (5)
			create l_sql.make (150)
			l_sql.append ("SELECT id, predecessor_id, successor_id, dependency_type FROM task_dependency WHERE successor_id = ")
			l_sql.append_integer_64 (a_task_id)
			l_result := db.fetch (l_sql)
			from i := 1 until i > l_result.count loop
				Result.extend (row_to_dependency (l_result [i]))
				i := i + 1
			end
		ensure
			result_attached: Result /= Void
		end

	find_successors (a_task_id: INTEGER_64): ARRAYED_LIST [TASK_DEPENDENCY]
			-- Find all dependencies where given task is the predecessor.
			-- These are the tasks that depend on this task.
		local
			l_sql: STRING_8
			l_result: SIMPLE_SQL_RESULT
			i: INTEGER
		do
			create Result.make (5)
			create l_sql.make (150)
			l_sql.append ("SELECT id, predecessor_id, successor_id, dependency_type FROM task_dependency WHERE predecessor_id = ")
			l_sql.append_integer_64 (a_task_id)
			l_result := db.fetch (l_sql)
			from i := 1 until i > l_result.count loop
				Result.extend (row_to_dependency (l_result [i]))
				i := i + 1
			end
		ensure
			result_attached: Result /= Void
		end

	find_all: ARRAYED_LIST [TASK_DEPENDENCY]
			-- Get all dependencies.
		local
			l_result: SIMPLE_SQL_RESULT
			i: INTEGER
		do
			create Result.make (20)
			l_result := db.fetch ("SELECT id, predecessor_id, successor_id, dependency_type FROM task_dependency")
			from i := 1 until i > l_result.count loop
				Result.extend (row_to_dependency (l_result [i]))
				i := i + 1
			end
		ensure
			result_attached: Result /= Void
		end

	predecessor_ids (a_task_id: INTEGER_64): ARRAYED_LIST [INTEGER_64]
			-- Get IDs of all predecessor tasks.
		local
			l_deps: ARRAYED_LIST [TASK_DEPENDENCY]
		do
			create Result.make (5)
			l_deps := find_predecessors (a_task_id)
			across l_deps as dep loop
				Result.extend (dep.predecessor_id)
			end
		ensure
			result_attached: Result /= Void
		end

	successor_ids (a_task_id: INTEGER_64): ARRAYED_LIST [INTEGER_64]
			-- Get IDs of all successor tasks.
		local
			l_deps: ARRAYED_LIST [TASK_DEPENDENCY]
		do
			create Result.make (5)
			l_deps := find_successors (a_task_id)
			across l_deps as dep loop
				Result.extend (dep.successor_id)
			end
		ensure
			result_attached: Result /= Void
		end

feature -- Blocking Status

	is_blocked (a_task_id: INTEGER_64; a_todo_repo: TODO_REPOSITORY): BOOLEAN
			-- Is the task blocked by incomplete predecessors?
			-- For finish-to-start: predecessor must be completed.
		local
			l_deps: ARRAYED_LIST [TASK_DEPENDENCY]
			l_pred: detachable TODO_ITEM
		do
			l_deps := find_predecessors (a_task_id)
			across l_deps as dep loop
				if dep.is_finish_to_start then
					l_pred := a_todo_repo.find_by_id (dep.predecessor_id)
					if attached l_pred and then not l_pred.is_completed then
						Result := True
					end
				end
			end
		end

	blocking_tasks (a_task_id: INTEGER_64; a_todo_repo: TODO_REPOSITORY): ARRAYED_LIST [TODO_ITEM]
			-- Get list of incomplete predecessor tasks that are blocking this task.
		local
			l_deps: ARRAYED_LIST [TASK_DEPENDENCY]
			l_pred: detachable TODO_ITEM
		do
			create Result.make (3)
			l_deps := find_predecessors (a_task_id)
			across l_deps as dep loop
				if dep.is_finish_to_start then
					l_pred := a_todo_repo.find_by_id (dep.predecessor_id)
					if attached l_pred and then not l_pred.is_completed then
						Result.extend (l_pred)
					end
				end
			end
		ensure
			result_attached: Result /= Void
		end

	blocked_by_task (a_task_id: INTEGER_64; a_todo_repo: TODO_REPOSITORY): ARRAYED_LIST [TODO_ITEM]
			-- Get list of tasks that are waiting on this task to complete.
		local
			l_deps: ARRAYED_LIST [TASK_DEPENDENCY]
			l_succ: detachable TODO_ITEM
		do
			create Result.make (3)
			l_deps := find_successors (a_task_id)
			across l_deps as dep loop
				if dep.is_finish_to_start then
					l_succ := a_todo_repo.find_by_id (dep.successor_id)
					if attached l_succ and then not l_succ.is_completed then
						Result.extend (l_succ)
					end
				end
			end
		ensure
			result_attached: Result /= Void
		end

feature -- Cycle Detection

	would_create_cycle (a_predecessor_id, a_successor_id: INTEGER_64): BOOLEAN
			-- Would adding this dependency create a circular reference?
			-- Check if successor can reach predecessor through existing dependencies.
		local
			l_visited: ARRAYED_SET [INTEGER_64]
		do
			create l_visited.make (10)
			Result := can_reach (a_successor_id, a_predecessor_id, l_visited)
		end

feature {NONE} -- Implementation

	row_to_dependency (a_row: SIMPLE_SQL_ROW): TASK_DEPENDENCY
			-- Convert database row to TASK_DEPENDENCY.
		do
			create Result.make (
				a_row.integer_64_value ("id"),
				a_row.integer_64_value ("predecessor_id"),
				a_row.integer_64_value ("successor_id"),
				a_row.string_value ("dependency_type")
			)
		end

	can_reach (a_from_id, a_to_id: INTEGER_64; a_visited: ARRAYED_SET [INTEGER_64]): BOOLEAN
			-- Can we reach a_to_id starting from a_from_id following successor links?
			-- Used for cycle detection (DFS).
		local
			l_successors: ARRAYED_LIST [INTEGER_64]
		do
			if a_from_id = a_to_id then
				Result := True
			elseif not a_visited.has (a_from_id) then
				a_visited.extend (a_from_id)
				l_successors := successor_ids (a_from_id)
				across l_successors as succ loop
					if can_reach (succ, a_to_id, a_visited) then
						Result := True
					end
				end
			end
		end

feature -- Statistics

	count: INTEGER
			-- Total number of dependencies.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := db.fetch ("SELECT COUNT(*) as cnt FROM task_dependency")
			if not l_result.is_empty then
				Result := l_result.first.integer_value ("cnt")
			end
		end

	has_dependency (a_predecessor_id, a_successor_id: INTEGER_64): BOOLEAN
			-- Does a dependency exist between these two tasks?
		local
			l_sql: STRING_8
			l_result: SIMPLE_SQL_RESULT
		do
			create l_sql.make (100)
			l_sql.append ("SELECT 1 FROM task_dependency WHERE predecessor_id = ")
			l_sql.append_integer_64 (a_predecessor_id)
			l_sql.append (" AND successor_id = ")
			l_sql.append_integer_64 (a_successor_id)
			l_result := db.fetch (l_sql)
			Result := not l_result.is_empty
		end

invariant
	db_attached: db /= Void

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
