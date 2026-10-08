note
	description: "Test application root class for cpm_app tests: runs every test through EQA_TEST_EVALUATOR"
	date: "$Date$"
	revision: "$Revision$"

class
	APPLICATION

create
	make

feature -- Initialization

	make
			-- Run every cpm_app test and print a summary.
		do
			run_test_cpm_app
			run_test_cpm_app_stress
			print ("%N========================%N")
			print ("Results: " + passed.out + " passed, " + failed.out + " failed%N")
		end

feature {NONE} -- Runners

	run_test_cpm_app
		local
			l_eval: EQA_TEST_EVALUATOR [TEST_CPM_APP]
		do
			create l_eval
			report ("TEST_CPM_APP.test_create_project", l_eval.execute (agent {TEST_CPM_APP}.test_create_project))
			report ("TEST_CPM_APP.test_find_project", l_eval.execute (agent {TEST_CPM_APP}.test_find_project))
			report ("TEST_CPM_APP.test_all_projects", l_eval.execute (agent {TEST_CPM_APP}.test_all_projects))
			report ("TEST_CPM_APP.test_delete_project", l_eval.execute (agent {TEST_CPM_APP}.test_delete_project))
			report ("TEST_CPM_APP.test_add_activity", l_eval.execute (agent {TEST_CPM_APP}.test_add_activity))
			report ("TEST_CPM_APP.test_find_activity_by_code", l_eval.execute (agent {TEST_CPM_APP}.test_find_activity_by_code))
			report ("TEST_CPM_APP.test_project_activities", l_eval.execute (agent {TEST_CPM_APP}.test_project_activities))
			report ("TEST_CPM_APP.test_activity_count", l_eval.execute (agent {TEST_CPM_APP}.test_activity_count))
			report ("TEST_CPM_APP.test_add_dependency", l_eval.execute (agent {TEST_CPM_APP}.test_add_dependency))
			report ("TEST_CPM_APP.test_predecessors_and_successors", l_eval.execute (agent {TEST_CPM_APP}.test_predecessors_and_successors))
			report ("TEST_CPM_APP.test_dependency_with_lag", l_eval.execute (agent {TEST_CPM_APP}.test_dependency_with_lag))
			report ("TEST_CPM_APP.test_simple_linear_cpm", l_eval.execute (agent {TEST_CPM_APP}.test_simple_linear_cpm))
			report ("TEST_CPM_APP.test_parallel_paths_cpm", l_eval.execute (agent {TEST_CPM_APP}.test_parallel_paths_cpm))
			report ("TEST_CPM_APP.test_cpm_with_lag", l_eval.execute (agent {TEST_CPM_APP}.test_cpm_with_lag))
			report ("TEST_CPM_APP.test_milestone_activity", l_eval.execute (agent {TEST_CPM_APP}.test_milestone_activity))
			report ("TEST_CPM_APP.test_total_float", l_eval.execute (agent {TEST_CPM_APP}.test_total_float))
			report ("TEST_CPM_APP.test_critical_path_activities", l_eval.execute (agent {TEST_CPM_APP}.test_critical_path_activities))
			report ("TEST_CPM_APP.test_empty_project", l_eval.execute (agent {TEST_CPM_APP}.test_empty_project))
			report ("TEST_CPM_APP.test_single_activity", l_eval.execute (agent {TEST_CPM_APP}.test_single_activity))
		end

	run_test_cpm_app_stress
		local
			l_eval: EQA_TEST_EVALUATOR [TEST_CPM_APP_STRESS]
		do
			create l_eval
			report ("TEST_CPM_APP_STRESS.test_riverside_commercial_complex", l_eval.execute (agent {TEST_CPM_APP_STRESS}.test_riverside_commercial_complex))
			report ("TEST_CPM_APP_STRESS.test_volume_100_activities", l_eval.execute (agent {TEST_CPM_APP_STRESS}.test_volume_100_activities))
			report ("TEST_CPM_APP_STRESS.test_volume_parallel_paths", l_eval.execute (agent {TEST_CPM_APP_STRESS}.test_volume_parallel_paths))
			report ("TEST_CPM_APP_STRESS.test_volume_diamond_network", l_eval.execute (agent {TEST_CPM_APP_STRESS}.test_volume_diamond_network))
			report ("TEST_CPM_APP_STRESS.test_multiple_concurrent_projects", l_eval.execute (agent {TEST_CPM_APP_STRESS}.test_multiple_concurrent_projects))
			report ("TEST_CPM_APP_STRESS.test_rapid_recalculation", l_eval.execute (agent {TEST_CPM_APP_STRESS}.test_rapid_recalculation))
			report ("TEST_CPM_APP_STRESS.test_multiple_predecessors", l_eval.execute (agent {TEST_CPM_APP_STRESS}.test_multiple_predecessors))
			report ("TEST_CPM_APP_STRESS.test_varied_lag_times", l_eval.execute (agent {TEST_CPM_APP_STRESS}.test_varied_lag_times))
		end

feature {NONE} -- Implementation

	passed, failed: INTEGER

	report (a_name: STRING_8; a_result: EQA_PARTIAL_RESULT)
			-- Count and print the outcome of test `a_name'.
		do
			if a_result.is_pass then
				passed := passed + 1
				print ("  PASS: " + a_name + "%N")
			else
				failed := failed + 1
				print ("  FAIL: " + a_name)
				if attached {EQA_RESULT} a_result as l_full and then attached l_full.test_response.exception as l_ex then
					print (" [" + {UTF_CONVERTER}.string_32_to_utf_8_string_8 (l_ex.tag_name) + "]")
				end
				print ("%N")
			end
		end

end
