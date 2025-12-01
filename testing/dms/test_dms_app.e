note
	description: "Comprehensive tests for DMS_APP - Document Management System"
	testing: "type/manual"
	testing: "execution/serial"

class
	TEST_DMS_APP

inherit
	TEST_SET_BASE

feature -- Test routines: User Management

	test_create_user
			-- Test creating a new user.
		local
			l_app: DMS_APP
			l_user: DMS_USER
		do
			create l_app.make
			l_user := l_app.create_user ("johndoe", "john@example.com", "John Doe")

			assert ("user_saved", not l_user.is_new)
			assert_equal ("username", "johndoe", l_user.username)
			assert_equal ("email", "john@example.com", l_user.email)
			assert_equal ("display_name", "John Doe", l_user.display_name)
			assert ("not_deleted", not l_user.is_deleted)
			assert ("has_root_folder", attached l_app.user_root_folder (l_user.id))

			l_app.close
		end

	test_find_user
			-- Test finding user by ID.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_found: detachable DMS_USER
		do
			create l_app.make
			l_user := l_app.create_user ("findme", "find@example.com", "Find Me")

			l_found := l_app.find_user (l_user.id)
			assert ("found", attached l_found)
			if attached l_found as f then
				assert_equal ("same_username", l_user.username, f.username)
			end

			l_app.close
		end

	test_find_user_by_username
			-- Test finding user by username.
		local
			l_app: DMS_APP
			l_user: DMS_USER
		do
			create l_app.make
			l_user := l_app.create_user ("uniquename", "unique@example.com", "Unique")

			assert ("found", attached l_app.find_user_by_username ("uniquename"))
			assert ("not_found", not attached l_app.find_user_by_username ("nonexistent"))

			l_app.close
		end

	test_all_users
			-- Test getting all users.
		local
			l_app: DMS_APP
			l_ignored: DMS_USER
		do
			create l_app.make
			l_ignored := l_app.create_user ("user1", "u1@example.com", "User 1")
			l_ignored := l_app.create_user ("user2", "u2@example.com", "User 2")
			l_ignored := l_app.create_user ("user3", "u3@example.com", "User 3")

			assert_equal ("three_users", 3, l_app.all_users.count)

			l_app.close
		end

	test_soft_delete_user
			-- Test soft deleting a user.
		local
			l_app: DMS_APP
			l_user: DMS_USER
		do
			create l_app.make
			l_user := l_app.create_user ("deleteme", "delete@example.com", "Delete Me")

			l_app.soft_delete_user (l_user.id, l_user.id)

			-- Should not appear in active users
			assert_equal ("no_active_users", 0, l_app.all_users.count)
			-- Should appear in all users including deleted
			assert_equal ("one_total", 1, l_app.all_users_including_deleted.count)
			-- Should appear in deleted users
			assert_equal ("one_deleted", 1, l_app.deleted_users.count)

			l_app.close
		end

	test_restore_user
			-- Test restoring a soft-deleted user.
		local
			l_app: DMS_APP
			l_user: DMS_USER
		do
			create l_app.make
			l_user := l_app.create_user ("restoreme", "restore@example.com", "Restore Me")

			l_app.soft_delete_user (l_user.id, l_user.id)
			assert_equal ("deleted", 0, l_app.all_users.count)

			l_app.restore_user (l_user.id, l_user.id)
			assert_equal ("restored", 1, l_app.all_users.count)

			l_app.close
		end

	test_update_user
			-- Test updating user.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_found: detachable DMS_USER
		do
			create l_app.make
			l_user := l_app.create_user ("updateme", "update@example.com", "Update Me")

			l_user.set_display_name ("Updated Name")
			l_user.set_preferences_json ("{%"theme%": %"dark%"}")
			l_app.update_user (l_user)

			l_found := l_app.find_user (l_user.id)
			if attached l_found as f then
				assert_equal ("name_updated", "Updated Name", f.display_name)
				assert ("prefs_updated", f.preferences_json.has_substring ("dark"))
			end

			l_app.close
		end

	test_user_count
			-- Test user count.
		local
			l_app: DMS_APP
			l_ignored: DMS_USER
		do
			create l_app.make
			assert_equal ("zero_initially", 0, l_app.user_count)

			l_ignored := l_app.create_user ("counter1", "c1@example.com", "Counter 1")
			l_ignored := l_app.create_user ("counter2", "c2@example.com", "Counter 2")

			assert_equal ("two_users", 2, l_app.user_count)

			l_app.close
		end

feature -- Test routines: Folder Management

	test_create_folder
			-- Test creating a folder.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_root: detachable DMS_FOLDER
			l_folder: DMS_FOLDER
		do
			create l_app.make
			l_user := l_app.create_user ("folderuser", "folder@example.com", "Folder User")

			l_root := l_app.user_root_folder (l_user.id)
			assert ("has_root", attached l_root)

			if attached l_root as r then
				l_folder := l_app.create_folder (l_user.id, r.id, "Documents")
				assert ("folder_saved", not l_folder.is_new)
				assert_equal ("folder_name", "Documents", l_folder.name)
				assert ("has_path", l_folder.path.has_substring ("Documents"))
			end

			l_app.close
		end

	test_folder_hierarchy
			-- Test creating nested folders.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_root, l_docs, l_work, l_projects: DMS_FOLDER
		do
			create l_app.make
			l_user := l_app.create_user ("hierarchyuser", "hier@example.com", "Hierarchy User")

			if attached l_app.user_root_folder (l_user.id) as r then
				l_root := r
				l_docs := l_app.create_folder (l_user.id, l_root.id, "Documents")
				l_work := l_app.create_folder (l_user.id, l_docs.id, "Work")
				l_projects := l_app.create_folder (l_user.id, l_work.id, "Projects")

				assert ("path_contains_docs", l_projects.path.has_substring ("Documents"))
				assert ("path_contains_work", l_projects.path.has_substring ("Work"))
				assert ("path_contains_projects", l_projects.path.has_substring ("Projects"))
			end

			l_app.close
		end

	test_folder_children
			-- Test getting folder children.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_ignored: DMS_FOLDER
			l_children: ARRAYED_LIST [DMS_FOLDER]
		do
			create l_app.make
			l_user := l_app.create_user ("childrenuser", "children@example.com", "Children User")

			if attached l_app.user_root_folder (l_user.id) as l_root then
				l_ignored := l_app.create_folder (l_user.id, l_root.id, "Folder1")
				l_ignored := l_app.create_folder (l_user.id, l_root.id, "Folder2")
				l_ignored := l_app.create_folder (l_user.id, l_root.id, "Folder3")

				l_children := l_app.folder_children (l_root.id)
				assert_equal ("three_children", 3, l_children.count)
			end

			l_app.close
		end

	test_folder_descendants
			-- Test getting all descendants.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_docs, l_work: DMS_FOLDER
			l_ignored: DMS_FOLDER
			l_descendants: ARRAYED_LIST [DMS_FOLDER]
		do
			create l_app.make
			l_user := l_app.create_user ("descuser", "desc@example.com", "Desc User")

			if attached l_app.user_root_folder (l_user.id) as l_root then
				l_docs := l_app.create_folder (l_user.id, l_root.id, "Documents")
				l_work := l_app.create_folder (l_user.id, l_docs.id, "Work")
				l_ignored := l_app.create_folder (l_user.id, l_work.id, "Projects")

				l_descendants := l_app.folder_descendants (l_docs.id)
				assert_equal ("two_descendants", 2, l_descendants.count)
			end

			l_app.close
		end

	test_soft_delete_folder
			-- Test soft deleting folder.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_folder: DMS_FOLDER
			l_found: detachable DMS_FOLDER
		do
			create l_app.make
			l_user := l_app.create_user ("delfolder", "delfolder@example.com", "Del Folder")

			if attached l_app.user_root_folder (l_user.id) as l_root then
				l_folder := l_app.create_folder (l_user.id, l_root.id, "ToDelete")
				l_app.soft_delete_folder (l_folder.id, l_user.id)

				l_found := l_app.find_folder (l_folder.id)
				if attached l_found as f then
					assert ("is_deleted", f.is_deleted)
				end
			end

			l_app.close
		end

	test_folder_count
			-- Test folder count.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_ignored: DMS_FOLDER
		do
			create l_app.make
			l_user := l_app.create_user ("countfolder", "countfolder@example.com", "Count Folder")

			-- Should have 1 (the root folder)
			assert_equal ("one_root", 1, l_app.folder_count (l_user.id))

			if attached l_app.user_root_folder (l_user.id) as l_root then
				l_ignored := l_app.create_folder (l_user.id, l_root.id, "Extra1")
				l_ignored := l_app.create_folder (l_user.id, l_root.id, "Extra2")
			end

			assert_equal ("three_total", 3, l_app.folder_count (l_user.id))

			l_app.close
		end

feature -- Test routines: Document Management

	test_create_document
			-- Test creating a document.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_doc: DMS_DOCUMENT
		do
			create l_app.make
			l_user := l_app.create_user ("docuser", "doc@example.com", "Doc User")

			if attached l_app.user_root_folder (l_user.id) as l_root then
				l_doc := l_app.create_document (l_user.id, l_root.id, "My Document", "This is the content.")

				assert ("doc_saved", not l_doc.is_new)
				assert_equal ("doc_title", "My Document", l_doc.title)
				assert_equal ("doc_content", "This is the content.", l_doc.content)
				assert_equal ("version_1", 1, l_doc.current_version)
			end

			l_app.close
		end

	test_find_document
			-- Test finding document.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_doc: DMS_DOCUMENT
		do
			create l_app.make
			l_user := l_app.create_user ("finddoc", "finddoc@example.com", "Find Doc")

			if attached l_app.user_root_folder (l_user.id) as l_root then
				l_doc := l_app.create_document (l_user.id, l_root.id, "Findable", "Content here")

				assert ("found", attached l_app.find_document (l_doc.id))
				assert ("not_found", not attached l_app.find_document (99999))
			end

			l_app.close
		end

	test_folder_documents
			-- Test getting documents in folder.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_ignored: DMS_DOCUMENT
		do
			create l_app.make
			l_user := l_app.create_user ("folderdocs", "folderdocs@example.com", "Folder Docs")

			if attached l_app.user_root_folder (l_user.id) as l_root then
				l_ignored := l_app.create_document (l_user.id, l_root.id, "Doc1", "Content 1")
				l_ignored := l_app.create_document (l_user.id, l_root.id, "Doc2", "Content 2")
				l_ignored := l_app.create_document (l_user.id, l_root.id, "Doc3", "Content 3")

				assert_equal ("three_docs", 3, l_app.folder_documents (l_root.id).count)
			end

			l_app.close
		end

	test_update_document_creates_version
			-- Test that updating a document creates a new version.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_doc: DMS_DOCUMENT
			l_found: detachable DMS_DOCUMENT
		do
			create l_app.make
			l_user := l_app.create_user ("versionuser", "version@example.com", "Version User")

			if attached l_app.user_root_folder (l_user.id) as l_root then
				l_doc := l_app.create_document (l_user.id, l_root.id, "Versioned Doc", "Initial content")
				assert_equal ("v1", 1, l_doc.current_version)

				l_app.update_document (l_doc.id, "Versioned Doc", "Updated content", l_user.id, "First update")

				l_found := l_app.find_document (l_doc.id)
				if attached l_found as f then
					assert_equal ("v2", 2, f.current_version)
				end

				l_app.update_document (l_doc.id, "Versioned Doc v3", "Third version", l_user.id, "Second update")
				l_found := l_app.find_document (l_doc.id)
				if attached l_found as f then
					assert_equal ("v3", 3, f.current_version)
				end
			end

			l_app.close
		end

	test_document_versions
			-- Test getting document versions.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_doc: DMS_DOCUMENT
			l_versions: ARRAYED_LIST [DMS_DOCUMENT_VERSION]
		do
			create l_app.make
			l_user := l_app.create_user ("versionsuser", "versions@example.com", "Versions User")

			if attached l_app.user_root_folder (l_user.id) as l_root then
				l_doc := l_app.create_document (l_user.id, l_root.id, "Multi Version", "Version 1")
				l_app.update_document (l_doc.id, "Multi Version", "Version 2", l_user.id, "Update 1")
				l_app.update_document (l_doc.id, "Multi Version", "Version 3", l_user.id, "Update 2")

				l_versions := l_app.document_versions (l_doc.id)
				assert_equal ("three_versions", 3, l_versions.count)
			end

			l_app.close
		end

	test_restore_document_version
			-- Test restoring a previous version.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_doc: DMS_DOCUMENT
			l_found: detachable DMS_DOCUMENT
		do
			create l_app.make
			l_user := l_app.create_user ("restorever", "restorever@example.com", "Restore Ver")

			if attached l_app.user_root_folder (l_user.id) as l_root then
				l_doc := l_app.create_document (l_user.id, l_root.id, "Restorable", "Original content")
				l_app.update_document (l_doc.id, "Restorable", "Changed content", l_user.id, "Changed")

				-- Restore to version 1
				l_app.restore_document_version (l_doc.id, 1, l_user.id)

				l_found := l_app.find_document (l_doc.id)
				if attached l_found as f then
					assert_equal ("content_restored", "Original content", f.content)
					assert_equal ("version_incremented", 3, f.current_version) -- Restore creates new version
				end
			end

			l_app.close
		end

	test_soft_delete_document
			-- Test soft deleting a document.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_doc: DMS_DOCUMENT
		do
			create l_app.make
			l_user := l_app.create_user ("deldocuser", "deldoc@example.com", "Del Doc")

			if attached l_app.user_root_folder (l_user.id) as l_root then
				l_doc := l_app.create_document (l_user.id, l_root.id, "To Delete", "Content")
				l_app.soft_delete_document (l_doc.id, l_user.id)

				-- Should not appear in folder documents
				assert_equal ("not_in_folder", 0, l_app.folder_documents (l_root.id).count)
				-- Should appear in trash
				assert_equal ("in_trash", 1, l_app.trashed_documents (l_user.id).count)
			end

			l_app.close
		end

	test_restore_document
			-- Test restoring a document from trash.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_doc: DMS_DOCUMENT
		do
			create l_app.make
			l_user := l_app.create_user ("restoredoc", "restoredoc@example.com", "Restore Doc")

			if attached l_app.user_root_folder (l_user.id) as l_root then
				l_doc := l_app.create_document (l_user.id, l_root.id, "Restore Me", "Content")
				l_app.soft_delete_document (l_doc.id, l_user.id)
				l_app.restore_document (l_doc.id, l_user.id)

				assert_equal ("back_in_folder", 1, l_app.folder_documents (l_root.id).count)
				assert_equal ("not_in_trash", 0, l_app.trashed_documents (l_user.id).count)
			end

			l_app.close
		end

	test_document_count
			-- Test document count.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_ignored: DMS_DOCUMENT
		do
			create l_app.make
			l_user := l_app.create_user ("countdoc", "countdoc@example.com", "Count Doc")

			if attached l_app.user_root_folder (l_user.id) as l_root then
				assert_equal ("zero_initially", 0, l_app.document_count (l_user.id))

				l_ignored := l_app.create_document (l_user.id, l_root.id, "Doc1", "C1")
				l_ignored := l_app.create_document (l_user.id, l_root.id, "Doc2", "C2")

				assert_equal ("two_docs", 2, l_app.document_count (l_user.id))
			end

			l_app.close
		end

feature -- Test routines: Comments

	test_add_comment
			-- Test adding a comment.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_doc: DMS_DOCUMENT
			l_comment: DMS_COMMENT
		do
			create l_app.make
			l_user := l_app.create_user ("commentuser", "comment@example.com", "Comment User")

			if attached l_app.user_root_folder (l_user.id) as l_root then
				l_doc := l_app.create_document (l_user.id, l_root.id, "Commented Doc", "Content")
				l_comment := l_app.add_comment (l_doc.id, l_user.id, "This is a great document!")

				assert ("comment_saved", not l_comment.is_new)
				assert ("is_top_level", l_comment.is_top_level)
			end

			l_app.close
		end

	test_reply_to_comment
			-- Test replying to a comment.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_doc: DMS_DOCUMENT
			l_comment, l_reply: DMS_COMMENT
		do
			create l_app.make
			l_user := l_app.create_user ("replyuser", "reply@example.com", "Reply User")

			if attached l_app.user_root_folder (l_user.id) as l_root then
				l_doc := l_app.create_document (l_user.id, l_root.id, "Reply Doc", "Content")
				l_comment := l_app.add_comment (l_doc.id, l_user.id, "Original comment")
				l_reply := l_app.reply_to_comment (l_doc.id, l_user.id, l_comment.id, "This is a reply")

				assert ("reply_saved", not l_reply.is_new)
				assert ("is_reply", l_reply.is_reply)
			end

			l_app.close
		end

	test_document_comments
			-- Test getting document comments.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_doc: DMS_DOCUMENT
			l_ignored: DMS_COMMENT
		do
			create l_app.make
			l_user := l_app.create_user ("commentsuser", "comments@example.com", "Comments User")

			if attached l_app.user_root_folder (l_user.id) as l_root then
				l_doc := l_app.create_document (l_user.id, l_root.id, "Many Comments", "Content")
				l_ignored := l_app.add_comment (l_doc.id, l_user.id, "Comment 1")
				l_ignored := l_app.add_comment (l_doc.id, l_user.id, "Comment 2")
				l_ignored := l_app.add_comment (l_doc.id, l_user.id, "Comment 3")

				assert_equal ("three_comments", 3, l_app.document_comments (l_doc.id).count)
			end

			l_app.close
		end

	test_document_comments_with_users
			-- Test eager loading of comments with user names (N+1 solution).
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_doc: DMS_DOCUMENT
			l_ignored: DMS_COMMENT
			l_comments: ARRAYED_LIST [DMS_COMMENT]
		do
			create l_app.make
			l_user := l_app.create_user ("eagercmts", "eager@example.com", "Eager Comments")

			if attached l_app.user_root_folder (l_user.id) as l_root then
				l_doc := l_app.create_document (l_user.id, l_root.id, "Eager Doc", "Content")
				l_ignored := l_app.add_comment (l_doc.id, l_user.id, "Comment with user")

				l_comments := l_app.document_comments_with_users (l_doc.id)
				assert_equal ("one_comment", 1, l_comments.count)
				assert ("has_cached_name", attached l_comments.first.cached_user_display_name)
			end

			l_app.close
		end

	test_comment_count
			-- Test comment count.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_doc: DMS_DOCUMENT
			l_ignored: DMS_COMMENT
		do
			create l_app.make
			l_user := l_app.create_user ("cmtcount", "cmtcount@example.com", "Cmt Count")

			if attached l_app.user_root_folder (l_user.id) as l_root then
				l_doc := l_app.create_document (l_user.id, l_root.id, "Count Comments", "Content")
				assert_equal ("zero", 0, l_app.comment_count (l_doc.id))

				l_ignored := l_app.add_comment (l_doc.id, l_user.id, "First")
				l_ignored := l_app.add_comment (l_doc.id, l_user.id, "Second")

				assert_equal ("two", 2, l_app.comment_count (l_doc.id))
			end

			l_app.close
		end

feature -- Test routines: Tags

	test_create_tag
			-- Test creating a tag.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_tag: DMS_TAG
		do
			create l_app.make
			l_user := l_app.create_user ("taguser", "tag@example.com", "Tag User")
			l_tag := l_app.create_tag (l_user.id, "important")

			assert ("tag_saved", not l_tag.is_new)
			assert_equal ("tag_name", "important", l_tag.name)

			l_app.close
		end

	test_user_tags
			-- Test getting user's tags.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_ignored: DMS_TAG
		do
			create l_app.make
			l_user := l_app.create_user ("tagsuser", "tags@example.com", "Tags User")
			l_ignored := l_app.create_tag (l_user.id, "work")
			l_ignored := l_app.create_tag (l_user.id, "personal")
			l_ignored := l_app.create_tag (l_user.id, "urgent")

			assert_equal ("three_tags", 3, l_app.user_tags (l_user.id).count)

			l_app.close
		end

	test_tag_document
			-- Test tagging a document.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_doc: DMS_DOCUMENT
			l_tag: DMS_TAG
		do
			create l_app.make
			l_user := l_app.create_user ("tagdocuser", "tagdoc@example.com", "Tag Doc")

			if attached l_app.user_root_folder (l_user.id) as l_root then
				l_doc := l_app.create_document (l_user.id, l_root.id, "Tagged Doc", "Content")
				l_tag := l_app.create_tag (l_user.id, "featured")

				l_app.tag_document (l_doc.id, l_tag.id, l_user.id)

				assert_equal ("one_tag", 1, l_app.document_tags (l_doc.id).count)
			end

			l_app.close
		end

	test_documents_with_tag
			-- Test finding documents by tag.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_doc1, l_doc2, l_ignored: DMS_DOCUMENT
			l_tag: DMS_TAG
		do
			create l_app.make
			l_user := l_app.create_user ("docsbytag", "docsbytag@example.com", "Docs By Tag")

			if attached l_app.user_root_folder (l_user.id) as l_root then
				l_doc1 := l_app.create_document (l_user.id, l_root.id, "Doc 1", "Content 1")
				l_doc2 := l_app.create_document (l_user.id, l_root.id, "Doc 2", "Content 2")
				l_ignored := l_app.create_document (l_user.id, l_root.id, "Doc 3", "Content 3")
				l_tag := l_app.create_tag (l_user.id, "special")

				l_app.tag_document (l_doc1.id, l_tag.id, l_user.id)
				l_app.tag_document (l_doc2.id, l_tag.id, l_user.id)

				assert_equal ("two_docs_tagged", 2, l_app.documents_with_tag (l_tag.id).count)
			end

			l_app.close
		end

	test_untag_document
			-- Test removing tag from document.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_doc: DMS_DOCUMENT
			l_tag: DMS_TAG
		do
			create l_app.make
			l_user := l_app.create_user ("untaguser", "untag@example.com", "Untag User")

			if attached l_app.user_root_folder (l_user.id) as l_root then
				l_doc := l_app.create_document (l_user.id, l_root.id, "Untag Doc", "Content")
				l_tag := l_app.create_tag (l_user.id, "temporary")

				l_app.tag_document (l_doc.id, l_tag.id, l_user.id)
				assert_equal ("has_tag", 1, l_app.document_tags (l_doc.id).count)

				l_app.untag_document (l_doc.id, l_tag.id, l_user.id)
				assert_equal ("no_tag", 0, l_app.document_tags (l_doc.id).count)
			end

			l_app.close
		end

feature -- Test routines: Sharing

	test_share_document
			-- Test sharing a document.
		local
			l_app: DMS_APP
			l_user1, l_user2: DMS_USER
			l_doc: DMS_DOCUMENT
			l_share: DMS_SHARE
		do
			create l_app.make
			l_user1 := l_app.create_user ("shareowner", "owner@example.com", "Owner")
			l_user2 := l_app.create_user ("sharerecip", "recip@example.com", "Recipient")

			if attached l_app.user_root_folder (l_user1.id) as l_root then
				l_doc := l_app.create_document (l_user1.id, l_root.id, "Shared Doc", "Content")
				l_share := l_app.share_document_with_user (l_doc.id, l_user1.id, l_user2.id, "{%"read%": true, %"write%": false}")

				assert ("share_saved", not l_share.is_new)
				assert ("can_read", l_share.can_read)
				assert ("cannot_write", not l_share.can_write)
			end

			l_app.close
		end

	test_documents_shared_with_user
			-- Test finding documents shared with user.
		local
			l_app: DMS_APP
			l_user1, l_user2: DMS_USER
			l_doc: DMS_DOCUMENT
			l_ignored: DMS_SHARE
		do
			create l_app.make
			l_user1 := l_app.create_user ("sharer", "sharer@example.com", "Sharer")
			l_user2 := l_app.create_user ("sharee", "sharee@example.com", "Sharee")

			if attached l_app.user_root_folder (l_user1.id) as l_root then
				l_doc := l_app.create_document (l_user1.id, l_root.id, "Shared", "Content")
				l_ignored := l_app.share_document_with_user (l_doc.id, l_user1.id, l_user2.id, "{%"read%": true}")

				assert_equal ("one_shared", 1, l_app.documents_shared_with_user (l_user2.id).count)
			end

			l_app.close
		end

	test_can_user_access_document
			-- Test checking document access.
		local
			l_app: DMS_APP
			l_user1, l_user2, l_user3: DMS_USER
			l_doc: DMS_DOCUMENT
			l_ignored: DMS_SHARE
		do
			create l_app.make
			l_user1 := l_app.create_user ("accessowner", "accessowner@example.com", "Access Owner")
			l_user2 := l_app.create_user ("accessshared", "accessshared@example.com", "Access Shared")
			l_user3 := l_app.create_user ("noaccess", "noaccess@example.com", "No Access")

			if attached l_app.user_root_folder (l_user1.id) as l_root then
				l_doc := l_app.create_document (l_user1.id, l_root.id, "Access Test", "Content")
				l_ignored := l_app.share_document_with_user (l_doc.id, l_user1.id, l_user2.id, "{%"read%": true}")

				assert ("owner_has_access", l_app.can_user_access_document (l_user1.id, l_doc.id))
				assert ("shared_has_access", l_app.can_user_access_document (l_user2.id, l_doc.id))
				assert ("no_access", not l_app.can_user_access_document (l_user3.id, l_doc.id))
			end

			l_app.close
		end

	test_revoke_share
			-- Test revoking a share.
		local
			l_app: DMS_APP
			l_user1, l_user2: DMS_USER
			l_doc: DMS_DOCUMENT
			l_share: DMS_SHARE
		do
			create l_app.make
			l_user1 := l_app.create_user ("revokeowner", "revokeowner@example.com", "Revoke Owner")
			l_user2 := l_app.create_user ("revokerecip", "revokerecip@example.com", "Revoke Recip")

			if attached l_app.user_root_folder (l_user1.id) as l_root then
				l_doc := l_app.create_document (l_user1.id, l_root.id, "Revoke Test", "Content")
				l_share := l_app.share_document_with_user (l_doc.id, l_user1.id, l_user2.id, "{%"read%": true}")

				assert ("initially_accessible", l_app.can_user_access_document (l_user2.id, l_doc.id))

				l_app.revoke_share (l_share.id, l_user1.id)

				assert ("no_longer_accessible", not l_app.can_user_access_document (l_user2.id, l_doc.id))
			end

			l_app.close
		end

feature -- Test routines: Full-Text Search

	test_search_documents
			-- Test searching documents.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_ignored: DMS_DOCUMENT
			l_results: ARRAYED_LIST [DMS_DOCUMENT]
		do
			create l_app.make
			l_user := l_app.create_user ("searchuser", "search@example.com", "Search User")

			if attached l_app.user_root_folder (l_user.id) as l_root then
				l_ignored := l_app.create_document (l_user.id, l_root.id, "Meeting Notes", "Discussion about project timeline")
				l_ignored := l_app.create_document (l_user.id, l_root.id, "Project Plan", "Timeline and milestones for the project")
				l_ignored := l_app.create_document (l_user.id, l_root.id, "Budget Report", "Financial analysis for Q4")

				l_results := l_app.search_documents ("project", l_user.id)
				assert_equal ("two_results", 2, l_results.count)

				l_results := l_app.search_documents ("budget", l_user.id)
				assert_equal ("one_result", 1, l_results.count)
			end

			l_app.close
		end

	test_search_with_snippets
			-- Test search with highlighted snippets.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_ignored: DMS_DOCUMENT
			l_results: ARRAYED_LIST [TUPLE [document: DMS_DOCUMENT; snippet: STRING_8]]
		do
			create l_app.make
			l_user := l_app.create_user ("snippetuser", "snippet@example.com", "Snippet User")

			if attached l_app.user_root_folder (l_user.id) as l_root then
				l_ignored := l_app.create_document (l_user.id, l_root.id, "Snippet Test", "The quick brown fox jumps over the lazy dog")

				l_results := l_app.search_documents_with_snippets ("fox", l_user.id)
				assert_equal ("one_result", 1, l_results.count)
				-- Snippet should contain highlighted text
			end

			l_app.close
		end

feature -- Test routines: Pagination

	test_documents_paginated
			-- Test cursor-based pagination.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_ignored: DMS_DOCUMENT
			l_page1, l_page2: TUPLE [documents: ARRAYED_LIST [DMS_DOCUMENT]; next_cursor: detachable STRING_8]
			i: INTEGER
		do
			create l_app.make
			l_user := l_app.create_user ("pageuser", "page@example.com", "Page User")

			if attached l_app.user_root_folder (l_user.id) as l_root then
				-- Create 10 documents
				from i := 1 until i > 10 loop
					l_ignored := l_app.create_document (l_user.id, l_root.id, "Doc " + i.out, "Content " + i.out)
					i := i + 1
				end

				-- Get first page (5 items)
				l_page1 := l_app.documents_paginated (l_user.id, Void, 5)
				assert_equal ("first_page_5", 5, l_page1.documents.count)
				assert ("has_next_cursor", attached l_page1.next_cursor)

				-- Get second page
				l_page2 := l_app.documents_paginated (l_user.id, l_page1.next_cursor, 5)
				assert_equal ("second_page_5", 5, l_page2.documents.count)
			end

			l_app.close
		end

	test_activity_feed_paginated
			-- Test paginated activity feed.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_ignored: DMS_DOCUMENT
			l_page: TUPLE [entries: ARRAYED_LIST [DMS_AUDIT_LOG]; next_cursor: detachable STRING_8]
		do
			create l_app.make
			l_user := l_app.create_user ("activityuser", "activity@example.com", "Activity User")

			if attached l_app.user_root_folder (l_user.id) as l_root then
				l_ignored := l_app.create_document (l_user.id, l_root.id, "Activity Doc", "Content")

				l_page := l_app.activity_feed_paginated (l_user.id, Void, 10)
				assert ("has_entries", l_page.entries.count > 0)
			end

			l_app.close
		end

feature -- Test routines: Audit Trail

	test_entity_audit_trail
			-- Test getting audit trail for entity.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_doc: DMS_DOCUMENT
			l_trail: ARRAYED_LIST [DMS_AUDIT_LOG]
		do
			create l_app.make
			l_user := l_app.create_user ("audituser", "audit@example.com", "Audit User")

			if attached l_app.user_root_folder (l_user.id) as l_root then
				l_doc := l_app.create_document (l_user.id, l_root.id, "Audited Doc", "Content")
				l_app.update_document (l_doc.id, "Audited Doc Updated", "New content", l_user.id, "Updated")

				l_trail := l_app.entity_audit_trail ("document", l_doc.id)
				assert ("has_trail", l_trail.count >= 2) -- create + update + version
			end

			l_app.close
		end

	test_user_activity
			-- Test getting user activity.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_ignored: DMS_DOCUMENT
			l_activity: ARRAYED_LIST [DMS_AUDIT_LOG]
		do
			create l_app.make
			l_user := l_app.create_user ("actuser", "act@example.com", "Act User")

			if attached l_app.user_root_folder (l_user.id) as l_root then
				l_ignored := l_app.create_document (l_user.id, l_root.id, "Activity Doc 1", "Content")
				l_ignored := l_app.create_document (l_user.id, l_root.id, "Activity Doc 2", "Content")

				l_activity := l_app.user_activity (l_user.id, 100)
				assert ("has_activity", l_activity.count > 0)
			end

			l_app.close
		end

	test_audit_log_count
			-- Test audit log count.
		local
			l_app: DMS_APP
			l_ignored: DMS_USER
		do
			create l_app.make
			l_ignored := l_app.create_user ("logcount", "logcount@example.com", "Log Count")

			assert ("has_entries", l_app.audit_log_count > 0)

			l_app.close
		end

feature -- Test routines: Trash Management

	test_trash_count
			-- Test counting items in trash.
		local
			l_app: DMS_APP
			l_user: DMS_USER
			l_doc: DMS_DOCUMENT
		do
			create l_app.make
			l_user := l_app.create_user ("trashcount", "trashcount@example.com", "Trash Count")

			if attached l_app.user_root_folder (l_user.id) as l_root then
				assert_equal ("empty_trash", 0, l_app.trash_count (l_user.id))

				l_doc := l_app.create_document (l_user.id, l_root.id, "Trash Me", "Content")
				l_app.soft_delete_document (l_doc.id, l_user.id)

				assert_equal ("one_in_trash", 1, l_app.trash_count (l_user.id))
			end

			l_app.close
		end

feature -- Test routines: Schema Versioning

	test_schema_version
			-- Test schema version tracking.
		local
			l_app: DMS_APP
		do
			create l_app.make

			assert ("has_version", l_app.current_schema_version >= 1)
			assert ("has_migrations", l_app.applied_migrations.count >= 1)

			l_app.close
		end

end
