note
	description: "CPM (Critical Path Method) application facade demonstrating SIMPLE_SQL usage"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	CPM_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize CPM application with in-memory database.
		do
			create database.make_memory
			create_schema
		end

feature -- Access

	database: SIMPLE_SQL_DATABASE
			-- The underlying database connection.

feature -- Project Management

	create_project (a_name: READABLE_STRING_8): CPM_PROJECT
			-- Create a new project and return it.
		require
			name_not_empty: not a_name.is_empty
		local
			l_project: CPM_PROJECT
			l_result: SIMPLE_SQL_RESULT
		do
			create l_project.make_new (a_name)
			database.execute_with_args ("INSERT INTO projects (name, calculated_duration) VALUES (?, 0)", <<a_name>>)
			l_project.set_id (database.last_insert_rowid)
			l_result := database.query_with_args ("SELECT created_at, updated_at FROM projects WHERE id = ?", <<l_project.id>>)
			if not l_result.is_empty then
				l_project.set_timestamps (
					l_result.first.string_value ("created_at").to_string_8,
					l_result.first.string_value ("updated_at").to_string_8
				)
			end
			Result := l_project
		ensure
			result_saved: not Result.is_new
			name_matches: Result.name.same_string (a_name)
		end

	find_project (a_id: INTEGER_64): detachable CPM_PROJECT
			-- Find project by ID or Void if not found.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args ("SELECT * FROM projects WHERE id = ?", <<a_id>>)
			if not l_result.is_empty then
				Result := row_to_project (l_result.first)
			end
		end

	all_projects: ARRAYED_LIST [CPM_PROJECT]
			-- Get all projects ordered by name.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (10)
			l_result := database.query ("SELECT * FROM projects ORDER BY name")
			across l_result.rows as ic loop
				Result.extend (row_to_project (ic))
			end
		end

	delete_project (a_project_id: INTEGER_64): BOOLEAN
			-- Delete a project and all its activities/dependencies.
		do
			database.execute_with_args ("DELETE FROM dependencies WHERE predecessor_id IN (SELECT id FROM activities WHERE project_id = ?)", <<a_project_id>>)
			database.execute_with_args ("DELETE FROM dependencies WHERE successor_id IN (SELECT id FROM activities WHERE project_id = ?)", <<a_project_id>>)
			database.execute_with_args ("DELETE FROM activities WHERE project_id = ?", <<a_project_id>>)
			database.execute_with_args ("DELETE FROM projects WHERE id = ?", <<a_project_id>>)
			Result := database.changes_count > 0
		end

feature -- Activity Management

	add_activity (a_project_id: INTEGER_64; a_code, a_name: READABLE_STRING_8; a_duration: INTEGER): CPM_ACTIVITY
			-- Add a new activity to a project.
		require
			valid_project: a_project_id > 0
			code_not_empty: not a_code.is_empty
			name_not_empty: not a_name.is_empty
			duration_non_negative: a_duration >= 0
		local
			l_activity: CPM_ACTIVITY
		do
			create l_activity.make_new (a_code, a_name, a_duration, a_project_id)
			database.execute_with_args ("INSERT INTO activities (code, name, duration, project_id, early_start, early_finish, late_start, late_finish, float, is_critical) VALUES (?, ?, ?, ?, 0, 0, 0, 0, 0, 0)", <<a_code, a_name, a_duration, a_project_id>>)
			l_activity.set_id (database.last_insert_rowid)
			Result := l_activity
		ensure
			result_saved: not Result.is_new
			code_matches: Result.code.same_string (a_code)
			name_matches: Result.name.same_string (a_name)
		end

	add_activity_with_description (a_project_id: INTEGER_64; a_code, a_name: READABLE_STRING_8;
			a_description: detachable READABLE_STRING_8; a_duration: INTEGER): CPM_ACTIVITY
			-- Add a new activity with optional description.
		require
			valid_project: a_project_id > 0
			code_not_empty: not a_code.is_empty
			name_not_empty: not a_name.is_empty
			duration_non_negative: a_duration >= 0
		local
			l_activity: CPM_ACTIVITY
		do
			create l_activity.make_new (a_code, a_name, a_duration, a_project_id)
			if attached a_description then
				l_activity.set_description (a_description)
			end
			database.execute_with_args ("INSERT INTO activities (code, name, description, duration, project_id, early_start, early_finish, late_start, late_finish, float, is_critical) VALUES (?, ?, ?, ?, ?, 0, 0, 0, 0, 0, 0)", <<a_code, a_name, a_description, a_duration, a_project_id>>)
			l_activity.set_id (database.last_insert_rowid)
			Result := l_activity
		ensure
			result_saved: not Result.is_new
		end

	find_activity (a_id: INTEGER_64): detachable CPM_ACTIVITY
			-- Find activity by ID.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args ("SELECT * FROM activities WHERE id = ?", <<a_id>>)
			if not l_result.is_empty then
				Result := row_to_activity (l_result.first)
			end
		end

	find_activity_by_code (a_project_id: INTEGER_64; a_code: READABLE_STRING_8): detachable CPM_ACTIVITY
			-- Find activity by code within a project.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args ("SELECT * FROM activities WHERE project_id = ? AND code = ?", <<a_project_id, a_code>>)
			if not l_result.is_empty then
				Result := row_to_activity (l_result.first)
			end
		end

	project_activities (a_project_id: INTEGER_64): ARRAYED_LIST [CPM_ACTIVITY]
			-- Get all activities for a project ordered by code.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (20)
			l_result := database.query_with_args ("SELECT * FROM activities WHERE project_id = ? ORDER BY code", <<a_project_id>>)
			across l_result.rows as ic loop
				Result.extend (row_to_activity (ic))
			end
		end

	critical_path_activities (a_project_id: INTEGER_64): ARRAYED_LIST [CPM_ACTIVITY]
			-- Get only critical path activities for a project.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (10)
			l_result := database.query_with_args ("SELECT * FROM activities WHERE project_id = ? AND is_critical = 1 ORDER BY early_start", <<a_project_id>>)
			across l_result.rows as ic loop
				Result.extend (row_to_activity (ic))
			end
		end

	activity_count (a_project_id: INTEGER_64): INTEGER
			-- Count of activities in a project.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args ("SELECT COUNT(*) as cnt FROM activities WHERE project_id = ?", <<a_project_id>>)
			if not l_result.is_empty then
				Result := l_result.first.integer_value ("cnt")
			end
		end

feature -- Dependency Management

	add_dependency (a_predecessor_id, a_successor_id: INTEGER_64): CPM_DEPENDENCY
			-- Add a Finish-to-Start dependency between two activities.
		require
			valid_predecessor: a_predecessor_id > 0
			valid_successor: a_successor_id > 0
			different: a_predecessor_id /= a_successor_id
		local
			l_dep: CPM_DEPENDENCY
		do
			create l_dep.make_new (a_predecessor_id, a_successor_id)
			database.execute_with_args ("INSERT INTO dependencies (predecessor_id, successor_id, dependency_type, lag) VALUES (?, ?, 'FS', 0)", <<a_predecessor_id, a_successor_id>>)
			l_dep.set_id (database.last_insert_rowid)
			Result := l_dep
		ensure
			result_saved: not Result.is_new
		end

	add_dependency_with_lag (a_predecessor_id, a_successor_id: INTEGER_64;
			a_type: READABLE_STRING_8; a_lag: INTEGER): CPM_DEPENDENCY
			-- Add a dependency with specific type and lag.
		require
			valid_predecessor: a_predecessor_id > 0
			valid_successor: a_successor_id > 0
			different: a_predecessor_id /= a_successor_id
		local
			l_dep: CPM_DEPENDENCY
		do
			create l_dep.make (0, a_predecessor_id, a_successor_id, a_type, a_lag)
			database.execute_with_args ("INSERT INTO dependencies (predecessor_id, successor_id, dependency_type, lag) VALUES (?, ?, ?, ?)", <<a_predecessor_id, a_successor_id, a_type, a_lag>>)
			l_dep.set_id (database.last_insert_rowid)
			Result := l_dep
		ensure
			result_saved: not Result.is_new
		end

	predecessors (a_activity_id: INTEGER_64): ARRAYED_LIST [CPM_ACTIVITY]
			-- Get all predecessor activities for an activity.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (5)
			l_result := database.query_with_args ("SELECT a.* FROM activities a INNER JOIN dependencies d ON a.id = d.predecessor_id WHERE d.successor_id = ?", <<a_activity_id>>)
			across l_result.rows as ic loop
				Result.extend (row_to_activity (ic))
			end
		end

	successors (a_activity_id: INTEGER_64): ARRAYED_LIST [CPM_ACTIVITY]
			-- Get all successor activities for an activity.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (5)
			l_result := database.query_with_args ("SELECT a.* FROM activities a INNER JOIN dependencies d ON a.id = d.successor_id WHERE d.predecessor_id = ?", <<a_activity_id>>)
			across l_result.rows as ic loop
				Result.extend (row_to_activity (ic))
			end
		end

	dependency_count (a_project_id: INTEGER_64): INTEGER
			-- Count of dependencies in a project.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args ("SELECT COUNT(*) as cnt FROM dependencies d INNER JOIN activities a ON d.predecessor_id = a.id WHERE a.project_id = ?", <<a_project_id>>)
			if not l_result.is_empty then
				Result := l_result.first.integer_value ("cnt")
			end
		end

	successor_ids (a_activity_id: INTEGER_64): ARRAYED_LIST [INTEGER_64]
			-- Get IDs of all successor activities.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (5)
			l_result := database.query_with_args ("SELECT successor_id FROM dependencies WHERE predecessor_id = ?", <<a_activity_id>>)
			across l_result.rows as ic loop
				Result.extend (ic.integer_64_value ("successor_id"))
			end
		end

	predecessor_ids (a_activity_id: INTEGER_64): ARRAYED_LIST [INTEGER_64]
			-- Get IDs of all predecessor activities.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (5)
			l_result := database.query_with_args ("SELECT predecessor_id FROM dependencies WHERE successor_id = ?", <<a_activity_id>>)
			across l_result.rows as ic loop
				Result.extend (ic.integer_64_value ("predecessor_id"))
			end
		end

feature -- CPM Calculation

	calculate_cpm (a_project_id: INTEGER_64)
			-- Calculate CPM schedule for a project (forward and backward pass).
		local
			l_activities: ARRAYED_LIST [CPM_ACTIVITY]
			l_sorted: ARRAYED_LIST [CPM_ACTIVITY]
			l_project_duration: INTEGER
		do
			l_activities := project_activities (a_project_id)
			if l_activities.is_empty then
				-- Nothing to calculate
			else
				-- Topological sort for forward pass
				l_sorted := topological_sort (l_activities)

				-- Forward pass: calculate ES and EF
				forward_pass (l_sorted)

				-- Get project duration (max EF)
				l_project_duration := max_early_finish (l_sorted)

				-- Backward pass: calculate LS, LF, and float
				backward_pass (l_sorted, l_project_duration)

				-- Mark critical activities and update database
				across l_sorted as ic loop
					ic.set_schedule (
						ic.early_start,
						ic.early_finish,
						ic.late_start,
						ic.late_finish,
						ic.late_start - ic.early_start,
						ic.late_start - ic.early_start = 0
					)
					update_activity_schedule (ic)
				end

				-- Update project duration
				database.execute_with_args ("UPDATE projects SET calculated_duration = ?, updated_at = datetime('now') WHERE id = ?", <<l_project_duration, a_project_id>>)
			end
		end

	project_duration (a_project_id: INTEGER_64): INTEGER
			-- Get calculated project duration.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args ("SELECT calculated_duration FROM projects WHERE id = ?", <<a_project_id>>)
			if not l_result.is_empty then
				Result := l_result.first.integer_value ("calculated_duration")
			end
		end

	critical_path_length (a_project_id: INTEGER_64): INTEGER
			-- Number of activities on critical path.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args ("SELECT COUNT(*) as cnt FROM activities WHERE project_id = ? AND is_critical = 1", <<a_project_id>>)
			if not l_result.is_empty then
				Result := l_result.first.integer_value ("cnt")
			end
		end

feature -- Statistics

	total_float (a_project_id: INTEGER_64): INTEGER
			-- Sum of all float in the project.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args ("SELECT COALESCE(SUM(float), 0) as total FROM activities WHERE project_id = ?", <<a_project_id>>)
			if not l_result.is_empty then
				Result := l_result.first.integer_value ("total")
			end
		end

	average_float (a_project_id: INTEGER_64): REAL_64
			-- Average float per activity.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args ("SELECT AVG(float) as avg_float FROM activities WHERE project_id = ?", <<a_project_id>>)
			if not l_result.is_empty then
				Result := l_result.first.real_value ("avg_float")
			end
		end

feature -- Cleanup

	close
			-- Close the database connection.
		do
			database.close
		end

feature {NONE} -- Implementation: Schema

	create_schema
			-- Create the database schema.
		do
			database.execute ("CREATE TABLE IF NOT EXISTS projects (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, description TEXT, start_date TEXT, calculated_duration INTEGER DEFAULT 0, created_at TEXT DEFAULT (datetime('now')), updated_at TEXT DEFAULT (datetime('now')))")
			database.execute ("CREATE TABLE IF NOT EXISTS activities (id INTEGER PRIMARY KEY AUTOINCREMENT, code TEXT NOT NULL, name TEXT NOT NULL, description TEXT, duration INTEGER NOT NULL DEFAULT 0, early_start INTEGER DEFAULT 0, early_finish INTEGER DEFAULT 0, late_start INTEGER DEFAULT 0, late_finish INTEGER DEFAULT 0, float INTEGER DEFAULT 0, is_critical INTEGER DEFAULT 0, project_id INTEGER NOT NULL, FOREIGN KEY (project_id) REFERENCES projects(id))")
			database.execute ("CREATE TABLE IF NOT EXISTS dependencies (id INTEGER PRIMARY KEY AUTOINCREMENT, predecessor_id INTEGER NOT NULL, successor_id INTEGER NOT NULL, dependency_type TEXT DEFAULT 'FS', lag INTEGER DEFAULT 0, FOREIGN KEY (predecessor_id) REFERENCES activities(id), FOREIGN KEY (successor_id) REFERENCES activities(id))")
			database.execute ("CREATE INDEX IF NOT EXISTS idx_activities_project ON activities(project_id)")
			database.execute ("CREATE INDEX IF NOT EXISTS idx_activities_critical ON activities(project_id, is_critical)")
			database.execute ("CREATE INDEX IF NOT EXISTS idx_dependencies_pred ON dependencies(predecessor_id)")
			database.execute ("CREATE INDEX IF NOT EXISTS idx_dependencies_succ ON dependencies(successor_id)")
		end

feature {NONE} -- Implementation: Row Mapping

	row_to_project (a_row: SIMPLE_SQL_ROW): CPM_PROJECT
			-- Convert result row to CPM_PROJECT.
		do
			create Result.make (
				a_row.integer_64_value ("id"),
				a_row.string_value ("name").to_string_8,
				string_or_void (a_row, "description"),
				string_or_void (a_row, "start_date"),
				a_row.integer_value ("calculated_duration"),
				a_row.string_value ("created_at").to_string_8,
				a_row.string_value ("updated_at").to_string_8
			)
		end

	row_to_activity (a_row: SIMPLE_SQL_ROW): CPM_ACTIVITY
			-- Convert result row to CPM_ACTIVITY.
		do
			create Result.make (
				a_row.integer_64_value ("id"),
				a_row.string_value ("code").to_string_8,
				a_row.string_value ("name").to_string_8,
				string_or_void (a_row, "description"),
				a_row.integer_value ("duration"),
				a_row.integer_value ("early_start"),
				a_row.integer_value ("early_finish"),
				a_row.integer_value ("late_start"),
				a_row.integer_value ("late_finish"),
				a_row.integer_value ("float"),
				a_row.integer_value ("is_critical") = 1,
				a_row.integer_64_value ("project_id")
			)
		end

	string_or_void (a_row: SIMPLE_SQL_ROW; a_column: STRING_8): detachable STRING_8
			-- Get string value or Void if null.
		do
			if not a_row.is_null (a_column) then
				Result := a_row.string_value (a_column).to_string_8
			end
		end

feature {NONE} -- Implementation: CPM Algorithm

	topological_sort (a_activities: ARRAYED_LIST [CPM_ACTIVITY]): ARRAYED_LIST [CPM_ACTIVITY]
			-- Sort activities in topological order (predecessors before successors).
		local
			l_in_degree: HASH_TABLE [INTEGER, INTEGER_64]
			l_queue: ARRAYED_QUEUE [CPM_ACTIVITY]
			l_activity: CPM_ACTIVITY
			l_succs: ARRAYED_LIST [CPM_ACTIVITY]
			l_deg: INTEGER
		do
			create Result.make (a_activities.count)
			create l_in_degree.make (a_activities.count)
			create l_queue.make (a_activities.count)

			-- Calculate in-degree for each activity
			across a_activities as ic loop
				l_in_degree.put (predecessors (ic.id).count, ic.id)
			end

			-- Start with activities that have no predecessors
			across a_activities as ic loop
				if attached l_in_degree.item (ic.id) as deg and then deg = 0 then
					l_queue.extend (ic)
				end
			end

			-- Process queue
			from until l_queue.is_empty loop
				l_activity := l_queue.item
				l_queue.remove
				Result.extend (l_activity)

				-- Reduce in-degree of successors
				l_succs := successors (l_activity.id)
				across l_succs as succ loop
					if attached l_in_degree.item (succ.id) as al_deg then
						l_deg := deg - 1
						l_in_degree.force (l_deg, succ.id)
						if l_deg = 0 then
							-- Find the activity object
							across a_activities as act loop
								if act.id = succ.id then
									l_queue.extend (act)
								end
							end
						end
					end
				end
			end
		end

	forward_pass (a_sorted: ARRAYED_LIST [CPM_ACTIVITY])
			-- Forward pass: calculate Early Start and Early Finish.
			-- ES = max(EF of all predecessors + lag)
			-- EF = ES + duration
			-- Note: Uses activity_map to look up in-memory predecessors with updated values
		local
			l_pred_ids: ARRAYED_LIST [INTEGER_64]
			l_activity_map: HASH_TABLE [CPM_ACTIVITY, INTEGER_64]
			l_max_ef: INTEGER
			l_lag: INTEGER
		do
			-- Build lookup table for in-memory activities
			create l_activity_map.make (a_sorted.count)
			across a_sorted as ic loop
				l_activity_map.put (ic, ic.id)
			end

			across a_sorted as ic loop
				l_pred_ids := predecessor_ids (ic.id)
				if l_pred_ids.is_empty then
					ic.set_schedule (0, ic.duration, 0, 0, 0, False)
				else
					l_max_ef := 0
					across l_pred_ids as pred_id loop
						if attached l_activity_map.item (pred_id) as al_l_pred then
							l_lag := get_lag (pred_id, ic.id)
							l_max_ef := l_max_ef.max (al_l_pred.early_finish + l_lag)
						end
					end
					ic.set_schedule (l_max_ef, l_max_ef + ic.duration, 0, 0, 0, False)
				end
			end
		end

	backward_pass (a_sorted: ARRAYED_LIST [CPM_ACTIVITY]; a_project_duration: INTEGER)
			-- Backward pass: calculate Late Start and Late Finish.
			-- LF = min(LS of all successors) - lag
			-- LS = LF - duration
			-- Note: Uses activity_map to look up in-memory successors with updated values
		local
			l_succ_ids: ARRAYED_LIST [INTEGER_64]
			l_activity_map: HASH_TABLE [CPM_ACTIVITY, INTEGER_64]
			l_min_lf: INTEGER
			l_ls, l_lf: INTEGER
			i: INTEGER
			l_lag: INTEGER
		do
			-- Build lookup table for in-memory activities
			create l_activity_map.make (a_sorted.count)
			across a_sorted as ic loop
				l_activity_map.put (ic, ic.id)
			end

			from i := a_sorted.count until i < 1 loop
				if attached a_sorted.i_th (i) as al_l_activity then
					l_succ_ids := successor_ids (al_l_activity.id)
					if l_succ_ids.is_empty then
						-- End activity: LF = project duration
						l_lf := a_project_duration
						l_ls := l_lf - al_l_activity.duration
					else
						-- LF = min(LS of successors - lag)
						l_min_lf := {INTEGER}.max_value
						across l_succ_ids as succ_id loop
							if attached l_activity_map.item (succ_id) as al_l_succ then
								l_lag := get_lag (al_l_activity.id, succ_id)
								l_min_lf := l_min_lf.min (l_succ.late_start - l_lag)
							end
						end
						l_lf := l_min_lf
						l_ls := l_lf - l_activity.duration
					end
					l_activity.set_schedule (l_activity.early_start, l_activity.early_finish, l_ls, l_lf, 0, False)
				end
				i := i - 1
			end
		end

	get_lag (a_predecessor_id, a_successor_id: INTEGER_64): INTEGER
			-- Get lag between two activities.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args ("SELECT lag FROM dependencies WHERE predecessor_id = ? AND successor_id = ?", <<a_predecessor_id, a_successor_id>>)
			if not l_result.is_empty then
				Result := l_result.first.integer_value ("lag")
			end
		end

	max_early_finish (a_activities: ARRAYED_LIST [CPM_ACTIVITY]): INTEGER
			-- Maximum Early Finish across all activities (project duration).
		do
			across a_activities as ic loop
				Result := Result.max (ic.early_finish)
			end
		end

	update_activity_schedule (a_activity: CPM_ACTIVITY)
			-- Update activity schedule in database.
		do
			database.execute_with_args ("UPDATE activities SET early_start = ?, early_finish = ?, late_start = ?, late_finish = ?, float = ?, is_critical = ? WHERE id = ?", <<a_activity.early_start, a_activity.early_finish, a_activity.late_start, a_activity.late_finish, a_activity.float, a_activity.is_critical, a_activity.id>>)
		end

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
