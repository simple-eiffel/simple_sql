note
	description: "Test application root class for dms tests: runs every test through EQA_TEST_EVALUATOR"
	date: "$Date$"
	revision: "$Revision$"

class
	APPLICATION

create
	make

feature -- Initialization

	make
			-- Run every dms test and print a summary.
		do
			run_test_dms_app
			run_test_dms_stress
			print ("%N========================%N")
			print ("Results: " + passed.out + " passed, " + failed.out + " failed%N")
		end

feature {NONE} -- Runners

	run_test_dms_app
		local
			l_eval: EQA_TEST_EVALUATOR [TEST_DMS_APP]
		do
			create l_eval
			report ("TEST_DMS_APP.test_create_user", l_eval.execute (agent {TEST_DMS_APP}.test_create_user))
			report ("TEST_DMS_APP.test_find_user", l_eval.execute (agent {TEST_DMS_APP}.test_find_user))
			report ("TEST_DMS_APP.test_find_user_by_username", l_eval.execute (agent {TEST_DMS_APP}.test_find_user_by_username))
			report ("TEST_DMS_APP.test_all_users", l_eval.execute (agent {TEST_DMS_APP}.test_all_users))
			report ("TEST_DMS_APP.test_soft_delete_user", l_eval.execute (agent {TEST_DMS_APP}.test_soft_delete_user))
			report ("TEST_DMS_APP.test_restore_user", l_eval.execute (agent {TEST_DMS_APP}.test_restore_user))
			report ("TEST_DMS_APP.test_update_user", l_eval.execute (agent {TEST_DMS_APP}.test_update_user))
			report ("TEST_DMS_APP.test_user_count", l_eval.execute (agent {TEST_DMS_APP}.test_user_count))
			report ("TEST_DMS_APP.test_create_folder", l_eval.execute (agent {TEST_DMS_APP}.test_create_folder))
			report ("TEST_DMS_APP.test_folder_hierarchy", l_eval.execute (agent {TEST_DMS_APP}.test_folder_hierarchy))
			report ("TEST_DMS_APP.test_folder_children", l_eval.execute (agent {TEST_DMS_APP}.test_folder_children))
			report ("TEST_DMS_APP.test_folder_descendants", l_eval.execute (agent {TEST_DMS_APP}.test_folder_descendants))
			report ("TEST_DMS_APP.test_soft_delete_folder", l_eval.execute (agent {TEST_DMS_APP}.test_soft_delete_folder))
			report ("TEST_DMS_APP.test_folder_count", l_eval.execute (agent {TEST_DMS_APP}.test_folder_count))
			report ("TEST_DMS_APP.test_create_document", l_eval.execute (agent {TEST_DMS_APP}.test_create_document))
			report ("TEST_DMS_APP.test_find_document", l_eval.execute (agent {TEST_DMS_APP}.test_find_document))
			report ("TEST_DMS_APP.test_folder_documents", l_eval.execute (agent {TEST_DMS_APP}.test_folder_documents))
			report ("TEST_DMS_APP.test_update_document_creates_version", l_eval.execute (agent {TEST_DMS_APP}.test_update_document_creates_version))
			report ("TEST_DMS_APP.test_document_versions", l_eval.execute (agent {TEST_DMS_APP}.test_document_versions))
			report ("TEST_DMS_APP.test_restore_document_version", l_eval.execute (agent {TEST_DMS_APP}.test_restore_document_version))
			report ("TEST_DMS_APP.test_soft_delete_document", l_eval.execute (agent {TEST_DMS_APP}.test_soft_delete_document))
			report ("TEST_DMS_APP.test_restore_document", l_eval.execute (agent {TEST_DMS_APP}.test_restore_document))
			report ("TEST_DMS_APP.test_document_count", l_eval.execute (agent {TEST_DMS_APP}.test_document_count))
			report ("TEST_DMS_APP.test_add_comment", l_eval.execute (agent {TEST_DMS_APP}.test_add_comment))
			report ("TEST_DMS_APP.test_reply_to_comment", l_eval.execute (agent {TEST_DMS_APP}.test_reply_to_comment))
			report ("TEST_DMS_APP.test_document_comments", l_eval.execute (agent {TEST_DMS_APP}.test_document_comments))
			report ("TEST_DMS_APP.test_document_comments_with_users", l_eval.execute (agent {TEST_DMS_APP}.test_document_comments_with_users))
			report ("TEST_DMS_APP.test_comment_count", l_eval.execute (agent {TEST_DMS_APP}.test_comment_count))
			report ("TEST_DMS_APP.test_create_tag", l_eval.execute (agent {TEST_DMS_APP}.test_create_tag))
			report ("TEST_DMS_APP.test_user_tags", l_eval.execute (agent {TEST_DMS_APP}.test_user_tags))
			report ("TEST_DMS_APP.test_tag_document", l_eval.execute (agent {TEST_DMS_APP}.test_tag_document))
			report ("TEST_DMS_APP.test_documents_with_tag", l_eval.execute (agent {TEST_DMS_APP}.test_documents_with_tag))
			report ("TEST_DMS_APP.test_untag_document", l_eval.execute (agent {TEST_DMS_APP}.test_untag_document))
			report ("TEST_DMS_APP.test_share_document", l_eval.execute (agent {TEST_DMS_APP}.test_share_document))
			report ("TEST_DMS_APP.test_documents_shared_with_user", l_eval.execute (agent {TEST_DMS_APP}.test_documents_shared_with_user))
			report ("TEST_DMS_APP.test_can_user_access_document", l_eval.execute (agent {TEST_DMS_APP}.test_can_user_access_document))
			report ("TEST_DMS_APP.test_revoke_share", l_eval.execute (agent {TEST_DMS_APP}.test_revoke_share))
			report ("TEST_DMS_APP.test_search_documents", l_eval.execute (agent {TEST_DMS_APP}.test_search_documents))
			report ("TEST_DMS_APP.test_search_with_snippets", l_eval.execute (agent {TEST_DMS_APP}.test_search_with_snippets))
			report ("TEST_DMS_APP.test_documents_paginated", l_eval.execute (agent {TEST_DMS_APP}.test_documents_paginated))
			report ("TEST_DMS_APP.test_activity_feed_paginated", l_eval.execute (agent {TEST_DMS_APP}.test_activity_feed_paginated))
			report ("TEST_DMS_APP.test_entity_audit_trail", l_eval.execute (agent {TEST_DMS_APP}.test_entity_audit_trail))
			report ("TEST_DMS_APP.test_user_activity", l_eval.execute (agent {TEST_DMS_APP}.test_user_activity))
			report ("TEST_DMS_APP.test_audit_log_count", l_eval.execute (agent {TEST_DMS_APP}.test_audit_log_count))
			report ("TEST_DMS_APP.test_trash_count", l_eval.execute (agent {TEST_DMS_APP}.test_trash_count))
			report ("TEST_DMS_APP.test_schema_version", l_eval.execute (agent {TEST_DMS_APP}.test_schema_version))
		end

	run_test_dms_stress
		local
			l_eval: EQA_TEST_EVALUATOR [TEST_DMS_STRESS]
		do
			create l_eval
			report ("TEST_DMS_STRESS.test_many_users", l_eval.execute (agent {TEST_DMS_STRESS}.test_many_users))
			report ("TEST_DMS_STRESS.test_many_documents", l_eval.execute (agent {TEST_DMS_STRESS}.test_many_documents))
			report ("TEST_DMS_STRESS.test_many_folders_deep_hierarchy", l_eval.execute (agent {TEST_DMS_STRESS}.test_many_folders_deep_hierarchy))
			report ("TEST_DMS_STRESS.test_many_comments_on_document", l_eval.execute (agent {TEST_DMS_STRESS}.test_many_comments_on_document))
			report ("TEST_DMS_STRESS.test_many_document_versions", l_eval.execute (agent {TEST_DMS_STRESS}.test_many_document_versions))
			report ("TEST_DMS_STRESS.test_many_tags_per_document", l_eval.execute (agent {TEST_DMS_STRESS}.test_many_tags_per_document))
			report ("TEST_DMS_STRESS.test_n_plus_1_comments_without_users", l_eval.execute (agent {TEST_DMS_STRESS}.test_n_plus_1_comments_without_users))
			report ("TEST_DMS_STRESS.test_n_plus_1_solution_with_eager_loading", l_eval.execute (agent {TEST_DMS_STRESS}.test_n_plus_1_solution_with_eager_loading))
			report ("TEST_DMS_STRESS.test_n_plus_1_documents_with_tags", l_eval.execute (agent {TEST_DMS_STRESS}.test_n_plus_1_documents_with_tags))
			report ("TEST_DMS_STRESS.test_delete_folder_cascade", l_eval.execute (agent {TEST_DMS_STRESS}.test_delete_folder_cascade))
			report ("TEST_DMS_STRESS.test_trash_isolation_between_users", l_eval.execute (agent {TEST_DMS_STRESS}.test_trash_isolation_between_users))
			report ("TEST_DMS_STRESS.test_pagination_empty_results", l_eval.execute (agent {TEST_DMS_STRESS}.test_pagination_empty_results))
			report ("TEST_DMS_STRESS.test_pagination_last_page", l_eval.execute (agent {TEST_DMS_STRESS}.test_pagination_last_page))
			report ("TEST_DMS_STRESS.test_search_no_results", l_eval.execute (agent {TEST_DMS_STRESS}.test_search_no_results))
			report ("TEST_DMS_STRESS.test_search_does_not_find_deleted", l_eval.execute (agent {TEST_DMS_STRESS}.test_search_does_not_find_deleted))
			report ("TEST_DMS_STRESS.test_audit_captures_all_operations", l_eval.execute (agent {TEST_DMS_STRESS}.test_audit_captures_all_operations))
			report ("TEST_DMS_STRESS.test_multi_user_document_collaboration", l_eval.execute (agent {TEST_DMS_STRESS}.test_multi_user_document_collaboration))
			report ("TEST_DMS_STRESS.test_documents_by_multiple_tags", l_eval.execute (agent {TEST_DMS_STRESS}.test_documents_by_multiple_tags))
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
