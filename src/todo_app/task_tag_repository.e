note
	description: "[
		TASK_TAG_REPOSITORY - Repository for task tags.

		Manages many-to-many relationship between tasks and tags.
		Tags are simple strings for flexible categorization.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TASK_TAG_REPOSITORY

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
			-- Create the task_tag table if it doesn't exist.
		do
			db.run_sql ("[
				CREATE TABLE IF NOT EXISTS task_tag (
					task_id INTEGER NOT NULL,
					tag TEXT NOT NULL,
					created_at TEXT DEFAULT (datetime('now')),
					PRIMARY KEY (task_id, tag),
					FOREIGN KEY (task_id) REFERENCES todo_item(id) ON DELETE CASCADE
				)
			]")
			db.run_sql ("CREATE INDEX IF NOT EXISTS idx_tag_name ON task_tag(tag)")
		end

	drop_table
			-- Drop the task_tag table.
		do
			db.run_sql ("DROP TABLE IF EXISTS task_tag")
		end

feature -- Tag Operations

	add_tag (a_task_id: INTEGER_64; a_tag: READABLE_STRING_8): BOOLEAN
			-- Add a tag to a task. Return True if added (not duplicate).
		require
			valid_task: a_task_id > 0
			tag_not_empty: not a_tag.is_empty
		local
			l_sql: STRING_8
		do
			create l_sql.make (100)
			l_sql.append ("INSERT OR IGNORE INTO task_tag (task_id, tag) VALUES (")
			l_sql.append_integer_64 (a_task_id)
			l_sql.append (", '")
			l_sql.append (escape_sql (a_tag))
			l_sql.append ("')")
			db.run_sql (l_sql)
			Result := db.changes > 0
		end

	remove_tag (a_task_id: INTEGER_64; a_tag: READABLE_STRING_8): BOOLEAN
			-- Remove a tag from a task. Return True if removed.
		require
			valid_task: a_task_id > 0
			tag_not_empty: not a_tag.is_empty
		local
			l_sql: STRING_8
		do
			create l_sql.make (100)
			l_sql.append ("DELETE FROM task_tag WHERE task_id = ")
			l_sql.append_integer_64 (a_task_id)
			l_sql.append (" AND tag = '")
			l_sql.append (escape_sql (a_tag))
			l_sql.append ("'")
			db.run_sql (l_sql)
			Result := db.changes > 0
		end

	remove_all_tags (a_task_id: INTEGER_64): INTEGER
			-- Remove all tags from a task. Return count removed.
		require
			valid_task: a_task_id > 0
		local
			l_sql: STRING_8
		do
			create l_sql.make (50)
			l_sql.append ("DELETE FROM task_tag WHERE task_id = ")
			l_sql.append_integer_64 (a_task_id)
			db.run_sql (l_sql)
			Result := db.changes
		end

	set_tags (a_task_id: INTEGER_64; a_tags: LIST [READABLE_STRING_8])
			-- Replace all tags for a task with new list.
		require
			valid_task: a_task_id > 0
			tags_attached: a_tags /= Void
		do
			remove_all_tags (a_task_id)
			across a_tags as tag loop
				if not tag.is_empty then
					add_tag (a_task_id, tag)
				end
			end
		end

feature -- Queries

	tags_for_task (a_task_id: INTEGER_64): ARRAYED_LIST [STRING_8]
			-- Get all tags for a task.
		require
			valid_task: a_task_id > 0
		local
			l_sql: STRING_8
			l_result: SIMPLE_SQL_RESULT
			i: INTEGER
		do
			create Result.make (5)
			create l_sql.make (80)
			l_sql.append ("SELECT tag FROM task_tag WHERE task_id = ")
			l_sql.append_integer_64 (a_task_id)
			l_sql.append (" ORDER BY tag")
			l_result := db.fetch (l_sql)
			from i := 1 until i > l_result.count loop
				Result.extend (l_result [i].string_value ("tag"))
				i := i + 1
			end
		ensure
			result_attached: Result /= Void
		end

	tasks_with_tag (a_tag: READABLE_STRING_8): ARRAYED_LIST [INTEGER_64]
			-- Get IDs of all tasks with given tag.
		require
			tag_not_empty: not a_tag.is_empty
		local
			l_sql: STRING_8
			l_result: SIMPLE_SQL_RESULT
			i: INTEGER
		do
			create Result.make (10)
			create l_sql.make (80)
			l_sql.append ("SELECT task_id FROM task_tag WHERE tag = '")
			l_sql.append (escape_sql (a_tag))
			l_sql.append ("' ORDER BY task_id")
			l_result := db.fetch (l_sql)
			from i := 1 until i > l_result.count loop
				Result.extend (l_result [i].integer_64_value ("task_id"))
				i := i + 1
			end
		ensure
			result_attached: Result /= Void
		end

	tasks_with_any_tag (a_tags: LIST [READABLE_STRING_8]): ARRAYED_LIST [INTEGER_64]
			-- Get IDs of tasks with any of the given tags.
		require
			tags_attached: a_tags /= Void
			tags_not_empty: not a_tags.is_empty
		local
			l_sql: STRING_8
			l_result: SIMPLE_SQL_RESULT
			l_first: BOOLEAN
			i: INTEGER
		do
			create Result.make (10)
			create l_sql.make (200)
			l_sql.append ("SELECT DISTINCT task_id FROM task_tag WHERE tag IN (")
			l_first := True
			across a_tags as tag loop
				if not tag.is_empty then
					if not l_first then
						l_sql.append (", ")
					end
					l_sql.append ("'")
					l_sql.append (escape_sql (tag))
					l_sql.append ("'")
					l_first := False
				end
			end
			l_sql.append (") ORDER BY task_id")
			l_result := db.fetch (l_sql)
			from i := 1 until i > l_result.count loop
				Result.extend (l_result [i].integer_64_value ("task_id"))
				i := i + 1
			end
		ensure
			result_attached: Result /= Void
		end

	tasks_with_all_tags (a_tags: LIST [READABLE_STRING_8]): ARRAYED_LIST [INTEGER_64]
			-- Get IDs of tasks that have ALL of the given tags.
		require
			tags_attached: a_tags /= Void
			tags_not_empty: not a_tags.is_empty
		local
			l_sql: STRING_8
			l_result: SIMPLE_SQL_RESULT
			l_first: BOOLEAN
			l_tag_count: INTEGER
			i: INTEGER
		do
			create Result.make (10)
			create l_sql.make (300)
			l_sql.append ("SELECT task_id FROM task_tag WHERE tag IN (")
			l_first := True
			l_tag_count := 0
			across a_tags as tag loop
				if not tag.is_empty then
					if not l_first then
						l_sql.append (", ")
					end
					l_sql.append ("'")
					l_sql.append (escape_sql (tag))
					l_sql.append ("'")
					l_first := False
					l_tag_count := l_tag_count + 1
				end
			end
			l_sql.append (") GROUP BY task_id HAVING COUNT(DISTINCT tag) = ")
			l_sql.append_integer (l_tag_count)
			l_result := db.fetch (l_sql)
			from i := 1 until i > l_result.count loop
				Result.extend (l_result [i].integer_64_value ("task_id"))
				i := i + 1
			end
		ensure
			result_attached: Result /= Void
		end

	all_tags: ARRAYED_LIST [STRING_8]
			-- Get all unique tags in use.
		local
			l_result: SIMPLE_SQL_RESULT
			i: INTEGER
		do
			create Result.make (20)
			l_result := db.fetch ("SELECT DISTINCT tag FROM task_tag ORDER BY tag")
			from i := 1 until i > l_result.count loop
				Result.extend (l_result [i].string_value ("tag"))
				i := i + 1
			end
		ensure
			result_attached: Result /= Void
		end

	has_tag (a_task_id: INTEGER_64; a_tag: READABLE_STRING_8): BOOLEAN
			-- Does the task have this tag?
		require
			valid_task: a_task_id > 0
			tag_not_empty: not a_tag.is_empty
		local
			l_sql: STRING_8
			l_result: SIMPLE_SQL_RESULT
		do
			create l_sql.make (100)
			l_sql.append ("SELECT 1 FROM task_tag WHERE task_id = ")
			l_sql.append_integer_64 (a_task_id)
			l_sql.append (" AND tag = '")
			l_sql.append (escape_sql (a_tag))
			l_sql.append ("'")
			l_result := db.fetch (l_sql)
			Result := not l_result.is_empty
		end

feature -- Statistics

	tag_count (a_task_id: INTEGER_64): INTEGER
			-- Number of tags for a task.
		require
			valid_task: a_task_id > 0
		local
			l_sql: STRING_8
			l_result: SIMPLE_SQL_RESULT
		do
			create l_sql.make (80)
			l_sql.append ("SELECT COUNT(*) as cnt FROM task_tag WHERE task_id = ")
			l_sql.append_integer_64 (a_task_id)
			l_result := db.fetch (l_sql)
			if not l_result.is_empty then
				Result := l_result.first.integer_value ("cnt")
			end
		end

	usage_count (a_tag: READABLE_STRING_8): INTEGER
			-- Number of tasks using this tag.
		require
			tag_not_empty: not a_tag.is_empty
		local
			l_sql: STRING_8
			l_result: SIMPLE_SQL_RESULT
		do
			create l_sql.make (80)
			l_sql.append ("SELECT COUNT(*) as cnt FROM task_tag WHERE tag = '")
			l_sql.append (escape_sql (a_tag))
			l_sql.append ("'")
			l_result := db.fetch (l_sql)
			if not l_result.is_empty then
				Result := l_result.first.integer_value ("cnt")
			end
		end

	total_count: INTEGER
			-- Total number of task-tag associations.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := db.fetch ("SELECT COUNT(*) as cnt FROM task_tag")
			if not l_result.is_empty then
				Result := l_result.first.integer_value ("cnt")
			end
		end

feature {NONE} -- Implementation

	escape_sql (a_str: READABLE_STRING_8): STRING_8
			-- Escape single quotes for SQL.
		do
			create Result.make_from_string (a_str)
			Result.replace_substring_all ("'", "''")
		end

invariant
	db_attached: db /= Void

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
