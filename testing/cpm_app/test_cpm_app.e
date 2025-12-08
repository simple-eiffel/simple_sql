note
	description: "Tests for CPM_APP consumer example"
	testing: "covers"
	testing: "execution/serial"

class
	TEST_CPM_APP

inherit
	TEST_SET_BASE

feature -- Test routines: Project Management

	test_create_project
			-- Test creating a project.
		local
			l_app: CPM_APP
			l_project: CPM_PROJECT
		do
			create l_app.make
			l_project := l_app.create_project ("Office Building")

			assert_false ("is_saved", l_project.is_new)
			assert_strings_equal ("name", "Office Building", l_project.name)
			assert_equal ("initial_duration", 0, l_project.calculated_duration)

			l_app.close
		end

	test_find_project
			-- Test finding a project by ID.
		local
			l_app: CPM_APP
			l_project: CPM_PROJECT
		do
			create l_app.make
			l_project := l_app.create_project ("Warehouse")

			if attached l_app.find_project (l_project.id) as l_found then
				assert_strings_equal ("name_matches", "Warehouse", l_found.name)
			else
				assert_true ("found", False)
			end

			l_app.close
		end

	test_all_projects
			-- Test retrieving all projects.
		local
			l_app: CPM_APP
			l_ignored: CPM_PROJECT
			l_projects: ARRAYED_LIST [CPM_PROJECT]
		do
			create l_app.make
			l_ignored := l_app.create_project ("Alpha")
			l_ignored := l_app.create_project ("Beta")
			l_ignored := l_app.create_project ("Gamma")

			l_projects := l_app.all_projects

			assert_equal ("three_projects", 3, l_projects.count)
			-- Ordered by name
			assert_strings_equal ("first", "Alpha", l_projects.first.name)

			l_app.close
		end

	test_delete_project
			-- Test deleting a project.
		local
			l_app: CPM_APP
			l_project: CPM_PROJECT
		do
			create l_app.make
			l_project := l_app.create_project ("To Delete")

			assert_true ("deleted", l_app.delete_project (l_project.id))
			assert_true ("not_found", l_app.find_project (l_project.id) = Void)

			l_app.close
		end

feature -- Test routines: Activity Management

	test_add_activity
			-- Test adding an activity.
		local
			l_app: CPM_APP
			l_project: CPM_PROJECT
			l_activity: CPM_ACTIVITY
		do
			create l_app.make
			l_project := l_app.create_project ("Test Project")
			l_activity := l_app.add_activity (l_project.id, "A", "Foundation", 10)

			assert_false ("is_saved", l_activity.is_new)
			assert_strings_equal ("code", "A", l_activity.code)
			assert_strings_equal ("name", "Foundation", l_activity.name)
			assert_equal ("duration", 10, l_activity.duration)

			l_app.close
		end

	test_find_activity_by_code
			-- Test finding activity by code.
		local
			l_app: CPM_APP
			l_project: CPM_PROJECT
			l_ignored: CPM_ACTIVITY
		do
			create l_app.make
			l_project := l_app.create_project ("Test Project")
			l_ignored := l_app.add_activity (l_project.id, "FOUND-01", "Pour Foundation", 15)

			if attached l_app.find_activity_by_code (l_project.id, "FOUND-01") as l_found then
				assert_strings_equal ("name", "Pour Foundation", l_found.name)
			else
				assert_true ("found", False)
			end

			l_app.close
		end

	test_project_activities
			-- Test getting all activities for a project.
		local
			l_app: CPM_APP
			l_project: CPM_PROJECT
			l_ignored: CPM_ACTIVITY
			l_activities: ARRAYED_LIST [CPM_ACTIVITY]
		do
			create l_app.make
			l_project := l_app.create_project ("Test Project")
			l_ignored := l_app.add_activity (l_project.id, "C", "Roof", 5)
			l_ignored := l_app.add_activity (l_project.id, "A", "Foundation", 10)
			l_ignored := l_app.add_activity (l_project.id, "B", "Framing", 8)

			l_activities := l_app.project_activities (l_project.id)

			assert_equal ("three_activities", 3, l_activities.count)
			-- Ordered by code
			assert_strings_equal ("first_code", "A", l_activities.first.code)

			l_app.close
		end

	test_activity_count
			-- Test activity count.
		local
			l_app: CPM_APP
			l_project: CPM_PROJECT
			l_ignored: CPM_ACTIVITY
		do
			create l_app.make
			l_project := l_app.create_project ("Test Project")

			assert_equal ("zero_initially", 0, l_app.activity_count (l_project.id))

			l_ignored := l_app.add_activity (l_project.id, "A", "Task A", 5)
			l_ignored := l_app.add_activity (l_project.id, "B", "Task B", 3)

			assert_equal ("two_activities", 2, l_app.activity_count (l_project.id))

			l_app.close
		end

feature -- Test routines: Dependency Management

	test_add_dependency
			-- Test adding a dependency.
		local
			l_app: CPM_APP
			l_project: CPM_PROJECT
			l_a, l_b: CPM_ACTIVITY
			l_dep: CPM_DEPENDENCY
		do
			create l_app.make
			l_project := l_app.create_project ("Test Project")
			l_a := l_app.add_activity (l_project.id, "A", "First", 5)
			l_b := l_app.add_activity (l_project.id, "B", "Second", 3)

			l_dep := l_app.add_dependency (l_a.id, l_b.id)

			assert_false ("is_saved", l_dep.is_new)
			assert_true ("finish_to_start", l_dep.is_finish_to_start)
			assert_equal ("zero_lag", 0, l_dep.lag)

			l_app.close
		end

	test_predecessors_and_successors
			-- Test getting predecessors and successors.
		local
			l_app: CPM_APP
			l_project: CPM_PROJECT
			l_a, l_b, l_c: CPM_ACTIVITY
			l_ignored: CPM_DEPENDENCY
			l_preds, l_succs: ARRAYED_LIST [CPM_ACTIVITY]
		do
			create l_app.make
			l_project := l_app.create_project ("Test Project")
			l_a := l_app.add_activity (l_project.id, "A", "First", 5)
			l_b := l_app.add_activity (l_project.id, "B", "Second", 3)
			l_c := l_app.add_activity (l_project.id, "C", "Third", 4)

			-- A -> B -> C
			l_ignored := l_app.add_dependency (l_a.id, l_b.id)
			l_ignored := l_app.add_dependency (l_b.id, l_c.id)

			l_preds := l_app.predecessors (l_b.id)
			l_succs := l_app.successors (l_b.id)

			assert_equal ("one_predecessor", 1, l_preds.count)
			assert_strings_equal ("pred_is_a", "A", l_preds.first.code)
			assert_equal ("one_successor", 1, l_succs.count)
			assert_strings_equal ("succ_is_c", "C", l_succs.first.code)

			l_app.close
		end

	test_dependency_with_lag
			-- Test dependency with lag time.
		local
			l_app: CPM_APP
			l_project: CPM_PROJECT
			l_a, l_b: CPM_ACTIVITY
			l_dep: CPM_DEPENDENCY
		do
			create l_app.make
			l_project := l_app.create_project ("Test Project")
			l_a := l_app.add_activity (l_project.id, "A", "Pour Concrete", 2)
			l_b := l_app.add_activity (l_project.id, "B", "Build on Concrete", 5)

			-- B can only start 7 days after A finishes (curing time)
			l_dep := l_app.add_dependency_with_lag (l_a.id, l_b.id, "FS", 7)

			assert_equal ("lag_7", 7, l_dep.lag)

			l_app.close
		end

feature -- Test routines: CPM Calculation

	test_simple_linear_cpm
			-- Test CPM on simple linear sequence A -> B -> C.
		local
			l_app: CPM_APP
			l_project: CPM_PROJECT
			l_a, l_b, l_c: CPM_ACTIVITY
			l_ignored: CPM_DEPENDENCY
		do
			create l_app.make
			l_project := l_app.create_project ("Linear Project")

			-- A(5) -> B(3) -> C(4) = 12 days total
			l_a := l_app.add_activity (l_project.id, "A", "Task A", 5)
			l_b := l_app.add_activity (l_project.id, "B", "Task B", 3)
			l_c := l_app.add_activity (l_project.id, "C", "Task C", 4)

			l_ignored := l_app.add_dependency (l_a.id, l_b.id)
			l_ignored := l_app.add_dependency (l_b.id, l_c.id)

			l_app.calculate_cpm (l_project.id)

			-- Check project duration
			assert_equal ("duration_12", 12, l_app.project_duration (l_project.id))

			-- All activities should be critical (single path)
			assert_equal ("all_critical", 3, l_app.critical_path_length (l_project.id))

			-- Verify schedule values
			if attached l_app.find_activity (l_a.id) as l_a_upd then
				assert_equal ("a_es", 0, l_a_upd.early_start)
				assert_equal ("a_ef", 5, l_a_upd.early_finish)
				assert_true ("a_critical", l_a_upd.is_critical)
			end

			if attached l_app.find_activity (l_b.id) as l_b_upd then
				assert_equal ("b_es", 5, l_b_upd.early_start)
				assert_equal ("b_ef", 8, l_b_upd.early_finish)
				assert_true ("b_critical", l_b_upd.is_critical)
			end

			if attached l_app.find_activity (l_c.id) as l_c_upd then
				assert_equal ("c_es", 8, l_c_upd.early_start)
				assert_equal ("c_ef", 12, l_c_upd.early_finish)
				assert_true ("c_critical", l_c_upd.is_critical)
			end

			l_app.close
		end

	test_parallel_paths_cpm
			-- Test CPM with parallel paths to identify critical path.
		local
			l_app: CPM_APP
			l_project: CPM_PROJECT
			l_start, l_a, l_b, l_finish: CPM_ACTIVITY
			l_ignored: CPM_DEPENDENCY
		do
			create l_app.make
			l_project := l_app.create_project ("Parallel Project")

			-- START(0) -> A(10) -> FINISH(0)
			--          -> B(5)  ->
			-- Critical path: START -> A -> FINISH (10 days)
			-- B has float of 5 days

			l_start := l_app.add_activity (l_project.id, "START", "Start", 0)
			l_a := l_app.add_activity (l_project.id, "A", "Long Path", 10)
			l_b := l_app.add_activity (l_project.id, "B", "Short Path", 5)
			l_finish := l_app.add_activity (l_project.id, "FINISH", "Finish", 0)

			l_ignored := l_app.add_dependency (l_start.id, l_a.id)
			l_ignored := l_app.add_dependency (l_start.id, l_b.id)
			l_ignored := l_app.add_dependency (l_a.id, l_finish.id)
			l_ignored := l_app.add_dependency (l_b.id, l_finish.id)

			l_app.calculate_cpm (l_project.id)

			-- Project duration should be 10 days
			assert_equal ("duration_10", 10, l_app.project_duration (l_project.id))

			-- A should be critical, B should have float
			if attached l_app.find_activity (l_a.id) as l_a_upd then
				assert_true ("a_critical", l_a_upd.is_critical)
				assert_equal ("a_float", 0, l_a_upd.float)
			end

			if attached l_app.find_activity (l_b.id) as l_b_upd then
				assert_false ("b_not_critical", l_b_upd.is_critical)
				assert_equal ("b_float", 5, l_b_upd.float)
			end

			l_app.close
		end

	test_cpm_with_lag
			-- Test CPM calculation respects lag time.
		local
			l_app: CPM_APP
			l_project: CPM_PROJECT
			l_a, l_b: CPM_ACTIVITY
			l_ignored: CPM_DEPENDENCY
		do
			create l_app.make
			l_project := l_app.create_project ("Lag Project")

			-- A(2) --[lag 7]--> B(5) = 2 + 7 + 5 = 14 days
			l_a := l_app.add_activity (l_project.id, "A", "Pour Concrete", 2)
			l_b := l_app.add_activity (l_project.id, "B", "Build", 5)

			l_ignored := l_app.add_dependency_with_lag (l_a.id, l_b.id, "FS", 7)

			l_app.calculate_cpm (l_project.id)

			assert_equal ("duration_14", 14, l_app.project_duration (l_project.id))

			if attached l_app.find_activity (l_b.id) as l_b_upd then
				assert_equal ("b_es", 9, l_b_upd.early_start) -- 2 + 7 = 9
				assert_equal ("b_ef", 14, l_b_upd.early_finish)
			end

			l_app.close
		end

	test_milestone_activity
			-- Test milestone (zero duration) activity.
		local
			l_app: CPM_APP
			l_project: CPM_PROJECT
			l_a, l_milestone, l_b: CPM_ACTIVITY
			l_ignored: CPM_DEPENDENCY
		do
			create l_app.make
			l_project := l_app.create_project ("Milestone Project")

			-- A(5) -> MILESTONE(0) -> B(3)
			l_a := l_app.add_activity (l_project.id, "A", "Work", 5)
			l_milestone := l_app.add_activity (l_project.id, "M", "Phase Complete", 0)
			l_b := l_app.add_activity (l_project.id, "B", "More Work", 3)

			l_ignored := l_app.add_dependency (l_a.id, l_milestone.id)
			l_ignored := l_app.add_dependency (l_milestone.id, l_b.id)

			l_app.calculate_cpm (l_project.id)

			assert_equal ("duration_8", 8, l_app.project_duration (l_project.id))
			assert_true ("is_milestone", l_milestone.is_milestone)

			if attached l_app.find_activity (l_milestone.id) as l_m then
				assert_equal ("m_es_ef_same", l_m.early_start, l_m.early_finish)
			end

			l_app.close
		end

feature -- Test routines: Statistics

	test_total_float
			-- Test total float calculation.
		local
			l_app: CPM_APP
			l_project: CPM_PROJECT
			l_start, l_a, l_b, l_c, l_finish: CPM_ACTIVITY
			l_ignored: CPM_DEPENDENCY
		do
			create l_app.make
			l_project := l_app.create_project ("Float Project")

			-- Critical: START -> A(10) -> FINISH
			-- Non-critical: START -> B(3) -> C(2) -> FINISH (5 days, float = 5 each)
			l_start := l_app.add_activity (l_project.id, "START", "Start", 0)
			l_a := l_app.add_activity (l_project.id, "A", "Critical Work", 10)
			l_b := l_app.add_activity (l_project.id, "B", "Optional 1", 3)
			l_c := l_app.add_activity (l_project.id, "C", "Optional 2", 2)
			l_finish := l_app.add_activity (l_project.id, "FINISH", "Finish", 0)

			l_ignored := l_app.add_dependency (l_start.id, l_a.id)
			l_ignored := l_app.add_dependency (l_start.id, l_b.id)
			l_ignored := l_app.add_dependency (l_a.id, l_finish.id)
			l_ignored := l_app.add_dependency (l_b.id, l_c.id)
			l_ignored := l_app.add_dependency (l_c.id, l_finish.id)

			l_app.calculate_cpm (l_project.id)

			-- Total float = 0 + 0 + 5 + 5 + 0 = 10
			assert_equal ("total_float_10", 10, l_app.total_float (l_project.id))

			l_app.close
		end

	test_critical_path_activities
			-- Test retrieving only critical path activities.
		local
			l_app: CPM_APP
			l_project: CPM_PROJECT
			l_start, l_a, l_b, l_finish: CPM_ACTIVITY
			l_ignored: CPM_DEPENDENCY
			l_critical: ARRAYED_LIST [CPM_ACTIVITY]
		do
			create l_app.make
			l_project := l_app.create_project ("Critical Path Project")

			l_start := l_app.add_activity (l_project.id, "START", "Start", 0)
			l_a := l_app.add_activity (l_project.id, "A", "Critical", 10)
			l_b := l_app.add_activity (l_project.id, "B", "Non-critical", 5)
			l_finish := l_app.add_activity (l_project.id, "FINISH", "Finish", 0)

			l_ignored := l_app.add_dependency (l_start.id, l_a.id)
			l_ignored := l_app.add_dependency (l_start.id, l_b.id)
			l_ignored := l_app.add_dependency (l_a.id, l_finish.id)
			l_ignored := l_app.add_dependency (l_b.id, l_finish.id)

			l_app.calculate_cpm (l_project.id)

			l_critical := l_app.critical_path_activities (l_project.id)

			-- Should be START, A, FINISH (not B)
			assert_equal ("three_critical", 3, l_critical.count)
			assert_true ("b_not_in_critical", across l_critical as ic all not ic.code.same_string ("B") end)

			l_app.close
		end

feature -- Test routines: Edge Cases

	test_empty_project
			-- Test CPM on empty project.
		local
			l_app: CPM_APP
			l_project: CPM_PROJECT
		do
			create l_app.make
			l_project := l_app.create_project ("Empty")

			l_app.calculate_cpm (l_project.id)

			assert_equal ("zero_duration", 0, l_app.project_duration (l_project.id))
			assert_equal ("zero_activities", 0, l_app.activity_count (l_project.id))

			l_app.close
		end

	test_single_activity
			-- Test CPM with single activity.
		local
			l_app: CPM_APP
			l_project: CPM_PROJECT
			l_a: CPM_ACTIVITY
		do
			create l_app.make
			l_project := l_app.create_project ("Single")
			l_a := l_app.add_activity (l_project.id, "A", "Only Task", 7)

			l_app.calculate_cpm (l_project.id)

			assert_equal ("duration_7", 7, l_app.project_duration (l_project.id))

			if attached l_app.find_activity (l_a.id) as l_upd then
				assert_true ("is_critical", l_upd.is_critical)
				assert_equal ("es_0", 0, l_upd.early_start)
				assert_equal ("ef_7", 7, l_upd.early_finish)
			end

			l_app.close
		end

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
