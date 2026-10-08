note
	description: "Test application root class for todo_app tests: runs every test through EQA_TEST_EVALUATOR"
	date: "$Date$"
	revision: "$Revision$"

class
	APPLICATION

create
	make

feature -- Initialization

	make
			-- Run every todo_app test and print a summary.
		do
			run_test_todo_app
			run_test_todo_app_stress
			print ("%N========================%N")
			print ("Results: " + passed.out + " passed, " + failed.out + " failed%N")
		end

feature {NONE} -- Runners

	run_test_todo_app
		local
			l_eval: EQA_TEST_EVALUATOR [TEST_TODO_APP]
		do
			create l_eval
			report ("TEST_TODO_APP.test_create_todo", l_eval.execute (agent {TEST_TODO_APP}.test_create_todo))
			report ("TEST_TODO_APP.test_create_todo_with_details", l_eval.execute (agent {TEST_TODO_APP}.test_create_todo_with_details))
			report ("TEST_TODO_APP.test_find_todo", l_eval.execute (agent {TEST_TODO_APP}.test_find_todo))
			report ("TEST_TODO_APP.test_delete_todo", l_eval.execute (agent {TEST_TODO_APP}.test_delete_todo))
			report ("TEST_TODO_APP.test_complete_todo", l_eval.execute (agent {TEST_TODO_APP}.test_complete_todo))
			report ("TEST_TODO_APP.test_uncomplete_todo", l_eval.execute (agent {TEST_TODO_APP}.test_uncomplete_todo))
			report ("TEST_TODO_APP.test_clear_completed", l_eval.execute (agent {TEST_TODO_APP}.test_clear_completed))
			report ("TEST_TODO_APP.test_all_todos", l_eval.execute (agent {TEST_TODO_APP}.test_all_todos))
			report ("TEST_TODO_APP.test_incomplete_todos", l_eval.execute (agent {TEST_TODO_APP}.test_incomplete_todos))
			report ("TEST_TODO_APP.test_completed_todos", l_eval.execute (agent {TEST_TODO_APP}.test_completed_todos))
			report ("TEST_TODO_APP.test_high_priority_todos", l_eval.execute (agent {TEST_TODO_APP}.test_high_priority_todos))
			report ("TEST_TODO_APP.test_search_todos", l_eval.execute (agent {TEST_TODO_APP}.test_search_todos))
			report ("TEST_TODO_APP.test_total_count", l_eval.execute (agent {TEST_TODO_APP}.test_total_count))
			report ("TEST_TODO_APP.test_completion_percentage", l_eval.execute (agent {TEST_TODO_APP}.test_completion_percentage))
			report ("TEST_TODO_APP.test_incomplete_and_completed_counts", l_eval.execute (agent {TEST_TODO_APP}.test_incomplete_and_completed_counts))
			report ("TEST_TODO_APP.test_repository_find_by_priority", l_eval.execute (agent {TEST_TODO_APP}.test_repository_find_by_priority))
			report ("TEST_TODO_APP.test_repository_pagination", l_eval.execute (agent {TEST_TODO_APP}.test_repository_pagination))
			report ("TEST_TODO_APP.test_empty_database", l_eval.execute (agent {TEST_TODO_APP}.test_empty_database))
			report ("TEST_TODO_APP.test_todo_not_found", l_eval.execute (agent {TEST_TODO_APP}.test_todo_not_found))
			report ("TEST_TODO_APP.test_priorities_range", l_eval.execute (agent {TEST_TODO_APP}.test_priorities_range))
		end

	run_test_todo_app_stress
		local
			l_eval: EQA_TEST_EVALUATOR [TEST_TODO_APP_STRESS]
		do
			create l_eval
			report ("TEST_TODO_APP_STRESS.test_volume_10000_todos", l_eval.execute (agent {TEST_TODO_APP_STRESS}.test_volume_10000_todos))
			report ("TEST_TODO_APP_STRESS.test_volume_pagination_large", l_eval.execute (agent {TEST_TODO_APP_STRESS}.test_volume_pagination_large))
			report ("TEST_TODO_APP_STRESS.test_volume_streaming_cursor", l_eval.execute (agent {TEST_TODO_APP_STRESS}.test_volume_streaming_cursor))
			report ("TEST_TODO_APP_STRESS.test_transaction_bulk_complete", l_eval.execute (agent {TEST_TODO_APP_STRESS}.test_transaction_bulk_complete))
			report ("TEST_TODO_APP_STRESS.test_transaction_rollback_on_failure", l_eval.execute (agent {TEST_TODO_APP_STRESS}.test_transaction_rollback_on_failure))
			report ("TEST_TODO_APP_STRESS.test_transaction_batch_insert", l_eval.execute (agent {TEST_TODO_APP_STRESS}.test_transaction_batch_insert))
			report ("TEST_TODO_APP_STRESS.test_rapid_crud_cycles", l_eval.execute (agent {TEST_TODO_APP_STRESS}.test_rapid_crud_cycles))
			report ("TEST_TODO_APP_STRESS.test_rapid_update_same_record", l_eval.execute (agent {TEST_TODO_APP_STRESS}.test_rapid_update_same_record))
			report ("TEST_TODO_APP_STRESS.test_query_with_many_conditions", l_eval.execute (agent {TEST_TODO_APP_STRESS}.test_query_with_many_conditions))
			report ("TEST_TODO_APP_STRESS.test_search_large_dataset", l_eval.execute (agent {TEST_TODO_APP_STRESS}.test_search_large_dataset))
			report ("TEST_TODO_APP_STRESS.test_prepared_statement_reuse", l_eval.execute (agent {TEST_TODO_APP_STRESS}.test_prepared_statement_reuse))
			report ("TEST_TODO_APP_STRESS.test_fts5_description_search", l_eval.execute (agent {TEST_TODO_APP_STRESS}.test_fts5_description_search))
			report ("TEST_TODO_APP_STRESS.test_json_metadata_storage", l_eval.execute (agent {TEST_TODO_APP_STRESS}.test_json_metadata_storage))
			report ("TEST_TODO_APP_STRESS.test_json_aggregate_todos", l_eval.execute (agent {TEST_TODO_APP_STRESS}.test_json_aggregate_todos))
			report ("TEST_TODO_APP_STRESS.test_audit_tracking", l_eval.execute (agent {TEST_TODO_APP_STRESS}.test_audit_tracking))
			report ("TEST_TODO_APP_STRESS.test_schema_migration_add_column", l_eval.execute (agent {TEST_TODO_APP_STRESS}.test_schema_migration_add_column))
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
