note
	description: "Test application for SIMPLE_SQL"
	author: "Larry Rix"

class
	TEST_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Run the tests.
		do
			print ("Running SIMPLE_SQL tests...%N%N")
			passed := 0
			failed := 0

			run_lib_tests
			run_simple_sql_tests

			print ("%N========================%N")
			print ("Results: " + passed.out + " passed, " + failed.out + " failed%N")

			if failed > 0 then
				print ("TESTS FAILED%N")
			else
				print ("ALL TESTS PASSED%N")
			end
		end

feature {NONE} -- Test Runners

	run_lib_tests
		do
			create lib_tests
			run_test (agent lib_tests.test_make_memory, "test_make_memory")
			run_test (agent lib_tests.test_execute_create_table, "test_execute_create_table")
			run_test (agent lib_tests.test_execute_insert, "test_execute_insert")
			run_test (agent lib_tests.test_query_select, "test_query_select")
			run_test (agent lib_tests.test_query_empty_result, "test_query_empty_result")
			run_test (agent lib_tests.test_transaction_commit, "test_transaction_commit")
			run_test (agent lib_tests.test_transaction_rollback, "test_transaction_rollback")
			run_test (agent lib_tests.test_prepared_statement, "test_prepared_statement")
			run_test (agent lib_tests.test_row_column_access, "test_row_column_access")
		end

	run_simple_sql_tests
		do
			create sql_tests
			run_test (agent sql_tests.test_create_memory_database, "test_create_memory_database")
			run_test (agent sql_tests.test_execute_create_table, "test_execute_create_table")
			run_test (agent sql_tests.test_insert_and_query, "test_insert_and_query")
			run_test (agent sql_tests.test_changes_count, "test_changes_count")
			run_test (agent sql_tests.test_transaction, "test_transaction")
			run_test (agent sql_tests.test_rollback, "test_rollback")
			run_test (agent sql_tests.test_empty_result, "test_empty_result")
			run_test (agent sql_tests.test_row_access_by_index, "test_row_access_by_index")
			run_test (agent sql_tests.test_null_values, "test_null_values")
			run_test (agent sql_tests.test_real_values, "test_real_values")
			run_test (agent sql_tests.test_has_column, "test_has_column")
			run_test (agent sql_tests.test_transaction_nested, "test_transaction_nested")
			run_test (agent sql_tests.test_execute_with_args_insert, "test_execute_with_args_insert")
			run_test (agent sql_tests.test_execute_with_args_update, "test_execute_with_args_update")
			run_test (agent sql_tests.test_execute_with_args_null, "test_execute_with_args_null")
			run_test (agent sql_tests.test_execute_with_args_integer_64, "test_execute_with_args_integer_64")
			run_test (agent sql_tests.test_query_with_args_select, "test_query_with_args_select")
			run_test (agent sql_tests.test_query_with_args_multiple_params, "test_query_with_args_multiple_params")
			run_test (agent sql_tests.test_query_with_args_integer_64, "test_query_with_args_integer_64")
		end

feature {NONE} -- Implementation

	lib_tests: LIB_TESTS
	sql_tests: TEST_SIMPLE_SQL

	passed: INTEGER
	failed: INTEGER

	run_test (a_test: PROCEDURE; a_name: STRING)
			-- Run a single test and update counters.
		local
			l_retried: BOOLEAN
		do
			if not l_retried then
				a_test.call (Void)
				print ("  PASS: " + a_name + "%N")
				passed := passed + 1
			end
		rescue
			print ("  FAIL: " + a_name + "%N")
			failed := failed + 1
			l_retried := True
			retry
		end

end
