note
	description: "[
		Runs the test sets whose tests TEST_APP did not call (port-coordination #17:
		342 of the test features in simple_sql_tests' cluster ran in no gate; the example apps have test targets of their own). Each test goes through
		AutoTest's own EQA_TEST_EVALUATOR: a fresh test set (on_prepare), the test, then
		clean (on_clean), so each runs as AutoTest would run it. A failing test is
		printed as "FAIL:" with its tag and counted.
	]"

class
	AUTOTEST_SETS_RUNNER

feature -- Counts

	passed, failed: INTEGER
			-- Tests run here.

feature -- Running

	run_all
			-- Every test below, 342 in all.
		do
			run_test_blob_debug
			run_test_phase6_atomic
			run_test_simple_sql_advanced_backup
			run_test_simple_sql_audit
			run_test_simple_sql_backup
			run_test_simple_sql_batch
			run_test_simple_sql_blob
			run_test_simple_sql_error
			run_test_simple_sql_fts5
			run_test_simple_sql_json
			run_test_simple_sql_json_advanced
			run_test_simple_sql_migration
			run_test_simple_sql_pragma_config
			run_test_simple_sql_prepared_statement
			run_test_simple_sql_query_builders
			run_test_simple_sql_repository
			run_test_simple_sql_schema
			run_test_simple_sql_streaming
			run_test_simple_sql_vector
		end

feature {NONE} -- Test sets







	run_test_blob_debug
		local
			l_evaluator: EQA_TEST_EVALUATOR [TEST_BLOB_DEBUG]
		do
			create l_evaluator
			report (l_evaluator.execute (agent {TEST_BLOB_DEBUG}.test_debug_blob_type), "TEST_BLOB_DEBUG.test_debug_blob_type")
		end

	run_test_phase6_atomic
		local
			l_evaluator: EQA_TEST_EVALUATOR [TEST_PHASE6_ATOMIC]
		do
			create l_evaluator
			report (l_evaluator.execute (agent {TEST_PHASE6_ATOMIC}.test_atomic_commits_on_success), "TEST_PHASE6_ATOMIC.test_atomic_commits_on_success")
			report (l_evaluator.execute (agent {TEST_PHASE6_ATOMIC}.test_atomic_rollback_on_failure), "TEST_PHASE6_ATOMIC.test_atomic_rollback_on_failure")
			report (l_evaluator.execute (agent {TEST_PHASE6_ATOMIC}.test_update_versioned_success), "TEST_PHASE6_ATOMIC.test_update_versioned_success")
			report (l_evaluator.execute (agent {TEST_PHASE6_ATOMIC}.test_update_versioned_fails_on_stale_version), "TEST_PHASE6_ATOMIC.test_update_versioned_fails_on_stale_version")
			report (l_evaluator.execute (agent {TEST_PHASE6_ATOMIC}.test_update_versioned_multiple_columns), "TEST_PHASE6_ATOMIC.test_update_versioned_multiple_columns")
			report (l_evaluator.execute (agent {TEST_PHASE6_ATOMIC}.test_upsert_inserts_new_row), "TEST_PHASE6_ATOMIC.test_upsert_inserts_new_row")
			report (l_evaluator.execute (agent {TEST_PHASE6_ATOMIC}.test_upsert_updates_existing_row), "TEST_PHASE6_ATOMIC.test_upsert_updates_existing_row")
			report (l_evaluator.execute (agent {TEST_PHASE6_ATOMIC}.test_upsert_multiple_rows), "TEST_PHASE6_ATOMIC.test_upsert_multiple_rows")
			report (l_evaluator.execute (agent {TEST_PHASE6_ATOMIC}.test_decrement_if_succeeds_when_sufficient), "TEST_PHASE6_ATOMIC.test_decrement_if_succeeds_when_sufficient")
			report (l_evaluator.execute (agent {TEST_PHASE6_ATOMIC}.test_decrement_if_fails_when_insufficient), "TEST_PHASE6_ATOMIC.test_decrement_if_fails_when_insufficient")
			report (l_evaluator.execute (agent {TEST_PHASE6_ATOMIC}.test_decrement_if_fails_when_row_not_found), "TEST_PHASE6_ATOMIC.test_decrement_if_fails_when_row_not_found")
			report (l_evaluator.execute (agent {TEST_PHASE6_ATOMIC}.test_decrement_if_atomic), "TEST_PHASE6_ATOMIC.test_decrement_if_atomic")
			report (l_evaluator.execute (agent {TEST_PHASE6_ATOMIC}.test_increment_if_succeeds), "TEST_PHASE6_ATOMIC.test_increment_if_succeeds")
			report (l_evaluator.execute (agent {TEST_PHASE6_ATOMIC}.test_increment_if_fails_when_row_not_found), "TEST_PHASE6_ATOMIC.test_increment_if_fails_when_row_not_found")
			report (l_evaluator.execute (agent {TEST_PHASE6_ATOMIC}.test_increment_if_with_complex_condition), "TEST_PHASE6_ATOMIC.test_increment_if_with_complex_condition")
		end

	run_test_simple_sql_advanced_backup
		local
			l_evaluator: EQA_TEST_EVALUATOR [TEST_SIMPLE_SQL_ADVANCED_BACKUP]
		do
			create l_evaluator
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ADVANCED_BACKUP}.test_online_backup_complete), "TEST_SIMPLE_SQL_ADVANCED_BACKUP.test_online_backup_complete")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ADVANCED_BACKUP}.test_online_backup_with_progress), "TEST_SIMPLE_SQL_ADVANCED_BACKUP.test_online_backup_with_progress")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ADVANCED_BACKUP}.test_online_backup_progress_percentage), "TEST_SIMPLE_SQL_ADVANCED_BACKUP.test_online_backup_progress_percentage")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ADVANCED_BACKUP}.test_export_csv_table), "TEST_SIMPLE_SQL_ADVANCED_BACKUP.test_export_csv_table")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ADVANCED_BACKUP}.test_export_csv_string), "TEST_SIMPLE_SQL_ADVANCED_BACKUP.test_export_csv_string")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ADVANCED_BACKUP}.test_export_json_table), "TEST_SIMPLE_SQL_ADVANCED_BACKUP.test_export_json_table")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ADVANCED_BACKUP}.test_export_json_string), "TEST_SIMPLE_SQL_ADVANCED_BACKUP.test_export_json_string")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ADVANCED_BACKUP}.test_export_sql_table), "TEST_SIMPLE_SQL_ADVANCED_BACKUP.test_export_sql_table")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ADVANCED_BACKUP}.test_export_database_sql), "TEST_SIMPLE_SQL_ADVANCED_BACKUP.test_export_database_sql")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ADVANCED_BACKUP}.test_import_csv), "TEST_SIMPLE_SQL_ADVANCED_BACKUP.test_import_csv")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ADVANCED_BACKUP}.test_import_json), "TEST_SIMPLE_SQL_ADVANCED_BACKUP.test_import_json")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ADVANCED_BACKUP}.test_import_sql), "TEST_SIMPLE_SQL_ADVANCED_BACKUP.test_import_sql")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ADVANCED_BACKUP}.test_export_import_round_trip), "TEST_SIMPLE_SQL_ADVANCED_BACKUP.test_export_import_round_trip")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ADVANCED_BACKUP}.test_export_import_blob_sql), "TEST_SIMPLE_SQL_ADVANCED_BACKUP.test_export_import_blob_sql")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ADVANCED_BACKUP}.test_export_csv_with_blob), "TEST_SIMPLE_SQL_ADVANCED_BACKUP.test_export_csv_with_blob")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ADVANCED_BACKUP}.test_import_csv_with_blob), "TEST_SIMPLE_SQL_ADVANCED_BACKUP.test_import_csv_with_blob")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ADVANCED_BACKUP}.test_backup_copy_with_blob), "TEST_SIMPLE_SQL_ADVANCED_BACKUP.test_backup_copy_with_blob")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ADVANCED_BACKUP}.test_backup_during_active_transaction), "TEST_SIMPLE_SQL_ADVANCED_BACKUP.test_backup_during_active_transaction")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ADVANCED_BACKUP}.test_export_csv_special_characters), "TEST_SIMPLE_SQL_ADVANCED_BACKUP.test_export_csv_special_characters")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ADVANCED_BACKUP}.test_export_json_unicode), "TEST_SIMPLE_SQL_ADVANCED_BACKUP.test_export_json_unicode")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ADVANCED_BACKUP}.test_import_csv_malformed_quotes), "TEST_SIMPLE_SQL_ADVANCED_BACKUP.test_import_csv_malformed_quotes")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ADVANCED_BACKUP}.test_import_json_invalid_structure), "TEST_SIMPLE_SQL_ADVANCED_BACKUP.test_import_json_invalid_structure")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ADVANCED_BACKUP}.test_import_sql_syntax_error), "TEST_SIMPLE_SQL_ADVANCED_BACKUP.test_import_sql_syntax_error")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ADVANCED_BACKUP}.test_export_import_null_values), "TEST_SIMPLE_SQL_ADVANCED_BACKUP.test_export_import_null_values")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ADVANCED_BACKUP}.test_export_empty_table), "TEST_SIMPLE_SQL_ADVANCED_BACKUP.test_export_empty_table")
		end

	run_test_simple_sql_audit
		local
			l_evaluator: EQA_TEST_EVALUATOR [TEST_SIMPLE_SQL_AUDIT]
		do
			create l_evaluator
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_AUDIT}.test_enable_auditing), "TEST_SIMPLE_SQL_AUDIT.test_enable_auditing")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_AUDIT}.test_disable_auditing), "TEST_SIMPLE_SQL_AUDIT.test_disable_auditing")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_AUDIT}.test_drop_audit_table), "TEST_SIMPLE_SQL_AUDIT.test_drop_audit_table")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_AUDIT}.test_insert_tracking), "TEST_SIMPLE_SQL_AUDIT.test_insert_tracking")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_AUDIT}.test_insert_tracking_new_values_json), "TEST_SIMPLE_SQL_AUDIT.test_insert_tracking_new_values_json")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_AUDIT}.test_update_tracking), "TEST_SIMPLE_SQL_AUDIT.test_update_tracking")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_AUDIT}.test_update_changed_fields), "TEST_SIMPLE_SQL_AUDIT.test_update_changed_fields")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_AUDIT}.test_update_multiple_fields), "TEST_SIMPLE_SQL_AUDIT.test_update_multiple_fields")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_AUDIT}.test_delete_tracking), "TEST_SIMPLE_SQL_AUDIT.test_delete_tracking")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_AUDIT}.test_get_changes_by_operation), "TEST_SIMPLE_SQL_AUDIT.test_get_changes_by_operation")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_AUDIT}.test_get_latest_changes), "TEST_SIMPLE_SQL_AUDIT.test_get_latest_changes")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_AUDIT}.test_get_changes_in_range), "TEST_SIMPLE_SQL_AUDIT.test_get_changes_in_range")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_AUDIT}.test_multiple_tables), "TEST_SIMPLE_SQL_AUDIT.test_multiple_tables")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_AUDIT}.test_audit_table_schema), "TEST_SIMPLE_SQL_AUDIT.test_audit_table_schema")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_AUDIT}.test_audit_full_lifecycle), "TEST_SIMPLE_SQL_AUDIT.test_audit_full_lifecycle")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_AUDIT}.test_audit_with_transaction_rollback), "TEST_SIMPLE_SQL_AUDIT.test_audit_with_transaction_rollback")
		end

	run_test_simple_sql_backup
		local
			l_evaluator: EQA_TEST_EVALUATOR [TEST_SIMPLE_SQL_BACKUP]
		do
			create l_evaluator
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_BACKUP}.test_backup_memory_to_file), "TEST_SIMPLE_SQL_BACKUP.test_backup_memory_to_file")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_BACKUP}.test_backup_file_to_memory), "TEST_SIMPLE_SQL_BACKUP.test_backup_file_to_memory")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_BACKUP}.test_round_trip_backup), "TEST_SIMPLE_SQL_BACKUP.test_round_trip_backup")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_BACKUP}.test_backup_with_null_values), "TEST_SIMPLE_SQL_BACKUP.test_backup_with_null_values")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_BACKUP}.test_backup_with_special_characters), "TEST_SIMPLE_SQL_BACKUP.test_backup_with_special_characters")
		end

	run_test_simple_sql_batch
		local
			l_evaluator: EQA_TEST_EVALUATOR [TEST_SIMPLE_SQL_BATCH]
		do
			create l_evaluator
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_BATCH}.test_batch_begin_commit), "TEST_SIMPLE_SQL_BATCH.test_batch_begin_commit")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_BATCH}.test_batch_rollback), "TEST_SIMPLE_SQL_BATCH.test_batch_rollback")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_BATCH}.test_batch_insert), "TEST_SIMPLE_SQL_BATCH.test_batch_insert")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_BATCH}.test_batch_insert_with_null), "TEST_SIMPLE_SQL_BATCH.test_batch_insert_with_null")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_BATCH}.test_batch_update), "TEST_SIMPLE_SQL_BATCH.test_batch_update")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_BATCH}.test_batch_delete), "TEST_SIMPLE_SQL_BATCH.test_batch_delete")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_BATCH}.test_insert_many), "TEST_SIMPLE_SQL_BATCH.test_insert_many")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_BATCH}.test_execute_many), "TEST_SIMPLE_SQL_BATCH.test_execute_many")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_BATCH}.test_mixed_batch_operations), "TEST_SIMPLE_SQL_BATCH.test_mixed_batch_operations")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_BATCH}.test_batch_escaping), "TEST_SIMPLE_SQL_BATCH.test_batch_escaping")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_BATCH}.test_insert_many_auto_transaction), "TEST_SIMPLE_SQL_BATCH.test_insert_many_auto_transaction")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_BATCH}.test_constraint_violation_batch), "TEST_SIMPLE_SQL_BATCH.test_constraint_violation_batch")
		end

	run_test_simple_sql_blob
		local
			l_evaluator: EQA_TEST_EVALUATOR [TEST_SIMPLE_SQL_BLOB]
		do
			create l_evaluator
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_BLOB}.test_blob_insert_and_retrieve), "TEST_SIMPLE_SQL_BLOB.test_blob_insert_and_retrieve")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_BLOB}.test_blob_bind_by_name), "TEST_SIMPLE_SQL_BLOB.test_blob_bind_by_name")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_BLOB}.test_blob_null_handling), "TEST_SIMPLE_SQL_BLOB.test_blob_null_handling")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_BLOB}.test_blob_from_file), "TEST_SIMPLE_SQL_BLOB.test_blob_from_file")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_BLOB}.test_blob_to_file), "TEST_SIMPLE_SQL_BLOB.test_blob_to_file")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_BLOB}.test_blob_large_data), "TEST_SIMPLE_SQL_BLOB.test_blob_large_data")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_BLOB}.test_blob_roundtrip_file_to_db_to_file), "TEST_SIMPLE_SQL_BLOB.test_blob_roundtrip_file_to_db_to_file")
		end

	run_test_simple_sql_error
		local
			l_evaluator: EQA_TEST_EVALUATOR [TEST_SIMPLE_SQL_ERROR]
		do
			create l_evaluator
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ERROR}.test_error_make), "TEST_SIMPLE_SQL_ERROR.test_error_make")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ERROR}.test_error_make_with_sql), "TEST_SIMPLE_SQL_ERROR.test_error_make_with_sql")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ERROR}.test_error_code_name), "TEST_SIMPLE_SQL_ERROR.test_error_code_name")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ERROR}.test_error_is_constraint_violation), "TEST_SIMPLE_SQL_ERROR.test_error_is_constraint_violation")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ERROR}.test_error_is_busy), "TEST_SIMPLE_SQL_ERROR.test_error_is_busy")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ERROR}.test_error_is_readonly), "TEST_SIMPLE_SQL_ERROR.test_error_is_readonly")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ERROR}.test_error_extended_code_unique), "TEST_SIMPLE_SQL_ERROR.test_error_extended_code_unique")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ERROR}.test_error_extended_code_primary_key), "TEST_SIMPLE_SQL_ERROR.test_error_extended_code_primary_key")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ERROR}.test_error_extended_code_foreign_key), "TEST_SIMPLE_SQL_ERROR.test_error_extended_code_foreign_key")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ERROR}.test_error_extended_code_not_null), "TEST_SIMPLE_SQL_ERROR.test_error_extended_code_not_null")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ERROR}.test_error_extended_code_check), "TEST_SIMPLE_SQL_ERROR.test_error_extended_code_check")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ERROR}.test_error_description), "TEST_SIMPLE_SQL_ERROR.test_error_description")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ERROR}.test_error_full_description_with_sql), "TEST_SIMPLE_SQL_ERROR.test_error_full_description_with_sql")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ERROR}.test_error_code_constants), "TEST_SIMPLE_SQL_ERROR.test_error_code_constants")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ERROR}.test_error_code_name_lookup), "TEST_SIMPLE_SQL_ERROR.test_error_code_name_lookup")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ERROR}.test_error_code_extended_name_lookup), "TEST_SIMPLE_SQL_ERROR.test_error_code_extended_name_lookup")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ERROR}.test_error_code_primary_code_extraction), "TEST_SIMPLE_SQL_ERROR.test_error_code_primary_code_extraction")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ERROR}.test_error_code_is_success), "TEST_SIMPLE_SQL_ERROR.test_error_code_is_success")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ERROR}.test_error_code_is_error), "TEST_SIMPLE_SQL_ERROR.test_error_code_is_error")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ERROR}.test_error_code_unknown), "TEST_SIMPLE_SQL_ERROR.test_error_code_unknown")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ERROR}.test_execute_malformed_sql), "TEST_SIMPLE_SQL_ERROR.test_execute_malformed_sql")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ERROR}.test_query_nonexistent_table), "TEST_SIMPLE_SQL_ERROR.test_query_nonexistent_table")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_ERROR}.test_query_nonexistent_column), "TEST_SIMPLE_SQL_ERROR.test_query_nonexistent_column")
		end

	run_test_simple_sql_fts5
		local
			l_evaluator: EQA_TEST_EVALUATOR [TEST_SIMPLE_SQL_FTS5]
		do
			create l_evaluator
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_FTS5}.test_is_fts5_available), "TEST_SIMPLE_SQL_FTS5.test_is_fts5_available")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_FTS5}.test_create_table), "TEST_SIMPLE_SQL_FTS5.test_create_table")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_FTS5}.test_create_table_with_options), "TEST_SIMPLE_SQL_FTS5.test_create_table_with_options")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_FTS5}.test_create_external_content_table), "TEST_SIMPLE_SQL_FTS5.test_create_external_content_table")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_FTS5}.test_drop_table), "TEST_SIMPLE_SQL_FTS5.test_drop_table")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_FTS5}.test_table_exists_false), "TEST_SIMPLE_SQL_FTS5.test_table_exists_false")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_FTS5}.test_insert), "TEST_SIMPLE_SQL_FTS5.test_insert")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_FTS5}.test_insert_multiple_rows), "TEST_SIMPLE_SQL_FTS5.test_insert_multiple_rows")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_FTS5}.test_delete), "TEST_SIMPLE_SQL_FTS5.test_delete")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_FTS5}.test_rebuild), "TEST_SIMPLE_SQL_FTS5.test_rebuild")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_FTS5}.test_optimize), "TEST_SIMPLE_SQL_FTS5.test_optimize")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_FTS5}.test_search_basic), "TEST_SIMPLE_SQL_FTS5.test_search_basic")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_FTS5}.test_search_ranked), "TEST_SIMPLE_SQL_FTS5.test_search_ranked")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_FTS5}.test_search_column), "TEST_SIMPLE_SQL_FTS5.test_search_column")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_FTS5}.test_search_with_snippets), "TEST_SIMPLE_SQL_FTS5.test_search_with_snippets")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_FTS5}.test_count_matches), "TEST_SIMPLE_SQL_FTS5.test_count_matches")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_FTS5}.test_search_special_characters), "TEST_SIMPLE_SQL_FTS5.test_search_special_characters")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_FTS5}.test_query_builder_basic_match), "TEST_SIMPLE_SQL_FTS5.test_query_builder_basic_match")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_FTS5}.test_query_builder_column_match), "TEST_SIMPLE_SQL_FTS5.test_query_builder_column_match")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_FTS5}.test_query_builder_phrase_match), "TEST_SIMPLE_SQL_FTS5.test_query_builder_phrase_match")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_FTS5}.test_query_builder_prefix_match), "TEST_SIMPLE_SQL_FTS5.test_query_builder_prefix_match")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_FTS5}.test_query_builder_boolean_match), "TEST_SIMPLE_SQL_FTS5.test_query_builder_boolean_match")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_FTS5}.test_query_builder_with_rank), "TEST_SIMPLE_SQL_FTS5.test_query_builder_with_rank")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_FTS5}.test_query_builder_with_snippets), "TEST_SIMPLE_SQL_FTS5.test_query_builder_with_snippets")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_FTS5}.test_query_builder_with_highlight), "TEST_SIMPLE_SQL_FTS5.test_query_builder_with_highlight")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_FTS5}.test_query_builder_order_by_rank), "TEST_SIMPLE_SQL_FTS5.test_query_builder_order_by_rank")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_FTS5}.test_query_builder_limit_offset), "TEST_SIMPLE_SQL_FTS5.test_query_builder_limit_offset")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_FTS5}.test_query_builder_select_columns), "TEST_SIMPLE_SQL_FTS5.test_query_builder_select_columns")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_FTS5}.test_query_builder_to_sql), "TEST_SIMPLE_SQL_FTS5.test_query_builder_to_sql")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_FTS5}.test_query_builder_count), "TEST_SIMPLE_SQL_FTS5.test_query_builder_count")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_FTS5}.test_query_builder_execute_cursor), "TEST_SIMPLE_SQL_FTS5.test_query_builder_execute_cursor")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_FTS5}.test_fts5_unicode_search), "TEST_SIMPLE_SQL_FTS5.test_fts5_unicode_search")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_FTS5}.test_fts5_very_long_document), "TEST_SIMPLE_SQL_FTS5.test_fts5_very_long_document")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_FTS5}.test_fts5_highlight_boundaries), "TEST_SIMPLE_SQL_FTS5.test_fts5_highlight_boundaries")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_FTS5}.test_fts5_snippet_no_match), "TEST_SIMPLE_SQL_FTS5.test_fts5_snippet_no_match")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_FTS5}.test_fts5_boolean_complex), "TEST_SIMPLE_SQL_FTS5.test_fts5_boolean_complex")
		end

	run_test_simple_sql_json
		local
			l_evaluator: EQA_TEST_EVALUATOR [TEST_SIMPLE_SQL_JSON]
		do
			create l_evaluator
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_JSON}.test_store_and_retrieve_json_object), "TEST_SIMPLE_SQL_JSON.test_store_and_retrieve_json_object")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_JSON}.test_json_array_storage), "TEST_SIMPLE_SQL_JSON.test_json_array_storage")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_JSON}.test_nested_json_structure), "TEST_SIMPLE_SQL_JSON.test_nested_json_structure")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_JSON}.test_json_with_null_values), "TEST_SIMPLE_SQL_JSON.test_json_with_null_values")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_JSON}.test_multiple_json_documents), "TEST_SIMPLE_SQL_JSON.test_multiple_json_documents")
		end

	run_test_simple_sql_json_advanced
		local
			l_evaluator: EQA_TEST_EVALUATOR [TEST_SIMPLE_SQL_JSON_ADVANCED]
		do
			create l_evaluator
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_JSON_ADVANCED}.test_json_validation_valid), "TEST_SIMPLE_SQL_JSON_ADVANCED.test_json_validation_valid")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_JSON_ADVANCED}.test_json_validation_invalid), "TEST_SIMPLE_SQL_JSON_ADVANCED.test_json_validation_invalid")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_JSON_ADVANCED}.test_json_type_root), "TEST_SIMPLE_SQL_JSON_ADVANCED.test_json_type_root")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_JSON_ADVANCED}.test_json_type_with_path), "TEST_SIMPLE_SQL_JSON_ADVANCED.test_json_type_with_path")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_JSON_ADVANCED}.test_extract_simple_paths), "TEST_SIMPLE_SQL_JSON_ADVANCED.test_extract_simple_paths")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_JSON_ADVANCED}.test_extract_array_element), "TEST_SIMPLE_SQL_JSON_ADVANCED.test_extract_array_element")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_JSON_ADVANCED}.test_extract_multiple_paths), "TEST_SIMPLE_SQL_JSON_ADVANCED.test_extract_multiple_paths")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_JSON_ADVANCED}.test_json_set_new_field), "TEST_SIMPLE_SQL_JSON_ADVANCED.test_json_set_new_field")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_JSON_ADVANCED}.test_json_set_existing_field), "TEST_SIMPLE_SQL_JSON_ADVANCED.test_json_set_existing_field")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_JSON_ADVANCED}.test_json_insert_new_field), "TEST_SIMPLE_SQL_JSON_ADVANCED.test_json_insert_new_field")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_JSON_ADVANCED}.test_json_insert_existing_field), "TEST_SIMPLE_SQL_JSON_ADVANCED.test_json_insert_existing_field")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_JSON_ADVANCED}.test_json_replace_existing_field), "TEST_SIMPLE_SQL_JSON_ADVANCED.test_json_replace_existing_field")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_JSON_ADVANCED}.test_json_replace_nonexistent_field), "TEST_SIMPLE_SQL_JSON_ADVANCED.test_json_replace_nonexistent_field")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_JSON_ADVANCED}.test_json_remove_field), "TEST_SIMPLE_SQL_JSON_ADVANCED.test_json_remove_field")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_JSON_ADVANCED}.test_json_array_creation), "TEST_SIMPLE_SQL_JSON_ADVANCED.test_json_array_creation")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_JSON_ADVANCED}.test_json_object_creation), "TEST_SIMPLE_SQL_JSON_ADVANCED.test_json_object_creation")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_JSON_ADVANCED}.test_aggregate_to_array), "TEST_SIMPLE_SQL_JSON_ADVANCED.test_aggregate_to_array")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_JSON_ADVANCED}.test_aggregate_to_array_with_where), "TEST_SIMPLE_SQL_JSON_ADVANCED.test_aggregate_to_array_with_where")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_JSON_ADVANCED}.test_aggregate_to_object), "TEST_SIMPLE_SQL_JSON_ADVANCED.test_aggregate_to_object")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_JSON_ADVANCED}.test_json_in_table_queries), "TEST_SIMPLE_SQL_JSON_ADVANCED.test_json_in_table_queries")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_JSON_ADVANCED}.test_json_modification_in_update), "TEST_SIMPLE_SQL_JSON_ADVANCED.test_json_modification_in_update")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_JSON_ADVANCED}.test_json_deeply_nested), "TEST_SIMPLE_SQL_JSON_ADVANCED.test_json_deeply_nested")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_JSON_ADVANCED}.test_json_array_of_arrays), "TEST_SIMPLE_SQL_JSON_ADVANCED.test_json_array_of_arrays")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_JSON_ADVANCED}.test_json_null_vs_missing), "TEST_SIMPLE_SQL_JSON_ADVANCED.test_json_null_vs_missing")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_JSON_ADVANCED}.test_json_numeric_precision), "TEST_SIMPLE_SQL_JSON_ADVANCED.test_json_numeric_precision")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_JSON_ADVANCED}.test_json_empty_object), "TEST_SIMPLE_SQL_JSON_ADVANCED.test_json_empty_object")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_JSON_ADVANCED}.test_json_empty_array), "TEST_SIMPLE_SQL_JSON_ADVANCED.test_json_empty_array")
		end

	run_test_simple_sql_migration
		local
			l_evaluator: EQA_TEST_EVALUATOR [TEST_SIMPLE_SQL_MIGRATION]
		do
			create l_evaluator
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_MIGRATION}.test_runner_initial_state), "TEST_SIMPLE_SQL_MIGRATION.test_runner_initial_state")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_MIGRATION}.test_runner_add_migrations), "TEST_SIMPLE_SQL_MIGRATION.test_runner_add_migrations")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_MIGRATION}.test_runner_sorted_order), "TEST_SIMPLE_SQL_MIGRATION.test_runner_sorted_order")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_MIGRATION}.test_migrate_all), "TEST_SIMPLE_SQL_MIGRATION.test_migrate_all")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_MIGRATION}.test_migrate_one), "TEST_SIMPLE_SQL_MIGRATION.test_migrate_one")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_MIGRATION}.test_migrate_to_version), "TEST_SIMPLE_SQL_MIGRATION.test_migrate_to_version")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_MIGRATION}.test_rollback), "TEST_SIMPLE_SQL_MIGRATION.test_rollback")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_MIGRATION}.test_rollback_all), "TEST_SIMPLE_SQL_MIGRATION.test_rollback_all")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_MIGRATION}.test_reset), "TEST_SIMPLE_SQL_MIGRATION.test_reset")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_MIGRATION}.test_has_version_check), "TEST_SIMPLE_SQL_MIGRATION.test_has_version_check")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_MIGRATION}.test_no_error_on_success), "TEST_SIMPLE_SQL_MIGRATION.test_no_error_on_success")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_MIGRATION}.test_migration_partial_failure), "TEST_SIMPLE_SQL_MIGRATION.test_migration_partial_failure")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_MIGRATION}.test_migration_version_skip), "TEST_SIMPLE_SQL_MIGRATION.test_migration_version_skip")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_MIGRATION}.test_migration_downgrade), "TEST_SIMPLE_SQL_MIGRATION.test_migration_downgrade")
		end

	run_test_simple_sql_pragma_config
		local
			l_evaluator: EQA_TEST_EVALUATOR [TEST_SIMPLE_SQL_PRAGMA_CONFIG]
		do
			create l_evaluator
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_PRAGMA_CONFIG}.test_make_default), "TEST_SIMPLE_SQL_PRAGMA_CONFIG.test_make_default")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_PRAGMA_CONFIG}.test_make_wal), "TEST_SIMPLE_SQL_PRAGMA_CONFIG.test_make_wal")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_PRAGMA_CONFIG}.test_make_performance), "TEST_SIMPLE_SQL_PRAGMA_CONFIG.test_make_performance")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_PRAGMA_CONFIG}.test_make_safe), "TEST_SIMPLE_SQL_PRAGMA_CONFIG.test_make_safe")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_PRAGMA_CONFIG}.test_make_custom), "TEST_SIMPLE_SQL_PRAGMA_CONFIG.test_make_custom")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_PRAGMA_CONFIG}.test_set_journal_mode), "TEST_SIMPLE_SQL_PRAGMA_CONFIG.test_set_journal_mode")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_PRAGMA_CONFIG}.test_set_synchronous), "TEST_SIMPLE_SQL_PRAGMA_CONFIG.test_set_synchronous")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_PRAGMA_CONFIG}.test_set_cache_size), "TEST_SIMPLE_SQL_PRAGMA_CONFIG.test_set_cache_size")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_PRAGMA_CONFIG}.test_set_busy_timeout), "TEST_SIMPLE_SQL_PRAGMA_CONFIG.test_set_busy_timeout")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_PRAGMA_CONFIG}.test_set_foreign_keys), "TEST_SIMPLE_SQL_PRAGMA_CONFIG.test_set_foreign_keys")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_PRAGMA_CONFIG}.test_set_mmap_size), "TEST_SIMPLE_SQL_PRAGMA_CONFIG.test_set_mmap_size")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_PRAGMA_CONFIG}.test_journal_mode_string), "TEST_SIMPLE_SQL_PRAGMA_CONFIG.test_journal_mode_string")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_PRAGMA_CONFIG}.test_synchronous_string), "TEST_SIMPLE_SQL_PRAGMA_CONFIG.test_synchronous_string")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_PRAGMA_CONFIG}.test_apply_to_database), "TEST_SIMPLE_SQL_PRAGMA_CONFIG.test_apply_to_database")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_PRAGMA_CONFIG}.test_apply_custom_config), "TEST_SIMPLE_SQL_PRAGMA_CONFIG.test_apply_custom_config")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_PRAGMA_CONFIG}.test_journal_mode_constants), "TEST_SIMPLE_SQL_PRAGMA_CONFIG.test_journal_mode_constants")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_PRAGMA_CONFIG}.test_synchronous_constants), "TEST_SIMPLE_SQL_PRAGMA_CONFIG.test_synchronous_constants")
		end

	run_test_simple_sql_prepared_statement
		local
			l_evaluator: EQA_TEST_EVALUATOR [TEST_SIMPLE_SQL_PREPARED_STATEMENT]
		do
			create l_evaluator
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_PREPARED_STATEMENT}.test_bind_integer_by_index), "TEST_SIMPLE_SQL_PREPARED_STATEMENT.test_bind_integer_by_index")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_PREPARED_STATEMENT}.test_bind_text_by_index), "TEST_SIMPLE_SQL_PREPARED_STATEMENT.test_bind_text_by_index")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_PREPARED_STATEMENT}.test_bind_real_by_index), "TEST_SIMPLE_SQL_PREPARED_STATEMENT.test_bind_real_by_index")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_PREPARED_STATEMENT}.test_bind_null_by_index), "TEST_SIMPLE_SQL_PREPARED_STATEMENT.test_bind_null_by_index")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_PREPARED_STATEMENT}.test_statement_reset), "TEST_SIMPLE_SQL_PREPARED_STATEMENT.test_statement_reset")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_PREPARED_STATEMENT}.test_query_with_parameters), "TEST_SIMPLE_SQL_PREPARED_STATEMENT.test_query_with_parameters")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_PREPARED_STATEMENT}.test_sql_injection_prevention), "TEST_SIMPLE_SQL_PREPARED_STATEMENT.test_sql_injection_prevention")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_PREPARED_STATEMENT}.test_multiple_parameters), "TEST_SIMPLE_SQL_PREPARED_STATEMENT.test_multiple_parameters")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_PREPARED_STATEMENT}.test_parameter_count), "TEST_SIMPLE_SQL_PREPARED_STATEMENT.test_parameter_count")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_PREPARED_STATEMENT}.test_is_query), "TEST_SIMPLE_SQL_PREPARED_STATEMENT.test_is_query")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_PREPARED_STATEMENT}.test_bind_wrong_type), "TEST_SIMPLE_SQL_PREPARED_STATEMENT.test_bind_wrong_type")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_PREPARED_STATEMENT}.test_bind_out_of_range), "TEST_SIMPLE_SQL_PREPARED_STATEMENT.test_bind_out_of_range")
		end

	run_test_simple_sql_query_builders
		local
			l_evaluator: EQA_TEST_EVALUATOR [TEST_SIMPLE_SQL_QUERY_BUILDERS]
		do
			create l_evaluator
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_QUERY_BUILDERS}.test_select_all), "TEST_SIMPLE_SQL_QUERY_BUILDERS.test_select_all")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_QUERY_BUILDERS}.test_select_columns), "TEST_SIMPLE_SQL_QUERY_BUILDERS.test_select_columns")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_QUERY_BUILDERS}.test_select_distinct), "TEST_SIMPLE_SQL_QUERY_BUILDERS.test_select_distinct")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_QUERY_BUILDERS}.test_select_where), "TEST_SIMPLE_SQL_QUERY_BUILDERS.test_select_where")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_QUERY_BUILDERS}.test_select_where_equals), "TEST_SIMPLE_SQL_QUERY_BUILDERS.test_select_where_equals")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_QUERY_BUILDERS}.test_select_and_where), "TEST_SIMPLE_SQL_QUERY_BUILDERS.test_select_and_where")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_QUERY_BUILDERS}.test_select_or_where), "TEST_SIMPLE_SQL_QUERY_BUILDERS.test_select_or_where")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_QUERY_BUILDERS}.test_select_order_by), "TEST_SIMPLE_SQL_QUERY_BUILDERS.test_select_order_by")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_QUERY_BUILDERS}.test_select_order_by_desc), "TEST_SIMPLE_SQL_QUERY_BUILDERS.test_select_order_by_desc")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_QUERY_BUILDERS}.test_select_limit_offset), "TEST_SIMPLE_SQL_QUERY_BUILDERS.test_select_limit_offset")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_QUERY_BUILDERS}.test_select_group_by), "TEST_SIMPLE_SQL_QUERY_BUILDERS.test_select_group_by")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_QUERY_BUILDERS}.test_select_join), "TEST_SIMPLE_SQL_QUERY_BUILDERS.test_select_join")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_QUERY_BUILDERS}.test_select_left_join), "TEST_SIMPLE_SQL_QUERY_BUILDERS.test_select_left_join")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_QUERY_BUILDERS}.test_select_execute), "TEST_SIMPLE_SQL_QUERY_BUILDERS.test_select_execute")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_QUERY_BUILDERS}.test_select_count), "TEST_SIMPLE_SQL_QUERY_BUILDERS.test_select_count")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_QUERY_BUILDERS}.test_select_exists), "TEST_SIMPLE_SQL_QUERY_BUILDERS.test_select_exists")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_QUERY_BUILDERS}.test_insert_to_sql), "TEST_SIMPLE_SQL_QUERY_BUILDERS.test_insert_to_sql")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_QUERY_BUILDERS}.test_insert_with_set), "TEST_SIMPLE_SQL_QUERY_BUILDERS.test_insert_with_set")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_QUERY_BUILDERS}.test_insert_execute), "TEST_SIMPLE_SQL_QUERY_BUILDERS.test_insert_execute")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_QUERY_BUILDERS}.test_insert_returning_id), "TEST_SIMPLE_SQL_QUERY_BUILDERS.test_insert_returning_id")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_QUERY_BUILDERS}.test_update_to_sql), "TEST_SIMPLE_SQL_QUERY_BUILDERS.test_update_to_sql")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_QUERY_BUILDERS}.test_update_multiple_columns), "TEST_SIMPLE_SQL_QUERY_BUILDERS.test_update_multiple_columns")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_QUERY_BUILDERS}.test_update_increment), "TEST_SIMPLE_SQL_QUERY_BUILDERS.test_update_increment")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_QUERY_BUILDERS}.test_update_decrement_by), "TEST_SIMPLE_SQL_QUERY_BUILDERS.test_update_decrement_by")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_QUERY_BUILDERS}.test_update_execute), "TEST_SIMPLE_SQL_QUERY_BUILDERS.test_update_execute")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_QUERY_BUILDERS}.test_delete_to_sql), "TEST_SIMPLE_SQL_QUERY_BUILDERS.test_delete_to_sql")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_QUERY_BUILDERS}.test_delete_with_and), "TEST_SIMPLE_SQL_QUERY_BUILDERS.test_delete_with_and")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_QUERY_BUILDERS}.test_delete_execute), "TEST_SIMPLE_SQL_QUERY_BUILDERS.test_delete_execute")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_QUERY_BUILDERS}.test_delete_execute_all), "TEST_SIMPLE_SQL_QUERY_BUILDERS.test_delete_execute_all")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_QUERY_BUILDERS}.test_select_reset), "TEST_SIMPLE_SQL_QUERY_BUILDERS.test_select_reset")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_QUERY_BUILDERS}.test_select_subquery), "TEST_SIMPLE_SQL_QUERY_BUILDERS.test_select_subquery")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_QUERY_BUILDERS}.test_select_join_multiple), "TEST_SIMPLE_SQL_QUERY_BUILDERS.test_select_join_multiple")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_QUERY_BUILDERS}.test_update_all_rows), "TEST_SIMPLE_SQL_QUERY_BUILDERS.test_update_all_rows")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_QUERY_BUILDERS}.test_delete_all_rows), "TEST_SIMPLE_SQL_QUERY_BUILDERS.test_delete_all_rows")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_QUERY_BUILDERS}.test_insert_default_values), "TEST_SIMPLE_SQL_QUERY_BUILDERS.test_insert_default_values")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_QUERY_BUILDERS}.test_select_group_having), "TEST_SIMPLE_SQL_QUERY_BUILDERS.test_select_group_having")
		end

	run_test_simple_sql_repository
		local
			l_evaluator: EQA_TEST_EVALUATOR [TEST_SIMPLE_SQL_REPOSITORY]
		do
			create l_evaluator
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_REPOSITORY}.test_find_all_empty), "TEST_SIMPLE_SQL_REPOSITORY.test_find_all_empty")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_REPOSITORY}.test_find_all_with_data), "TEST_SIMPLE_SQL_REPOSITORY.test_find_all_with_data")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_REPOSITORY}.test_find_all_ordered), "TEST_SIMPLE_SQL_REPOSITORY.test_find_all_ordered")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_REPOSITORY}.test_find_all_limited), "TEST_SIMPLE_SQL_REPOSITORY.test_find_all_limited")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_REPOSITORY}.test_find_by_id_exists), "TEST_SIMPLE_SQL_REPOSITORY.test_find_by_id_exists")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_REPOSITORY}.test_find_by_id_not_exists), "TEST_SIMPLE_SQL_REPOSITORY.test_find_by_id_not_exists")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_REPOSITORY}.test_exists), "TEST_SIMPLE_SQL_REPOSITORY.test_exists")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_REPOSITORY}.test_find_where), "TEST_SIMPLE_SQL_REPOSITORY.test_find_where")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_REPOSITORY}.test_find_where_ordered), "TEST_SIMPLE_SQL_REPOSITORY.test_find_where_ordered")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_REPOSITORY}.test_find_first_where), "TEST_SIMPLE_SQL_REPOSITORY.test_find_first_where")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_REPOSITORY}.test_count), "TEST_SIMPLE_SQL_REPOSITORY.test_count")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_REPOSITORY}.test_count_where), "TEST_SIMPLE_SQL_REPOSITORY.test_count_where")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_REPOSITORY}.test_insert), "TEST_SIMPLE_SQL_REPOSITORY.test_insert")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_REPOSITORY}.test_insert_multiple), "TEST_SIMPLE_SQL_REPOSITORY.test_insert_multiple")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_REPOSITORY}.test_update), "TEST_SIMPLE_SQL_REPOSITORY.test_update")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_REPOSITORY}.test_update_nonexistent), "TEST_SIMPLE_SQL_REPOSITORY.test_update_nonexistent")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_REPOSITORY}.test_update_where), "TEST_SIMPLE_SQL_REPOSITORY.test_update_where")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_REPOSITORY}.test_delete), "TEST_SIMPLE_SQL_REPOSITORY.test_delete")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_REPOSITORY}.test_delete_nonexistent), "TEST_SIMPLE_SQL_REPOSITORY.test_delete_nonexistent")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_REPOSITORY}.test_delete_where), "TEST_SIMPLE_SQL_REPOSITORY.test_delete_where")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_REPOSITORY}.test_delete_all), "TEST_SIMPLE_SQL_REPOSITORY.test_delete_all")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_REPOSITORY}.test_save_new_entity), "TEST_SIMPLE_SQL_REPOSITORY.test_save_new_entity")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_REPOSITORY}.test_save_existing_entity), "TEST_SIMPLE_SQL_REPOSITORY.test_save_existing_entity")
		end

	run_test_simple_sql_schema
		local
			l_evaluator: EQA_TEST_EVALUATOR [TEST_SIMPLE_SQL_SCHEMA]
		do
			create l_evaluator
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_SCHEMA}.test_tables_list), "TEST_SIMPLE_SQL_SCHEMA.test_tables_list")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_SCHEMA}.test_table_exists), "TEST_SIMPLE_SQL_SCHEMA.test_table_exists")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_SCHEMA}.test_views_list), "TEST_SIMPLE_SQL_SCHEMA.test_views_list")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_SCHEMA}.test_column_names), "TEST_SIMPLE_SQL_SCHEMA.test_column_names")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_SCHEMA}.test_columns_info), "TEST_SIMPLE_SQL_SCHEMA.test_columns_info")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_SCHEMA}.test_table_info), "TEST_SIMPLE_SQL_SCHEMA.test_table_info")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_SCHEMA}.test_indexes), "TEST_SIMPLE_SQL_SCHEMA.test_indexes")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_SCHEMA}.test_foreign_keys), "TEST_SIMPLE_SQL_SCHEMA.test_foreign_keys")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_SCHEMA}.test_user_version), "TEST_SIMPLE_SQL_SCHEMA.test_user_version")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_SCHEMA}.test_schema_version), "TEST_SIMPLE_SQL_SCHEMA.test_schema_version")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_SCHEMA}.test_column_info_description), "TEST_SIMPLE_SQL_SCHEMA.test_column_info_description")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_SCHEMA}.test_schema_after_alter), "TEST_SIMPLE_SQL_SCHEMA.test_schema_after_alter")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_SCHEMA}.test_schema_foreign_keys_introspection), "TEST_SIMPLE_SQL_SCHEMA.test_schema_foreign_keys_introspection")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_SCHEMA}.test_schema_indexes_introspection), "TEST_SIMPLE_SQL_SCHEMA.test_schema_indexes_introspection")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_SCHEMA}.test_schema_views_introspection), "TEST_SIMPLE_SQL_SCHEMA.test_schema_views_introspection")
		end

	run_test_simple_sql_streaming
		local
			l_evaluator: EQA_TEST_EVALUATOR [TEST_SIMPLE_SQL_STREAMING]
		do
			create l_evaluator
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_STREAMING}.test_cursor_basic_iteration), "TEST_SIMPLE_SQL_STREAMING.test_cursor_basic_iteration")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_STREAMING}.test_cursor_across_syntax), "TEST_SIMPLE_SQL_STREAMING.test_cursor_across_syntax")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_STREAMING}.test_cursor_row_access), "TEST_SIMPLE_SQL_STREAMING.test_cursor_row_access")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_STREAMING}.test_cursor_empty_result), "TEST_SIMPLE_SQL_STREAMING.test_cursor_empty_result")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_STREAMING}.test_cursor_rows_fetched), "TEST_SIMPLE_SQL_STREAMING.test_cursor_rows_fetched")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_STREAMING}.test_stream_for_each), "TEST_SIMPLE_SQL_STREAMING.test_stream_for_each")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_STREAMING}.test_stream_for_each_do), "TEST_SIMPLE_SQL_STREAMING.test_stream_for_each_do")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_STREAMING}.test_stream_early_stop), "TEST_SIMPLE_SQL_STREAMING.test_stream_early_stop")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_STREAMING}.test_stream_collect_first), "TEST_SIMPLE_SQL_STREAMING.test_stream_collect_first")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_STREAMING}.test_stream_count_rows), "TEST_SIMPLE_SQL_STREAMING.test_stream_count_rows")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_STREAMING}.test_stream_first_row), "TEST_SIMPLE_SQL_STREAMING.test_stream_first_row")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_STREAMING}.test_stream_exists), "TEST_SIMPLE_SQL_STREAMING.test_stream_exists")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_STREAMING}.test_database_query_stream), "TEST_SIMPLE_SQL_STREAMING.test_database_query_stream")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_STREAMING}.test_prepared_statement_cursor), "TEST_SIMPLE_SQL_STREAMING.test_prepared_statement_cursor")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_STREAMING}.test_prepared_statement_stream), "TEST_SIMPLE_SQL_STREAMING.test_prepared_statement_stream")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_STREAMING}.test_select_builder_cursor), "TEST_SIMPLE_SQL_STREAMING.test_select_builder_cursor")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_STREAMING}.test_select_builder_for_each), "TEST_SIMPLE_SQL_STREAMING.test_select_builder_for_each")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_STREAMING}.test_cursor_large_dataset), "TEST_SIMPLE_SQL_STREAMING.test_cursor_large_dataset")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_STREAMING}.test_stream_aggregate_large_dataset), "TEST_SIMPLE_SQL_STREAMING.test_stream_aggregate_large_dataset")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_STREAMING}.test_cursor_large_result), "TEST_SIMPLE_SQL_STREAMING.test_cursor_large_result")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_STREAMING}.test_cursor_early_termination), "TEST_SIMPLE_SQL_STREAMING.test_cursor_early_termination")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_STREAMING}.test_stream_callback_exception), "TEST_SIMPLE_SQL_STREAMING.test_stream_callback_exception")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_STREAMING}.test_stream_memory_stability), "TEST_SIMPLE_SQL_STREAMING.test_stream_memory_stability")
		end

	run_test_simple_sql_vector
		local
			l_evaluator: EQA_TEST_EVALUATOR [TEST_SIMPLE_SQL_VECTOR]
		do
			create l_evaluator
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_VECTOR}.test_vector_from_array), "TEST_SIMPLE_SQL_VECTOR.test_vector_from_array")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_VECTOR}.test_vector_zero), "TEST_SIMPLE_SQL_VECTOR.test_vector_zero")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_VECTOR}.test_vector_blob_roundtrip), "TEST_SIMPLE_SQL_VECTOR.test_vector_blob_roundtrip")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_VECTOR}.test_vector_magnitude), "TEST_SIMPLE_SQL_VECTOR.test_vector_magnitude")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_VECTOR}.test_vector_dot_product), "TEST_SIMPLE_SQL_VECTOR.test_vector_dot_product")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_VECTOR}.test_vector_normalized), "TEST_SIMPLE_SQL_VECTOR.test_vector_normalized")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_VECTOR}.test_vector_add_subtract), "TEST_SIMPLE_SQL_VECTOR.test_vector_add_subtract")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_VECTOR}.test_vector_scale), "TEST_SIMPLE_SQL_VECTOR.test_vector_scale")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_VECTOR}.test_cosine_similarity_identical), "TEST_SIMPLE_SQL_VECTOR.test_cosine_similarity_identical")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_VECTOR}.test_cosine_similarity_orthogonal), "TEST_SIMPLE_SQL_VECTOR.test_cosine_similarity_orthogonal")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_VECTOR}.test_cosine_similarity_opposite), "TEST_SIMPLE_SQL_VECTOR.test_cosine_similarity_opposite")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_VECTOR}.test_euclidean_distance), "TEST_SIMPLE_SQL_VECTOR.test_euclidean_distance")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_VECTOR}.test_manhattan_distance), "TEST_SIMPLE_SQL_VECTOR.test_manhattan_distance")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_VECTOR}.test_is_similar), "TEST_SIMPLE_SQL_VECTOR.test_is_similar")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_VECTOR}.test_store_insert_and_retrieve), "TEST_SIMPLE_SQL_VECTOR.test_store_insert_and_retrieve")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_VECTOR}.test_store_with_metadata), "TEST_SIMPLE_SQL_VECTOR.test_store_with_metadata")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_VECTOR}.test_store_update), "TEST_SIMPLE_SQL_VECTOR.test_store_update")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_VECTOR}.test_store_delete), "TEST_SIMPLE_SQL_VECTOR.test_store_delete")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_VECTOR}.test_store_count), "TEST_SIMPLE_SQL_VECTOR.test_store_count")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_VECTOR}.test_find_nearest), "TEST_SIMPLE_SQL_VECTOR.test_find_nearest")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_VECTOR}.test_find_within_threshold), "TEST_SIMPLE_SQL_VECTOR.test_find_within_threshold")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_VECTOR}.test_find_nearest_euclidean), "TEST_SIMPLE_SQL_VECTOR.test_find_nearest_euclidean")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_VECTOR}.test_vector_near_zero), "TEST_SIMPLE_SQL_VECTOR.test_vector_near_zero")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_VECTOR}.test_vector_zero_magnitude), "TEST_SIMPLE_SQL_VECTOR.test_vector_zero_magnitude")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_VECTOR}.test_vector_large_values), "TEST_SIMPLE_SQL_VECTOR.test_vector_large_values")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_VECTOR}.test_vector_negative_values), "TEST_SIMPLE_SQL_VECTOR.test_vector_negative_values")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_VECTOR}.test_similarity_identical_vectors_exact), "TEST_SIMPLE_SQL_VECTOR.test_similarity_identical_vectors_exact")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_VECTOR}.test_similarity_opposite_vectors_exact), "TEST_SIMPLE_SQL_VECTOR.test_similarity_opposite_vectors_exact")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_VECTOR}.test_knn_tie_breaking), "TEST_SIMPLE_SQL_VECTOR.test_knn_tie_breaking")
			report (l_evaluator.execute (agent {TEST_SIMPLE_SQL_VECTOR}.test_vector_store_large_batch), "TEST_SIMPLE_SQL_VECTOR.test_vector_store_large_batch")
		end



feature {NONE} -- Implementation

	report (a_result: EQA_PARTIAL_RESULT; a_name: STRING)
			-- Count and print `a_result' of test `a_name'.
		do
			if a_result.is_pass then
				print ("  PASS: " + a_name + "%N")
				passed := passed + 1
			else
				print ("  FAIL: " + a_name + " [" + {UTF_CONVERTER}.string_32_to_utf_8_string_8 (a_result.tag) + "]%N")
				failed := failed + 1
			end
		end

end
