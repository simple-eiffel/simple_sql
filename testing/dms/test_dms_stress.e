note
	description: "Stress tests for DMS_APP - N+1 problems, high volume, and performance scenarios"
	testing: "covers"
	testing: "execution/serial"

class
	TEST_DMS_STRESS

inherit
	TEST_SET_BASE

feature -- Test routines: High Volume

	test_many_users
			-- Test creating many users.
		local
			l_app: DMS_APP
			l_ignored: DMS_USER
			i: INTEGER
		do
			create l_app.make

			from i := 1 until i > 100 loop
				l_ignored := l_app.create_user ("user" + i.out, "user" + i.out + "@example.com", "User " + i.out)
				i := i + 1
			end

			assert_equal ("100_users", 100, l_app.user_count)

			l_app.close
		end

	test_many_documents
			-- Test creating many documents.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_ignored: DMS_DOCUMENT
			i: INTEGER
		do
			create l_app.make
			l_user := l_app.create_user ("manydocs", "manydocs@example.com", "Many Docs")

			if attached l_app.user_root_folder (l_user.id) as l_root then
				from i := 1 until i > 200 loop
					l_ignored := l_app.create_document (l_user.id, l_root.id, "Document " + i.out, "Content for document " + i.out)
					i := i + 1
				end

				assert_equal ("200_docs", 200, l_app.document_count (l_user.id))
			end

			l_app.close
		end

	test_many_folders_deep_hierarchy
			-- Test deep folder hierarchy.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_current_folder: DMS_FOLDER
			i: INTEGER
		do
			create l_app.make
			l_user := l_app.create_user ("deepfolders", "deepfolders@example.com", "Deep Folders")

			if attached l_app.user_root_folder (l_user.id) as l_root then
				l_current_folder := l_root
				from i := 1 until i > 20 loop
					l_current_folder := l_app.create_folder (l_user.id, l_current_folder.id, "Level" + i.out)
					i := i + 1
				end

				-- Should have root + 20 levels
				assert_equal ("21_folders", 21, l_app.folder_count (l_user.id))
				-- Check deepest folder has correct depth
				assert_equal ("depth_20", 20, l_current_folder.depth)
			end

			l_app.close
		end

	test_many_comments_on_document
			-- Test many comments on a single document.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_doc: DMS_DOCUMENT
			l_ignored: DMS_COMMENT
			i: INTEGER
		do
			create l_app.make
			l_user := l_app.create_user ("manycomments", "manycomments@example.com", "Many Comments")

			if attached l_app.user_root_folder (l_user.id) as l_root then
				l_doc := l_app.create_document (l_user.id, l_root.id, "Commented Doc", "Content")

				from i := 1 until i > 100 loop
					l_ignored := l_app.add_comment (l_doc.id, l_user.id, "Comment number " + i.out)
					i := i + 1
				end

				assert_equal ("100_comments", 100, l_app.comment_count (l_doc.id))
			end

			l_app.close
		end

	test_many_document_versions
			-- Test many versions of a document.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_doc: DMS_DOCUMENT
			l_found: detachable DMS_DOCUMENT
			i: INTEGER
		do
			create l_app.make
			l_user := l_app.create_user ("manyversions", "manyversions@example.com", "Many Versions")

			if attached l_app.user_root_folder (l_user.id) as l_root then
				l_doc := l_app.create_document (l_user.id, l_root.id, "Versioned", "Version 1")

				from i := 2 until i > 50 loop
					l_app.update_document (l_doc.id, "Versioned", "Version " + i.out, l_user.id, "Update " + i.out)
					i := i + 1
				end

				l_found := l_app.find_document (l_doc.id)
				if attached l_found as f then
					assert_equal ("version_50", 50, f.current_version)
				end
				assert_equal ("50_versions", 50, l_app.version_count (l_doc.id))
			end

			l_app.close
		end

	test_many_tags_per_document
			-- Test document with many tags.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_doc: DMS_DOCUMENT
			l_tag: DMS_TAG
			i: INTEGER
		do
			create l_app.make
			l_user := l_app.create_user ("manytags", "manytags@example.com", "Many Tags")

			if attached l_app.user_root_folder (l_user.id) as l_root then
				l_doc := l_app.create_document (l_user.id, l_root.id, "Tagged Doc", "Content")

				from i := 1 until i > 30 loop
					l_tag := l_app.create_tag (l_user.id, "tag" + i.out)
					l_app.tag_document (l_doc.id, l_tag.id, l_user.id)
					i := i + 1
				end

				assert_equal ("30_tags", 30, l_app.document_tags (l_doc.id).count)
			end

			l_app.close
		end

feature -- Test routines: N+1 Problem Exposure

	test_n_plus_1_comments_without_users
			-- Test N+1 problem: fetching comments without user names.
			-- This would require N additional queries to get user names.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_doc: DMS_DOCUMENT
			l_comments: ARRAYED_LIST [DMS_COMMENT]
			l_ignored: DMS_COMMENT
			i: INTEGER
		do
			create l_app.make
			l_user := l_app.create_user ("n1user", "n1@example.com", "N+1 User")

			if attached l_app.user_root_folder (l_user.id) as l_root then
				l_doc := l_app.create_document (l_user.id, l_root.id, "N+1 Doc", "Content")

				from i := 1 until i > 20 loop
					l_ignored := l_app.add_comment (l_doc.id, l_user.id, "Comment " + i.out)
					i := i + 1
				end

				-- This fetches comments but NOT user names
				l_comments := l_app.document_comments (l_doc.id)
				assert_equal ("20_comments", 20, l_comments.count)
				-- Each comment would need a separate query for user name
				-- Without eager loading, displaying "John said: ..." requires 20 queries!
				assert ("no_cached_name", not attached l_comments.first.cached_user_display_name)
			end

			l_app.close
		end

	test_n_plus_1_solution_with_eager_loading
			-- Test N+1 solution using JOIN to fetch users.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_doc: DMS_DOCUMENT
			l_comments: ARRAYED_LIST [DMS_COMMENT]
			l_ignored: DMS_COMMENT
			i: INTEGER
		do
			create l_app.make
			l_user := l_app.create_user ("eageruser", "eager@example.com", "Eager User")

			if attached l_app.user_root_folder (l_user.id) as l_root then
				l_doc := l_app.create_document (l_user.id, l_root.id, "Eager Doc", "Content")

				from i := 1 until i > 20 loop
					l_ignored := l_app.add_comment (l_doc.id, l_user.id, "Comment " + i.out)
					i := i + 1
				end

				-- This fetches comments WITH user names in one query
				l_comments := l_app.document_comments_with_users (l_doc.id)
				assert_equal ("20_comments", 20, l_comments.count)
				-- All comments have cached user names
				assert ("has_cached_name", attached l_comments.first.cached_user_display_name)
				across l_comments as ic loop
					assert ("all_have_names", attached ic.cached_user_display_name)
				end
			end

			l_app.close
		end

	test_n_plus_1_documents_with_tags
			-- Test N+1 when fetching documents with their tags.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_docs: ARRAYED_LIST [DMS_DOCUMENT]
			l_doc: DMS_DOCUMENT
			l_tag: DMS_TAG
			i: INTEGER
		do
			create l_app.make
			l_user := l_app.create_user ("doctagsuser", "doctags@example.com", "Doc Tags User")

			if attached l_app.user_root_folder (l_user.id) as l_root then
				l_tag := l_app.create_tag (l_user.id, "common")

				from i := 1 until i > 10 loop
					l_doc := l_app.create_document (l_user.id, l_root.id, "Doc " + i.out, "Content " + i.out)
					l_app.tag_document (l_doc.id, l_tag.id, l_user.id)
					i := i + 1
				end

				l_docs := l_app.folder_documents (l_root.id)
				assert_equal ("10_docs", 10, l_docs.count)
				-- To display tags for each document, we need 10 more queries!
				-- This is the N+1 problem for many-to-many relationships
			end

			l_app.close
		end

feature -- Test routines: Soft Delete Edge Cases

	test_delete_folder_cascade
			-- Test that deleting folder cascades to subfolders and documents.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_parent, l_child: DMS_FOLDER
			l_ignored: DMS_DOCUMENT
		do
			create l_app.make
			l_user := l_app.create_user ("cascadeuser", "cascade@example.com", "Cascade User")

			if attached l_app.user_root_folder (l_user.id) as l_root then
				l_parent := l_app.create_folder (l_user.id, l_root.id, "Parent")
				l_child := l_app.create_folder (l_user.id, l_parent.id, "Child")
				l_ignored := l_app.create_document (l_user.id, l_child.id, "Nested Doc", "Content")

				-- Verify setup
				assert_equal ("one_doc", 1, l_app.folder_documents (l_child.id).count)

				-- Delete parent folder
				l_app.soft_delete_folder (l_parent.id, l_user.id)

				-- Both folders and document should be deleted
				if attached l_app.find_folder (l_child.id) as f then
					assert ("child_deleted", f.is_deleted)
				end
				assert_equal ("doc_deleted", 0, l_app.folder_documents (l_child.id).count)
			end

			l_app.close
		end

	test_trash_isolation_between_users
			-- Test that trash is isolated between users.
		local
			l_app: DMS_APP
			l_user1, l_user2: DMS_USER
			l_doc1, l_doc2: DMS_DOCUMENT
		do
			create l_app.make
			l_user1 := l_app.create_user ("trashuser1", "trash1@example.com", "Trash User 1")
			l_user2 := l_app.create_user ("trashuser2", "trash2@example.com", "Trash User 2")

			if attached l_app.user_root_folder (l_user1.id) as l_root1 then
				if attached l_app.user_root_folder (l_user2.id) as l_root2 then
					l_doc1 := l_app.create_document (l_user1.id, l_root1.id, "User1 Doc", "Content")
					l_doc2 := l_app.create_document (l_user2.id, l_root2.id, "User2 Doc", "Content")

					l_app.soft_delete_document (l_doc1.id, l_user1.id)

					assert_equal ("user1_trash", 1, l_app.trashed_documents (l_user1.id).count)
					assert_equal ("user2_no_trash", 0, l_app.trashed_documents (l_user2.id).count)
				end
			end

			l_app.close
		end

feature -- Test routines: Pagination Edge Cases

	test_pagination_empty_results
			-- Test pagination with no results.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_page: TUPLE [documents: ARRAYED_LIST [DMS_DOCUMENT]; next_cursor: detachable STRING_8]
		do
			create l_app.make
			l_user := l_app.create_user ("emptypage", "emptypage@example.com", "Empty Page")

			l_page := l_app.documents_paginated (l_user.id, Void, 10)
			assert_equal ("empty", 0, l_page.documents.count)
			assert ("no_cursor", not attached l_page.next_cursor)

			l_app.close
		end

	test_pagination_last_page
			-- Test pagination on last page (no more results).
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_ignored: DMS_DOCUMENT
			l_page: TUPLE [documents: ARRAYED_LIST [DMS_DOCUMENT]; next_cursor: detachable STRING_8]
			i: INTEGER
		do
			create l_app.make
			l_user := l_app.create_user ("lastpage", "lastpage@example.com", "Last Page")

			if attached l_app.user_root_folder (l_user.id) as l_root then
				from i := 1 until i > 3 loop
					l_ignored := l_app.create_document (l_user.id, l_root.id, "Doc " + i.out, "Content")
					i := i + 1
				end

				-- Request page of 10, only 3 exist
				l_page := l_app.documents_paginated (l_user.id, Void, 10)
				assert_equal ("three_docs", 3, l_page.documents.count)
				assert ("no_more_pages", not attached l_page.next_cursor)
			end

			l_app.close
		end

feature -- Test routines: Search Edge Cases

	test_search_no_results
			-- Test search with no matching documents.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_ignored: DMS_DOCUMENT
		do
			create l_app.make
			l_user := l_app.create_user ("nosearch", "nosearch@example.com", "No Search")

			if attached l_app.user_root_folder (l_user.id) as l_root then
				l_ignored := l_app.create_document (l_user.id, l_root.id, "Hello World", "Some content")

				assert_equal ("no_results", 0, l_app.search_documents ("xyznonexistent", l_user.id).count)
			end

			l_app.close
		end

	test_search_does_not_find_deleted
			-- Test that search excludes soft-deleted documents.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_doc: DMS_DOCUMENT
		do
			create l_app.make
			l_user := l_app.create_user ("searchdel", "searchdel@example.com", "Search Del")

			if attached l_app.user_root_folder (l_user.id) as l_root then
				l_doc := l_app.create_document (l_user.id, l_root.id, "Deletable", "Unique searchable content xyz123")

				assert_equal ("found_before", 1, l_app.search_documents ("xyz123", l_user.id).count)

				l_app.soft_delete_document (l_doc.id, l_user.id)

				assert_equal ("not_found_after", 0, l_app.search_documents ("xyz123", l_user.id).count)
			end

			l_app.close
		end

feature -- Test routines: Audit Trail Completeness

	test_audit_captures_all_operations
			-- Test that audit trail captures all major operations.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_doc: DMS_DOCUMENT
			l_trail: ARRAYED_LIST [DMS_AUDIT_LOG]
			l_actions: ARRAYED_LIST [STRING_8]
		do
			create l_app.make
			l_user := l_app.create_user ("auditall", "auditall@example.com", "Audit All")

			if attached l_app.user_root_folder (l_user.id) as l_root then
				l_doc := l_app.create_document (l_user.id, l_root.id, "Audit Doc", "Content")
				l_app.update_document (l_doc.id, "Audit Doc Updated", "New content", l_user.id, "Updated")
				l_app.record_document_access (l_doc.id, l_user.id)
				l_app.soft_delete_document (l_doc.id, l_user.id)
				l_app.restore_document (l_doc.id, l_user.id)

				l_trail := l_app.entity_audit_trail ("document", l_doc.id)

				create l_actions.make (10)
				across l_trail as ic loop
					l_actions.extend (ic.action)
				end

				assert ("has_create", has_action (l_actions, "create"))
				assert ("has_update", has_action (l_actions, "update"))
				assert ("has_read", has_action (l_actions, "read"))
				assert ("has_soft_delete", has_action (l_actions, "soft_delete"))
				assert ("has_restore", has_action (l_actions, "restore"))
			end

			l_app.close
		end

feature -- Test routines: Multi-User Scenarios

	test_multi_user_document_collaboration
			-- Test multiple users working on same document via sharing.
		local
			l_app: DMS_APP
			l_owner, l_collaborator: DMS_USER
			l_doc: DMS_DOCUMENT
			l_ignored: DMS_SHARE
			l_ignored2: DMS_COMMENT
		do
			create l_app.make
			l_owner := l_app.create_user ("docowner", "docowner@example.com", "Doc Owner")
			l_collaborator := l_app.create_user ("collab", "collab@example.com", "Collaborator")

			if attached l_app.user_root_folder (l_owner.id) as l_root then
				l_doc := l_app.create_document (l_owner.id, l_root.id, "Shared Work", "Initial content")
				l_ignored := l_app.share_document_with_user (l_doc.id, l_owner.id, l_collaborator.id, "{%"read%": true, %"write%": true}")

				-- Both can access
				assert ("owner_access", l_app.can_user_access_document (l_owner.id, l_doc.id))
				assert ("collab_access", l_app.can_user_access_document (l_collaborator.id, l_doc.id))

				-- Both can comment
				l_ignored2 := l_app.add_comment (l_doc.id, l_owner.id, "Owner comment")
				l_ignored2 := l_app.add_comment (l_doc.id, l_collaborator.id, "Collaborator comment")

				assert_equal ("two_comments", 2, l_app.comment_count (l_doc.id))
			end

			l_app.close
		end

feature -- Test routines: Complex Queries

	test_documents_by_multiple_tags
			-- Test finding documents that have specific tags.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_doc1, l_doc2, l_doc3: DMS_DOCUMENT
			l_tag_work, l_tag_urgent: DMS_TAG
		do
			create l_app.make
			l_user := l_app.create_user ("multitag", "multitag@example.com", "Multi Tag")

			if attached l_app.user_root_folder (l_user.id) as l_root then
				l_doc1 := l_app.create_document (l_user.id, l_root.id, "Doc 1", "Content")
				l_doc2 := l_app.create_document (l_user.id, l_root.id, "Doc 2", "Content")
				l_doc3 := l_app.create_document (l_user.id, l_root.id, "Doc 3", "Content")

				l_tag_work := l_app.create_tag (l_user.id, "work")
				l_tag_urgent := l_app.create_tag (l_user.id, "urgent")

				-- Doc1: work + urgent
				l_app.tag_document (l_doc1.id, l_tag_work.id, l_user.id)
				l_app.tag_document (l_doc1.id, l_tag_urgent.id, l_user.id)

				-- Doc2: work only
				l_app.tag_document (l_doc2.id, l_tag_work.id, l_user.id)

				-- Doc3: urgent only
				l_app.tag_document (l_doc3.id, l_tag_urgent.id, l_user.id)

				assert_equal ("two_work", 2, l_app.documents_with_tag (l_tag_work.id).count)
				assert_equal ("two_urgent", 2, l_app.documents_with_tag (l_tag_urgent.id).count)
			end

			l_app.close
		end

feature {NONE} -- Implementation

	has_action (a_list: ARRAYED_LIST [STRING_8]; a_action: STRING_8): BOOLEAN
			-- Does `a_list' contain an action matching `a_action'?
		do
			across a_list as ic loop
				if ic.same_string (a_action) then
					Result := True
				end
			end
		end

end
