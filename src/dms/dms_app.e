note
	description: "[
		DMS Application Facade - Document Management System demonstrating all SIMPLE_SQL pain points.

		This comprehensive mock application exposes:
		- N+1 query problems (comments with users, documents with tags)
		- Repetitive CRUD boilerplate (9 entities)
		- Audit trail patterns (every action logged)
		- Soft delete system (trash/restore)
		- Cursor-based pagination
		- Date/time handling
		- FTS5 full-text search
		- Transaction management
		- Schema migrations
		- JSON column handling (permissions, metadata, preferences)
		- Hierarchical folder structures
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	DMS_APP

create
	make,
	make_with_file

feature {NONE} -- Initialization

	make
			-- Initialize DMS with in-memory database.
		do
			create database.make_memory
			initialize_schema
		end

	make_with_file (a_path: READABLE_STRING_8)
			-- Initialize DMS with file-based database.
		require
			path_not_empty: not a_path.is_empty
		do
			create database.make (a_path)
			initialize_schema
		end

feature -- Access

	database: SIMPLE_SQL_DATABASE
			-- The underlying database connection.

feature -- Database Management

	close
			-- Close the database connection.
		do
			database.close
		end

feature {NONE} -- Schema

	initialize_schema
			-- Create all tables and indexes.
		do
			create_schema_versions_table
			create_users_table
			create_folders_table
			create_documents_table
			create_document_versions_table
			create_comments_table
			create_tags_table
			create_document_tags_table
			create_shares_table
			create_audit_log_table
			create_fts_table
			create_indexes
			record_schema_version (1, "initial_schema", "Created all DMS tables")
		end

	create_schema_versions_table
		do
			database.execute ("[
				CREATE TABLE IF NOT EXISTS schema_versions (
					id INTEGER PRIMARY KEY AUTOINCREMENT,
					version INTEGER NOT NULL UNIQUE,
					name TEXT NOT NULL,
					description TEXT NOT NULL DEFAULT '',
					applied_at TEXT NOT NULL DEFAULT (datetime('now')),
					checksum TEXT,
					execution_time_ms INTEGER DEFAULT 0
				)
			]")
		end

	create_users_table
		do
			database.execute ("[
				CREATE TABLE IF NOT EXISTS users (
					id INTEGER PRIMARY KEY AUTOINCREMENT,
					username TEXT NOT NULL UNIQUE,
					email TEXT NOT NULL UNIQUE,
					display_name TEXT NOT NULL DEFAULT '',
					preferences_json TEXT NOT NULL DEFAULT '{}',
					created_at TEXT NOT NULL DEFAULT (datetime('now')),
					updated_at TEXT NOT NULL DEFAULT (datetime('now')),
					deleted_at TEXT
				)
			]")
		end

	create_folders_table
		do
			database.execute ("[
				CREATE TABLE IF NOT EXISTS folders (
					id INTEGER PRIMARY KEY AUTOINCREMENT,
					owner_id INTEGER NOT NULL REFERENCES users(id),
					parent_id INTEGER REFERENCES folders(id),
					name TEXT NOT NULL,
					path TEXT NOT NULL,
					created_at TEXT NOT NULL DEFAULT (datetime('now')),
					updated_at TEXT NOT NULL DEFAULT (datetime('now')),
					deleted_at TEXT
				)
			]")
		end

	create_documents_table
		do
			database.execute ("[
				CREATE TABLE IF NOT EXISTS documents (
					id INTEGER PRIMARY KEY AUTOINCREMENT,
					owner_id INTEGER NOT NULL REFERENCES users(id),
					folder_id INTEGER NOT NULL REFERENCES folders(id),
					title TEXT NOT NULL,
					content TEXT NOT NULL DEFAULT '',
					mime_type TEXT NOT NULL DEFAULT 'text/plain',
					file_size INTEGER NOT NULL DEFAULT 0,
					checksum TEXT,
					current_version INTEGER NOT NULL DEFAULT 1,
					metadata_json TEXT NOT NULL DEFAULT '{}',
					created_at TEXT NOT NULL DEFAULT (datetime('now')),
					updated_at TEXT NOT NULL DEFAULT (datetime('now')),
					deleted_at TEXT,
					expires_at TEXT,
					last_accessed_at TEXT
				)
			]")
		end

	create_document_versions_table
		do
			database.execute ("[
				CREATE TABLE IF NOT EXISTS document_versions (
					id INTEGER PRIMARY KEY AUTOINCREMENT,
					document_id INTEGER NOT NULL REFERENCES documents(id),
					version_number INTEGER NOT NULL,
					title TEXT NOT NULL,
					content TEXT NOT NULL,
					file_size INTEGER NOT NULL DEFAULT 0,
					checksum TEXT,
					created_by INTEGER NOT NULL REFERENCES users(id),
					change_summary TEXT,
					created_at TEXT NOT NULL DEFAULT (datetime('now')),
					UNIQUE(document_id, version_number)
				)
			]")
		end

	create_comments_table
		do
			database.execute ("[
				CREATE TABLE IF NOT EXISTS comments (
					id INTEGER PRIMARY KEY AUTOINCREMENT,
					document_id INTEGER NOT NULL REFERENCES documents(id),
					user_id INTEGER NOT NULL REFERENCES users(id),
					parent_comment_id INTEGER REFERENCES comments(id),
					content TEXT NOT NULL,
					created_at TEXT NOT NULL DEFAULT (datetime('now')),
					updated_at TEXT NOT NULL DEFAULT (datetime('now')),
					deleted_at TEXT
				)
			]")
		end

	create_tags_table
		do
			database.execute ("[
				CREATE TABLE IF NOT EXISTS tags (
					id INTEGER PRIMARY KEY AUTOINCREMENT,
					owner_id INTEGER NOT NULL REFERENCES users(id),
					name TEXT NOT NULL,
					color TEXT DEFAULT '#808080',
					created_at TEXT NOT NULL DEFAULT (datetime('now')),
					UNIQUE(owner_id, name)
				)
			]")
		end

	create_document_tags_table
		do
			database.execute ("[
				CREATE TABLE IF NOT EXISTS document_tags (
					id INTEGER PRIMARY KEY AUTOINCREMENT,
					document_id INTEGER NOT NULL REFERENCES documents(id),
					tag_id INTEGER NOT NULL REFERENCES tags(id),
					tagged_by INTEGER NOT NULL REFERENCES users(id),
					created_at TEXT NOT NULL DEFAULT (datetime('now')),
					UNIQUE(document_id, tag_id)
				)
			]")
		end

	create_shares_table
		do
			database.execute ("[
				CREATE TABLE IF NOT EXISTS shares (
					id INTEGER PRIMARY KEY AUTOINCREMENT,
					document_id INTEGER REFERENCES documents(id),
					folder_id INTEGER REFERENCES folders(id),
					owner_id INTEGER NOT NULL REFERENCES users(id),
					shared_with_user_id INTEGER REFERENCES users(id),
					permissions_json TEXT NOT NULL DEFAULT '{"read": true}',
					share_link TEXT UNIQUE,
					expires_at TEXT,
					created_at TEXT NOT NULL DEFAULT (datetime('now')),
					revoked_at TEXT,
					CHECK (document_id IS NOT NULL OR folder_id IS NOT NULL)
				)
			]")
		end

	create_audit_log_table
		do
			database.execute ("[
				CREATE TABLE IF NOT EXISTS audit_log (
					id INTEGER PRIMARY KEY AUTOINCREMENT,
					user_id INTEGER NOT NULL REFERENCES users(id),
					action TEXT NOT NULL,
					entity_type TEXT NOT NULL,
					entity_id INTEGER NOT NULL,
					old_value_json TEXT,
					new_value_json TEXT,
					ip_address TEXT,
					user_agent TEXT,
					created_at TEXT NOT NULL DEFAULT (datetime('now'))
				)
			]")
		end

	create_fts_table
			-- Create FTS5 virtual table for full-text search.
		do
			database.execute ("[
				CREATE VIRTUAL TABLE IF NOT EXISTS documents_fts USING fts5(
					title,
					content
				)
			]")
		end

	create_indexes
		do
			-- User indexes
			database.execute ("CREATE INDEX IF NOT EXISTS idx_users_deleted ON users(deleted_at)")
			database.execute ("CREATE INDEX IF NOT EXISTS idx_users_username ON users(username)")

			-- Folder indexes
			database.execute ("CREATE INDEX IF NOT EXISTS idx_folders_owner ON folders(owner_id)")
			database.execute ("CREATE INDEX IF NOT EXISTS idx_folders_parent ON folders(parent_id)")
			database.execute ("CREATE INDEX IF NOT EXISTS idx_folders_deleted ON folders(deleted_at)")
			database.execute ("CREATE INDEX IF NOT EXISTS idx_folders_path ON folders(path)")

			-- Document indexes
			database.execute ("CREATE INDEX IF NOT EXISTS idx_documents_owner ON documents(owner_id)")
			database.execute ("CREATE INDEX IF NOT EXISTS idx_documents_folder ON documents(folder_id)")
			database.execute ("CREATE INDEX IF NOT EXISTS idx_documents_deleted ON documents(deleted_at)")
			database.execute ("CREATE INDEX IF NOT EXISTS idx_documents_expires ON documents(expires_at)")
			database.execute ("CREATE INDEX IF NOT EXISTS idx_documents_accessed ON documents(last_accessed_at)")

			-- Version indexes
			database.execute ("CREATE INDEX IF NOT EXISTS idx_versions_document ON document_versions(document_id)")
			database.execute ("CREATE INDEX IF NOT EXISTS idx_versions_created_by ON document_versions(created_by)")

			-- Comment indexes
			database.execute ("CREATE INDEX IF NOT EXISTS idx_comments_document ON comments(document_id)")
			database.execute ("CREATE INDEX IF NOT EXISTS idx_comments_user ON comments(user_id)")
			database.execute ("CREATE INDEX IF NOT EXISTS idx_comments_parent ON comments(parent_comment_id)")
			database.execute ("CREATE INDEX IF NOT EXISTS idx_comments_deleted ON comments(deleted_at)")

			-- Tag indexes
			database.execute ("CREATE INDEX IF NOT EXISTS idx_tags_owner ON tags(owner_id)")
			database.execute ("CREATE INDEX IF NOT EXISTS idx_document_tags_document ON document_tags(document_id)")
			database.execute ("CREATE INDEX IF NOT EXISTS idx_document_tags_tag ON document_tags(tag_id)")

			-- Share indexes
			database.execute ("CREATE INDEX IF NOT EXISTS idx_shares_document ON shares(document_id)")
			database.execute ("CREATE INDEX IF NOT EXISTS idx_shares_folder ON shares(folder_id)")
			database.execute ("CREATE INDEX IF NOT EXISTS idx_shares_owner ON shares(owner_id)")
			database.execute ("CREATE INDEX IF NOT EXISTS idx_shares_shared_with ON shares(shared_with_user_id)")
			database.execute ("CREATE INDEX IF NOT EXISTS idx_shares_revoked ON shares(revoked_at)")

			-- Audit log indexes
			database.execute ("CREATE INDEX IF NOT EXISTS idx_audit_user ON audit_log(user_id)")
			database.execute ("CREATE INDEX IF NOT EXISTS idx_audit_entity ON audit_log(entity_type, entity_id)")
			database.execute ("CREATE INDEX IF NOT EXISTS idx_audit_action ON audit_log(action)")
			database.execute ("CREATE INDEX IF NOT EXISTS idx_audit_created ON audit_log(created_at)")
		end

	record_schema_version (a_version: INTEGER; a_name, a_description: STRING_8)
			-- Record that a schema version was applied.
		do
			database.execute_with_args (
				"INSERT OR IGNORE INTO schema_versions (version, name, description) VALUES (?, ?, ?)",
				<<a_version, a_name, a_description>>
			)
		end

feature -- User Management (CRUD Boilerplate Example #1)

	create_user (a_username, a_email, a_display_name: READABLE_STRING_8): DMS_USER
			-- Create a new user.
		require
			username_not_empty: not a_username.is_empty
			email_not_empty: not a_email.is_empty
		local
			l_user: DMS_USER
			l_result: SIMPLE_SQL_RESULT
		do
			create l_user.make_new (a_username, a_email, a_display_name)
			database.execute_with_args (
				"INSERT INTO users (username, email, display_name) VALUES (?, ?, ?)",
				<<a_username, a_email, a_display_name>>
			)
			l_user.set_id (database.last_insert_rowid)
			l_result := database.query_with_args ("SELECT created_at, updated_at FROM users WHERE id = ?", <<l_user.id>>)
			if not l_result.is_empty then
				l_user.set_created_at (l_result.first.string_value ("created_at").to_string_8)
				l_user.set_updated_at (l_result.first.string_value ("updated_at").to_string_8)
			end
			-- Log audit
			log_audit (l_user.id, "create", "user", l_user.id, Void, user_to_json (l_user))
			-- Create root folder for user (discard result)
			if attached create_root_folder (l_user.id) as l_root then
				-- Root folder created
			end
			Result := l_user
		ensure
			result_saved: not Result.is_new
		end

	find_user (a_id: INTEGER_64): detachable DMS_USER
			-- Find user by ID.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args ("SELECT * FROM users WHERE id = ?", <<a_id>>)
			if not l_result.is_empty then
				Result := row_to_user (l_result.first)
			end
		end

	find_user_by_username (a_username: READABLE_STRING_8): detachable DMS_USER
			-- Find user by username.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args ("SELECT * FROM users WHERE username = ?", <<a_username>>)
			if not l_result.is_empty then
				Result := row_to_user (l_result.first)
			end
		end

	all_users: ARRAYED_LIST [DMS_USER]
			-- Get all active users.
		do
			Result := query_users ("SELECT * FROM users WHERE deleted_at IS NULL ORDER BY username")
		end

	all_users_including_deleted: ARRAYED_LIST [DMS_USER]
			-- Get all users including soft-deleted.
		do
			Result := query_users ("SELECT * FROM users ORDER BY username")
		end

	deleted_users: ARRAYED_LIST [DMS_USER]
			-- Get only soft-deleted users (trash).
		do
			Result := query_users ("SELECT * FROM users WHERE deleted_at IS NOT NULL ORDER BY deleted_at DESC")
		end

	update_user (a_user: DMS_USER)
			-- Update user.
		require
			not_new: not a_user.is_new
		local
			l_old_json: STRING_8
		do
			if attached find_user (a_user.id) as l_old then
				l_old_json := user_to_json (l_old)
			else
				l_old_json := "{}"
			end
			database.execute_with_args (
				"UPDATE users SET display_name = ?, email = ?, preferences_json = ?, updated_at = datetime('now') WHERE id = ?",
				<<a_user.display_name, a_user.email, a_user.preferences_json, a_user.id>>
			)
			log_audit (a_user.id, "update", "user", a_user.id, l_old_json, user_to_json (a_user))
		end

	soft_delete_user (a_user_id: INTEGER_64; a_deleted_by: INTEGER_64)
			-- Soft delete a user.
		require
			valid_user: a_user_id > 0
		do
			database.execute_with_args (
				"UPDATE users SET deleted_at = datetime('now'), updated_at = datetime('now') WHERE id = ?",
				<<a_user_id>>
			)
			log_audit (a_deleted_by, "soft_delete", "user", a_user_id, Void, Void)
		end

	restore_user (a_user_id: INTEGER_64; a_restored_by: INTEGER_64)
			-- Restore a soft-deleted user.
		require
			valid_user: a_user_id > 0
		do
			database.execute_with_args (
				"UPDATE users SET deleted_at = NULL, updated_at = datetime('now') WHERE id = ?",
				<<a_user_id>>
			)
			log_audit (a_restored_by, "restore", "user", a_user_id, Void, Void)
		end

	permanently_delete_user (a_user_id: INTEGER_64; a_deleted_by: INTEGER_64)
			-- Permanently delete a user (hard delete).
		require
			valid_user: a_user_id > 0
		do
			log_audit (a_deleted_by, "delete", "user", a_user_id, Void, Void)
			database.execute_with_args ("DELETE FROM users WHERE id = ?", <<a_user_id>>)
		end

	user_count: INTEGER
			-- Count of active users.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query ("SELECT COUNT(*) as cnt FROM users WHERE deleted_at IS NULL")
			if not l_result.is_empty then
				Result := l_result.first.integer_value ("cnt")
			end
		end

feature -- Folder Management (CRUD Boilerplate Example #2 + Hierarchy)

	create_root_folder (a_owner_id: INTEGER_64): DMS_FOLDER
			-- Create root folder for a user.
		require
			valid_owner: a_owner_id > 0
		local
			l_folder: DMS_FOLDER
			l_result: SIMPLE_SQL_RESULT
		do
			create l_folder.make_root (a_owner_id)
			database.execute_with_args (
				"INSERT INTO folders (owner_id, parent_id, name, path) VALUES (?, NULL, ?, ?)",
				<<a_owner_id, l_folder.name, l_folder.path>>
			)
			l_folder.set_id (database.last_insert_rowid)
			l_result := database.query_with_args ("SELECT created_at, updated_at FROM folders WHERE id = ?", <<l_folder.id>>)
			if not l_result.is_empty then
				l_folder.set_created_at (l_result.first.string_value ("created_at").to_string_8)
				l_folder.set_updated_at (l_result.first.string_value ("updated_at").to_string_8)
			end
			Result := l_folder
		ensure
			result_saved: not Result.is_new
			is_root: Result.is_root
		end

	create_folder (a_owner_id, a_parent_id: INTEGER_64; a_name: READABLE_STRING_8): DMS_FOLDER
			-- Create a subfolder.
		require
			valid_owner: a_owner_id > 0
			valid_parent: a_parent_id > 0
			name_not_empty: not a_name.is_empty
		local
			l_folder: DMS_FOLDER
			l_parent_path: STRING_8
			l_result: SIMPLE_SQL_RESULT
		do
			-- Get parent path
			l_result := database.query_with_args ("SELECT path FROM folders WHERE id = ?", <<a_parent_id>>)
			if not l_result.is_empty then
				l_parent_path := l_result.first.string_value ("path").to_string_8
			else
				l_parent_path := "/"
			end

			create l_folder.make_new (a_owner_id, a_parent_id, a_name, l_parent_path)
			database.execute_with_args (
				"INSERT INTO folders (owner_id, parent_id, name, path) VALUES (?, ?, ?, ?)",
				<<a_owner_id, a_parent_id, l_folder.name, l_folder.path>>
			)
			l_folder.set_id (database.last_insert_rowid)
			l_result := database.query_with_args ("SELECT created_at, updated_at FROM folders WHERE id = ?", <<l_folder.id>>)
			if not l_result.is_empty then
				l_folder.set_created_at (l_result.first.string_value ("created_at").to_string_8)
				l_folder.set_updated_at (l_result.first.string_value ("updated_at").to_string_8)
			end
			log_audit (a_owner_id, "create", "folder", l_folder.id, Void, Void)
			Result := l_folder
		ensure
			result_saved: not Result.is_new
			not_root: not Result.is_root
		end

	find_folder (a_id: INTEGER_64): detachable DMS_FOLDER
			-- Find folder by ID.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args ("SELECT * FROM folders WHERE id = ?", <<a_id>>)
			if not l_result.is_empty then
				Result := row_to_folder (l_result.first)
			end
		end

	user_root_folder (a_owner_id: INTEGER_64): detachable DMS_FOLDER
			-- Get user's root folder.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args (
				"SELECT * FROM folders WHERE owner_id = ? AND parent_id IS NULL AND deleted_at IS NULL",
				<<a_owner_id>>
			)
			if not l_result.is_empty then
				Result := row_to_folder (l_result.first)
			end
		end

	folder_children (a_folder_id: INTEGER_64): ARRAYED_LIST [DMS_FOLDER]
			-- Get immediate child folders.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (10)
			l_result := database.query_with_args (
				"SELECT * FROM folders WHERE parent_id = ? AND deleted_at IS NULL ORDER BY name",
				<<a_folder_id>>
			)
			across l_result.rows as ic loop
				Result.extend (row_to_folder (ic))
			end
		end

	folder_descendants (a_folder_id: INTEGER_64): ARRAYED_LIST [DMS_FOLDER]
			-- Get all descendant folders (recursive).
			-- This exposes the need for recursive CTE support.
		local
			l_result: SIMPLE_SQL_RESULT
			l_path_prefix: STRING_8
		do
			create Result.make (20)
			-- Get the folder's path
			l_result := database.query_with_args ("SELECT path FROM folders WHERE id = ?", <<a_folder_id>>)
			if not l_result.is_empty then
				l_path_prefix := l_result.first.string_value ("path").to_string_8
				-- Find all folders with paths starting with this path
				-- This is a workaround for lack of recursive CTE support
				l_result := database.query_with_args (
					"SELECT * FROM folders WHERE path LIKE ? AND id != ? AND deleted_at IS NULL ORDER BY path",
					<<l_path_prefix + "/%%", a_folder_id>>
				)
				across l_result.rows as ic loop
					Result.extend (row_to_folder (ic))
				end
			end
		end

	move_folder (a_folder_id, a_new_parent_id: INTEGER_64; a_moved_by: INTEGER_64)
			-- Move folder to new parent.
			-- This is a complex operation requiring transaction for atomicity.
		require
			valid_folder: a_folder_id > 0
			valid_parent: a_new_parent_id > 0
		local
			l_old_path, l_new_parent_path, l_new_path, l_folder_name: STRING_8
			l_result: SIMPLE_SQL_RESULT
		do
			-- TRANSACTION PAIN POINT: This should be atomic
			-- Get old path
			l_result := database.query_with_args ("SELECT name, path FROM folders WHERE id = ?", <<a_folder_id>>)
			if not l_result.is_empty then
				l_folder_name := l_result.first.string_value ("name").to_string_8
				l_old_path := l_result.first.string_value ("path").to_string_8

				-- Get new parent path
				l_result := database.query_with_args ("SELECT path FROM folders WHERE id = ?", <<a_new_parent_id>>)
				if not l_result.is_empty then
					l_new_parent_path := l_result.first.string_value ("path").to_string_8
					l_new_path := l_new_parent_path + "/" + l_folder_name

					-- Update folder
					database.execute_with_args (
						"UPDATE folders SET parent_id = ?, path = ?, updated_at = datetime('now') WHERE id = ?",
						<<a_new_parent_id, l_new_path, a_folder_id>>
					)

					-- Update all descendant paths
					database.execute_with_args (
						"UPDATE folders SET path = ? || substr(path, ?) WHERE path LIKE ?",
						<<l_new_path, l_old_path.count + 1, l_old_path + "/%%">>
					)

					-- Update all documents in moved folders
					database.execute_with_args (
						"UPDATE documents SET updated_at = datetime('now') WHERE folder_id IN (SELECT id FROM folders WHERE path LIKE ?)",
						<<l_new_path + "%%">>
					)

					log_audit (a_moved_by, "move", "folder", a_folder_id, l_old_path, l_new_path)
				end
			end
		end

	soft_delete_folder (a_folder_id: INTEGER_64; a_deleted_by: INTEGER_64)
			-- Soft delete folder and all contents.
		require
			valid_folder: a_folder_id > 0
		local
			l_path: STRING_8
			l_result: SIMPLE_SQL_RESULT
		do
			-- Get folder path
			l_result := database.query_with_args ("SELECT path FROM folders WHERE id = ?", <<a_folder_id>>)
			if not l_result.is_empty then
				l_path := l_result.first.string_value ("path").to_string_8

				-- Soft delete folder
				database.execute_with_args (
					"UPDATE folders SET deleted_at = datetime('now') WHERE id = ?",
					<<a_folder_id>>
				)

				-- Soft delete all subfolders
				database.execute_with_args (
					"UPDATE folders SET deleted_at = datetime('now') WHERE path LIKE ?",
					<<l_path + "/%%">>
				)

				-- Soft delete all documents in folder and subfolders
				database.execute_with_args (
					"UPDATE documents SET deleted_at = datetime('now') WHERE folder_id IN (SELECT id FROM folders WHERE path LIKE ? OR id = ?)",
					<<l_path + "/%%", a_folder_id>>
				)

				log_audit (a_deleted_by, "soft_delete", "folder", a_folder_id, Void, Void)
			end
		end

	folder_count (a_owner_id: INTEGER_64): INTEGER
			-- Count active folders for user.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args (
				"SELECT COUNT(*) as cnt FROM folders WHERE owner_id = ? AND deleted_at IS NULL",
				<<a_owner_id>>
			)
			if not l_result.is_empty then
				Result := l_result.first.integer_value ("cnt")
			end
		end

feature -- Document Management (CRUD Boilerplate Example #3 + Versioning)

	create_document (a_owner_id, a_folder_id: INTEGER_64; a_title, a_content: READABLE_STRING_8): DMS_DOCUMENT
			-- Create a new document with initial version.
		require
			valid_owner: a_owner_id > 0
			valid_folder: a_folder_id > 0
			title_not_empty: not a_title.is_empty
		local
			l_doc: DMS_DOCUMENT
			l_result: SIMPLE_SQL_RESULT
		do
			create l_doc.make_new (a_owner_id, a_folder_id, a_title, a_content, "text/plain")
			database.execute_with_args (
				"INSERT INTO documents (owner_id, folder_id, title, content, mime_type, file_size, current_version) VALUES (?, ?, ?, ?, ?, ?, 1)",
				<<a_owner_id, a_folder_id, a_title, a_content, l_doc.mime_type, l_doc.file_size>>
			)
			l_doc.set_id (database.last_insert_rowid)
			l_result := database.query_with_args ("SELECT created_at, updated_at FROM documents WHERE id = ?", <<l_doc.id>>)
			if not l_result.is_empty then
				l_doc.set_created_at (l_result.first.string_value ("created_at").to_string_8)
				l_doc.set_updated_at (l_result.first.string_value ("updated_at").to_string_8)
			end

			-- Create initial version
			create_document_version (l_doc.id, 1, a_title, a_content, a_owner_id, "Initial version")

			-- Update FTS index
			update_fts_index (l_doc.id, a_title, a_content)

			log_audit (a_owner_id, "create", "document", l_doc.id, Void, document_to_json (l_doc))
			Result := l_doc
		ensure
			result_saved: not Result.is_new
			version_1: Result.current_version = 1
		end

	find_document (a_id: INTEGER_64): detachable DMS_DOCUMENT
			-- Find document by ID.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args ("SELECT * FROM documents WHERE id = ?", <<a_id>>)
			if not l_result.is_empty then
				Result := row_to_document (l_result.first)
			end
		end

	folder_documents (a_folder_id: INTEGER_64): ARRAYED_LIST [DMS_DOCUMENT]
			-- Get all active documents in a folder.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (20)
			l_result := database.query_with_args (
				"SELECT * FROM documents WHERE folder_id = ? AND deleted_at IS NULL ORDER BY title",
				<<a_folder_id>>
			)
			across l_result.rows as ic loop
				Result.extend (row_to_document (ic))
			end
		end

	user_documents (a_owner_id: INTEGER_64): ARRAYED_LIST [DMS_DOCUMENT]
			-- Get all active documents for a user.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (50)
			l_result := database.query_with_args (
				"SELECT * FROM documents WHERE owner_id = ? AND deleted_at IS NULL ORDER BY updated_at DESC",
				<<a_owner_id>>
			)
			across l_result.rows as ic loop
				Result.extend (row_to_document (ic))
			end
		end

	update_document (a_document_id: INTEGER_64; a_title, a_content: READABLE_STRING_8;
			a_updated_by: INTEGER_64; a_change_summary: READABLE_STRING_8)
			-- Update document and create new version.
		require
			valid_document: a_document_id > 0
			title_not_empty: not a_title.is_empty
		local
			l_old_json: STRING_8
			l_new_version: INTEGER
			l_result: SIMPLE_SQL_RESULT
		do
			-- Get current state for audit
			if attached find_document (a_document_id) as l_old then
				l_old_json := document_to_json (l_old)
				l_new_version := l_old.current_version + 1
			else
				l_old_json := "{}"
				l_new_version := 1
			end

			-- Update document
			database.execute_with_args (
				"UPDATE documents SET title = ?, content = ?, file_size = ?, current_version = ?, updated_at = datetime('now') WHERE id = ?",
				<<a_title, a_content, a_content.count, l_new_version, a_document_id>>
			)

			-- Create version record
			create_document_version (a_document_id, l_new_version, a_title, a_content, a_updated_by, a_change_summary)

			-- Update FTS index
			update_fts_index (a_document_id, a_title, a_content)

			-- Audit
			l_result := database.query_with_args ("SELECT * FROM documents WHERE id = ?", <<a_document_id>>)
			if not l_result.is_empty then
				log_audit (a_updated_by, "update", "document", a_document_id, l_old_json, document_to_json (row_to_document (l_result.first)))
			end
		end

	soft_delete_document (a_document_id: INTEGER_64; a_deleted_by: INTEGER_64)
			-- Move document to trash.
		require
			valid_document: a_document_id > 0
		do
			database.execute_with_args (
				"UPDATE documents SET deleted_at = datetime('now'), updated_at = datetime('now') WHERE id = ?",
				<<a_document_id>>
			)
			log_audit (a_deleted_by, "soft_delete", "document", a_document_id, Void, Void)
		end

	restore_document (a_document_id: INTEGER_64; a_restored_by: INTEGER_64)
			-- Restore document from trash.
		require
			valid_document: a_document_id > 0
		do
			database.execute_with_args (
				"UPDATE documents SET deleted_at = NULL, updated_at = datetime('now') WHERE id = ?",
				<<a_document_id>>
			)
			log_audit (a_restored_by, "restore", "document", a_document_id, Void, Void)
		end

	permanently_delete_document (a_document_id: INTEGER_64; a_deleted_by: INTEGER_64)
			-- Hard delete document and all versions.
		require
			valid_document: a_document_id > 0
		do
			log_audit (a_deleted_by, "delete", "document", a_document_id, Void, Void)
			-- Delete FTS entry
			database.execute_with_args ("DELETE FROM documents_fts WHERE rowid = ?", <<a_document_id>>)
			-- Delete versions
			database.execute_with_args ("DELETE FROM document_versions WHERE document_id = ?", <<a_document_id>>)
			-- Delete comments
			database.execute_with_args ("DELETE FROM comments WHERE document_id = ?", <<a_document_id>>)
			-- Delete tags
			database.execute_with_args ("DELETE FROM document_tags WHERE document_id = ?", <<a_document_id>>)
			-- Delete shares
			database.execute_with_args ("DELETE FROM shares WHERE document_id = ?", <<a_document_id>>)
			-- Delete document
			database.execute_with_args ("DELETE FROM documents WHERE id = ?", <<a_document_id>>)
		end

	trashed_documents (a_owner_id: INTEGER_64): ARRAYED_LIST [DMS_DOCUMENT]
			-- Get documents in trash for user.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (20)
			l_result := database.query_with_args (
				"SELECT * FROM documents WHERE owner_id = ? AND deleted_at IS NOT NULL ORDER BY deleted_at DESC",
				<<a_owner_id>>
			)
			across l_result.rows as ic loop
				Result.extend (row_to_document (ic))
			end
		end

	document_count (a_owner_id: INTEGER_64): INTEGER
			-- Count active documents for user.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args (
				"SELECT COUNT(*) as cnt FROM documents WHERE owner_id = ? AND deleted_at IS NULL",
				<<a_owner_id>>
			)
			if not l_result.is_empty then
				Result := l_result.first.integer_value ("cnt")
			end
		end

	record_document_access (a_document_id: INTEGER_64; a_user_id: INTEGER_64)
			-- Record that a document was accessed.
		do
			database.execute_with_args (
				"UPDATE documents SET last_accessed_at = datetime('now') WHERE id = ?",
				<<a_document_id>>
			)
			log_audit (a_user_id, "read", "document", a_document_id, Void, Void)
		end

feature -- Document Version Management

	create_document_version (a_document_id: INTEGER_64; a_version_number: INTEGER;
			a_title, a_content: READABLE_STRING_8;
			a_created_by: INTEGER_64; a_change_summary: READABLE_STRING_8)
			-- Create a version snapshot.
		require
			valid_document: a_document_id > 0
			valid_version: a_version_number > 0
		do
			database.execute_with_args (
				"INSERT INTO document_versions (document_id, version_number, title, content, file_size, created_by, change_summary) VALUES (?, ?, ?, ?, ?, ?, ?)",
				<<a_document_id, a_version_number, a_title, a_content, a_content.count, a_created_by, a_change_summary>>
			)
			log_audit (a_created_by, "version", "document", a_document_id, Void, Void)
		end

	document_versions (a_document_id: INTEGER_64): ARRAYED_LIST [DMS_DOCUMENT_VERSION]
			-- Get all versions for a document.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (10)
			l_result := database.query_with_args (
				"SELECT * FROM document_versions WHERE document_id = ? ORDER BY version_number DESC",
				<<a_document_id>>
			)
			across l_result.rows as ic loop
				Result.extend (row_to_document_version (ic))
			end
		end

	find_document_version (a_document_id: INTEGER_64; a_version_number: INTEGER): detachable DMS_DOCUMENT_VERSION
			-- Find specific version of a document.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args (
				"SELECT * FROM document_versions WHERE document_id = ? AND version_number = ?",
				<<a_document_id, a_version_number>>
			)
			if not l_result.is_empty then
				Result := row_to_document_version (l_result.first)
			end
		end

	restore_document_version (a_document_id: INTEGER_64; a_version_number: INTEGER; a_restored_by: INTEGER_64)
			-- Restore document to a previous version (creates new version with old content).
		local
			l_version: detachable DMS_DOCUMENT_VERSION
		do
			l_version := find_document_version (a_document_id, a_version_number)
			if attached l_version then
				update_document (a_document_id, l_version.title, l_version.content, a_restored_by,
					"Restored from version " + a_version_number.out)
			end
		end

	version_count (a_document_id: INTEGER_64): INTEGER
			-- Count versions for document.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args (
				"SELECT COUNT(*) as cnt FROM document_versions WHERE document_id = ?",
				<<a_document_id>>
			)
			if not l_result.is_empty then
				Result := l_result.first.integer_value ("cnt")
			end
		end

feature -- Comment Management (N+1 Problem Exposure)

	add_comment (a_document_id, a_user_id: INTEGER_64; a_content: READABLE_STRING_8): DMS_COMMENT
			-- Add a comment to a document.
		require
			valid_document: a_document_id > 0
			valid_user: a_user_id > 0
			content_not_empty: not a_content.is_empty
		local
			l_comment: DMS_COMMENT
			l_result: SIMPLE_SQL_RESULT
		do
			create l_comment.make_new (a_document_id, a_user_id, a_content)
			database.execute_with_args (
				"INSERT INTO comments (document_id, user_id, content) VALUES (?, ?, ?)",
				<<a_document_id, a_user_id, a_content>>
			)
			l_comment.set_id (database.last_insert_rowid)
			l_result := database.query_with_args ("SELECT created_at, updated_at FROM comments WHERE id = ?", <<l_comment.id>>)
			if not l_result.is_empty then
				l_comment.set_created_at (l_result.first.string_value ("created_at").to_string_8)
				l_comment.set_updated_at (l_result.first.string_value ("updated_at").to_string_8)
			end
			log_audit (a_user_id, "comment", "document", a_document_id, Void, Void)
			Result := l_comment
		ensure
			result_saved: not Result.is_new
		end

	reply_to_comment (a_document_id, a_user_id, a_parent_comment_id: INTEGER_64; a_content: READABLE_STRING_8): DMS_COMMENT
			-- Reply to an existing comment.
		require
			valid_document: a_document_id > 0
			valid_user: a_user_id > 0
			valid_parent: a_parent_comment_id > 0
			content_not_empty: not a_content.is_empty
		local
			l_comment: DMS_COMMENT
			l_result: SIMPLE_SQL_RESULT
		do
			create l_comment.make_new (a_document_id, a_user_id, a_content)
			l_comment.set_parent_comment_id (a_parent_comment_id)
			database.execute_with_args (
				"INSERT INTO comments (document_id, user_id, parent_comment_id, content) VALUES (?, ?, ?, ?)",
				<<a_document_id, a_user_id, a_parent_comment_id, a_content>>
			)
			l_comment.set_id (database.last_insert_rowid)
			l_result := database.query_with_args ("SELECT created_at, updated_at FROM comments WHERE id = ?", <<l_comment.id>>)
			if not l_result.is_empty then
				l_comment.set_created_at (l_result.first.string_value ("created_at").to_string_8)
				l_comment.set_updated_at (l_result.first.string_value ("updated_at").to_string_8)
			end
			Result := l_comment
		ensure
			result_saved: not Result.is_new
			is_reply: Result.is_reply
		end

	document_comments (a_document_id: INTEGER_64): ARRAYED_LIST [DMS_COMMENT]
			-- Get all comments for a document (exposes N+1 problem).
			-- To display "John Doe commented: ..." we need to fetch each user.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (20)
			l_result := database.query_with_args (
				"SELECT * FROM comments WHERE document_id = ? AND deleted_at IS NULL ORDER BY created_at",
				<<a_document_id>>
			)
			across l_result.rows as ic loop
				Result.extend (row_to_comment (ic))
			end
			-- N+1 PROBLEM: Now we need to fetch user names for each comment!
			-- Without eager loading, this becomes O(n) queries.
		end

	document_comments_with_users (a_document_id: INTEGER_64): ARRAYED_LIST [DMS_COMMENT]
			-- Get comments with user display names pre-fetched (N+1 solution via JOIN).
		local
			l_result: SIMPLE_SQL_RESULT
			l_comment: DMS_COMMENT
		do
			create Result.make (20)
			l_result := database.query_with_args (
				"SELECT c.*, u.display_name as user_display_name FROM comments c JOIN users u ON c.user_id = u.id WHERE c.document_id = ? AND c.deleted_at IS NULL ORDER BY c.created_at",
				<<a_document_id>>
			)
			across l_result.rows as ic loop
				l_comment := row_to_comment (ic)
				-- Set cached user name from join
				l_comment.set_cached_user_display_name (ic.string_value ("user_display_name").to_string_8)
				Result.extend (l_comment)
			end
		end

	comment_count (a_document_id: INTEGER_64): INTEGER
			-- Count comments on document.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args (
				"SELECT COUNT(*) as cnt FROM comments WHERE document_id = ? AND deleted_at IS NULL",
				<<a_document_id>>
			)
			if not l_result.is_empty then
				Result := l_result.first.integer_value ("cnt")
			end
		end

	soft_delete_comment (a_comment_id: INTEGER_64; a_deleted_by: INTEGER_64)
			-- Soft delete a comment.
		do
			database.execute_with_args (
				"UPDATE comments SET deleted_at = datetime('now') WHERE id = ?",
				<<a_comment_id>>
			)
			log_audit (a_deleted_by, "soft_delete", "comment", a_comment_id, Void, Void)
		end

feature -- Tag Management (Many-to-Many Relationship)

	create_tag (a_owner_id: INTEGER_64; a_name: READABLE_STRING_8): DMS_TAG
			-- Create a new tag.
		require
			valid_owner: a_owner_id > 0
			name_not_empty: not a_name.is_empty
		local
			l_tag: DMS_TAG
			l_result: SIMPLE_SQL_RESULT
		do
			create l_tag.make_new (a_owner_id, a_name)
			database.execute_with_args (
				"INSERT INTO tags (owner_id, name) VALUES (?, ?)",
				<<a_owner_id, a_name>>
			)
			l_tag.set_id (database.last_insert_rowid)
			l_result := database.query_with_args ("SELECT created_at FROM tags WHERE id = ?", <<l_tag.id>>)
			if not l_result.is_empty then
				l_tag.set_created_at (l_result.first.string_value ("created_at").to_string_8)
			end
			Result := l_tag
		ensure
			result_saved: not Result.is_new
		end

	find_tag (a_id: INTEGER_64): detachable DMS_TAG
			-- Find tag by ID.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args ("SELECT * FROM tags WHERE id = ?", <<a_id>>)
			if not l_result.is_empty then
				Result := row_to_tag (l_result.first)
			end
		end

	user_tags (a_owner_id: INTEGER_64): ARRAYED_LIST [DMS_TAG]
			-- Get all tags for a user.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (20)
			l_result := database.query_with_args (
				"SELECT * FROM tags WHERE owner_id = ? ORDER BY name",
				<<a_owner_id>>
			)
			across l_result.rows as ic loop
				Result.extend (row_to_tag (ic))
			end
		end

	tag_document (a_document_id, a_tag_id, a_tagged_by: INTEGER_64)
			-- Add tag to document.
		require
			valid_document: a_document_id > 0
			valid_tag: a_tag_id > 0
		do
			database.execute_with_args (
				"INSERT OR IGNORE INTO document_tags (document_id, tag_id, tagged_by) VALUES (?, ?, ?)",
				<<a_document_id, a_tag_id, a_tagged_by>>
			)
			log_audit (a_tagged_by, "tag", "document", a_document_id, Void, Void)
		end

	untag_document (a_document_id, a_tag_id: INTEGER_64; a_untagged_by: INTEGER_64)
			-- Remove tag from document.
		do
			database.execute_with_args (
				"DELETE FROM document_tags WHERE document_id = ? AND tag_id = ?",
				<<a_document_id, a_tag_id>>
			)
			log_audit (a_untagged_by, "untag", "document", a_document_id, Void, Void)
		end

	document_tags (a_document_id: INTEGER_64): ARRAYED_LIST [DMS_TAG]
			-- Get all tags for a document.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (10)
			l_result := database.query_with_args (
				"SELECT t.* FROM tags t JOIN document_tags dt ON t.id = dt.tag_id WHERE dt.document_id = ? ORDER BY t.name",
				<<a_document_id>>
			)
			across l_result.rows as ic loop
				Result.extend (row_to_tag (ic))
			end
		end

	documents_with_tag (a_tag_id: INTEGER_64): ARRAYED_LIST [DMS_DOCUMENT]
			-- Get all documents with a specific tag.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (20)
			l_result := database.query_with_args (
				"SELECT d.* FROM documents d JOIN document_tags dt ON d.id = dt.document_id WHERE dt.tag_id = ? AND d.deleted_at IS NULL ORDER BY d.title",
				<<a_tag_id>>
			)
			across l_result.rows as ic loop
				Result.extend (row_to_document (ic))
			end
		end

feature -- Sharing (JSON Permissions)

	share_document_with_user (a_document_id, a_owner_id, a_shared_with: INTEGER_64;
			a_permissions_json: READABLE_STRING_8): DMS_SHARE
			-- Share document with another user.
		require
			valid_document: a_document_id > 0
			valid_owner: a_owner_id > 0
			valid_user: a_shared_with > 0
		local
			l_share: DMS_SHARE
			l_result: SIMPLE_SQL_RESULT
		do
			create l_share.make_new (a_owner_id, a_shared_with, a_permissions_json)
			l_share.set_document_id (a_document_id)
			database.execute_with_args (
				"INSERT INTO shares (document_id, owner_id, shared_with_user_id, permissions_json) VALUES (?, ?, ?, ?)",
				<<a_document_id, a_owner_id, a_shared_with, a_permissions_json>>
			)
			l_share.set_id (database.last_insert_rowid)
			l_result := database.query_with_args ("SELECT created_at FROM shares WHERE id = ?", <<l_share.id>>)
			if not l_result.is_empty then
				l_share.set_created_at (l_result.first.string_value ("created_at").to_string_8)
			end
			log_audit (a_owner_id, "share", "document", a_document_id, Void, a_permissions_json)
			Result := l_share
		ensure
			result_saved: not Result.is_new
		end

	document_shares (a_document_id: INTEGER_64): ARRAYED_LIST [DMS_SHARE]
			-- Get all active shares for a document.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (10)
			l_result := database.query_with_args (
				"SELECT * FROM shares WHERE document_id = ? AND revoked_at IS NULL",
				<<a_document_id>>
			)
			across l_result.rows as ic loop
				Result.extend (row_to_share (ic))
			end
		end

	documents_shared_with_user (a_user_id: INTEGER_64): ARRAYED_LIST [DMS_DOCUMENT]
			-- Get documents shared with a user.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (20)
			l_result := database.query_with_args (
				"SELECT d.* FROM documents d JOIN shares s ON d.id = s.document_id WHERE s.shared_with_user_id = ? AND s.revoked_at IS NULL AND d.deleted_at IS NULL ORDER BY d.title",
				<<a_user_id>>
			)
			across l_result.rows as ic loop
				Result.extend (row_to_document (ic))
			end
		end

	can_user_access_document (a_user_id, a_document_id: INTEGER_64): BOOLEAN
			-- Check if user can access document (owner or shared with).
		local
			l_result: SIMPLE_SQL_RESULT
		do
			-- Check ownership
			l_result := database.query_with_args (
				"SELECT id FROM documents WHERE id = ? AND owner_id = ? AND deleted_at IS NULL",
				<<a_document_id, a_user_id>>
			)
			if not l_result.is_empty then
				Result := True
			else
				-- Check shares
				l_result := database.query_with_args (
					"SELECT id FROM shares WHERE document_id = ? AND shared_with_user_id = ? AND revoked_at IS NULL",
					<<a_document_id, a_user_id>>
				)
				Result := not l_result.is_empty
			end
		end

	revoke_share (a_share_id: INTEGER_64; a_revoked_by: INTEGER_64)
			-- Revoke a share.
		do
			database.execute_with_args (
				"UPDATE shares SET revoked_at = datetime('now') WHERE id = ?",
				<<a_share_id>>
			)
			log_audit (a_revoked_by, "unshare", "share", a_share_id, Void, Void)
		end

feature -- Full-Text Search (FTS5)

	search_documents (a_query: READABLE_STRING_8; a_owner_id: INTEGER_64): ARRAYED_LIST [DMS_DOCUMENT]
			-- Search documents using FTS5.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (20)
			l_result := database.query_with_args (
				"SELECT d.* FROM documents d JOIN documents_fts fts ON d.id = fts.rowid WHERE documents_fts MATCH ? AND d.owner_id = ? AND d.deleted_at IS NULL ORDER BY rank",
				<<a_query, a_owner_id>>
			)
			across l_result.rows as ic loop
				Result.extend (row_to_document (ic))
			end
		end

	search_documents_with_snippets (a_query: READABLE_STRING_8; a_owner_id: INTEGER_64): ARRAYED_LIST [TUPLE [document: DMS_DOCUMENT; snippet: STRING_8]]
			-- Search with highlighted snippets.
		local
			l_result: SIMPLE_SQL_RESULT
			l_doc: DMS_DOCUMENT
			l_snippet: STRING_8
		do
			create Result.make (20)
			l_result := database.query_with_args (
				"SELECT d.*, snippet(documents_fts, 1, '<b>', '</b>', '...', 32) as snippet FROM documents d JOIN documents_fts fts ON d.id = fts.rowid WHERE documents_fts MATCH ? AND d.owner_id = ? AND d.deleted_at IS NULL ORDER BY rank",
				<<a_query, a_owner_id>>
			)
			across l_result.rows as ic loop
				l_doc := row_to_document (ic)
				l_snippet := ic.string_value ("snippet").to_string_8
				Result.extend ([l_doc, l_snippet])
			end
		end

	update_fts_index (a_document_id: INTEGER_64; a_title, a_content: READABLE_STRING_8)
			-- Update FTS index for a document.
		do
			-- Delete old entry
			database.execute_with_args ("DELETE FROM documents_fts WHERE rowid = ?", <<a_document_id>>)
			-- Insert new entry
			database.execute_with_args (
				"INSERT INTO documents_fts (rowid, title, content) VALUES (?, ?, ?)",
				<<a_document_id, a_title, a_content>>
			)
		end

feature -- Cursor-Based Pagination

	documents_paginated (a_owner_id: INTEGER_64; a_cursor: detachable STRING_8; a_limit: INTEGER): TUPLE [documents: ARRAYED_LIST [DMS_DOCUMENT]; next_cursor: detachable STRING_8]
			-- Get documents with cursor-based pagination.
			-- Cursor format: "last_updated_at|last_id" (using | to avoid conflict with timestamp colons)
		local
			l_result: SIMPLE_SQL_RESULT
			l_docs: ARRAYED_LIST [DMS_DOCUMENT]
			l_doc: DMS_DOCUMENT
			l_sql: STRING_8
			l_next_cursor: detachable STRING_8
			l_cursor_updated_at: STRING_8
			l_cursor_id: INTEGER_64
			l_parts: LIST [STRING_8]
		do
			create l_docs.make (a_limit)

			-- Parse cursor (format: "updated_at|id")
			if attached a_cursor as c and then not c.is_empty then
				l_parts := c.split ('|')
				if l_parts.count >= 2 then
					l_cursor_updated_at := l_parts [1]
					l_cursor_id := l_parts [2].to_integer_64
					l_sql := "SELECT * FROM documents WHERE owner_id = ? AND deleted_at IS NULL AND (updated_at < ? OR (updated_at = ? AND id < ?)) ORDER BY updated_at DESC, id DESC LIMIT ?"
					l_result := database.query_with_args (l_sql, <<a_owner_id, l_cursor_updated_at, l_cursor_updated_at, l_cursor_id, a_limit + 1>>)
				else
					l_result := database.query_with_args (
						"SELECT * FROM documents WHERE owner_id = ? AND deleted_at IS NULL ORDER BY updated_at DESC, id DESC LIMIT ?",
						<<a_owner_id, a_limit + 1>>
					)
				end
			else
				l_result := database.query_with_args (
					"SELECT * FROM documents WHERE owner_id = ? AND deleted_at IS NULL ORDER BY updated_at DESC, id DESC LIMIT ?",
					<<a_owner_id, a_limit + 1>>
				)
			end

			-- Process results
			across l_result.rows as ic loop
				if l_docs.count < a_limit then
					l_doc := row_to_document (ic)
					l_docs.extend (l_doc)
				end
			end

			-- Build next cursor if there are more results
			if l_result.rows.count > a_limit and then not l_docs.is_empty then
				l_doc := l_docs.last
				l_next_cursor := l_doc.updated_at + "|" + l_doc.id.out
			end

			Result := [l_docs, l_next_cursor]
		end

	activity_feed_paginated (a_user_id: INTEGER_64; a_cursor: detachable STRING_8; a_limit: INTEGER): TUPLE [entries: ARRAYED_LIST [DMS_AUDIT_LOG]; next_cursor: detachable STRING_8]
			-- Get audit log with cursor pagination.
		local
			l_result: SIMPLE_SQL_RESULT
			l_entries: ARRAYED_LIST [DMS_AUDIT_LOG]
			l_entry: DMS_AUDIT_LOG
			l_cursor_id: INTEGER_64
			l_next_cursor: detachable STRING_8
		do
			create l_entries.make (a_limit)

			if attached a_cursor as c and then not c.is_empty then
				l_cursor_id := c.to_integer_64
				l_result := database.query_with_args (
					"SELECT * FROM audit_log WHERE user_id = ? AND id < ? ORDER BY id DESC LIMIT ?",
					<<a_user_id, l_cursor_id, a_limit + 1>>
				)
			else
				l_result := database.query_with_args (
					"SELECT * FROM audit_log WHERE user_id = ? ORDER BY id DESC LIMIT ?",
					<<a_user_id, a_limit + 1>>
				)
			end

			across l_result.rows as ic loop
				if l_entries.count < a_limit then
					l_entry := row_to_audit_log (ic)
					l_entries.extend (l_entry)
				end
			end

			if l_result.rows.count > a_limit and then not l_entries.is_empty then
				l_next_cursor := l_entries.last.id.out
			end

			Result := [l_entries, l_next_cursor]
		end

feature -- Audit Trail

	log_audit (a_user_id: INTEGER_64; a_action, a_entity_type: READABLE_STRING_8;
			a_entity_id: INTEGER_64; a_old_value, a_new_value: detachable READABLE_STRING_8)
			-- Record an audit log entry.
		do
			database.execute_with_args (
				"INSERT INTO audit_log (user_id, action, entity_type, entity_id, old_value_json, new_value_json) VALUES (?, ?, ?, ?, ?, ?)",
				<<a_user_id, a_action, a_entity_type, a_entity_id, a_old_value, a_new_value>>
			)
		end

	entity_audit_trail (a_entity_type: READABLE_STRING_8; a_entity_id: INTEGER_64): ARRAYED_LIST [DMS_AUDIT_LOG]
			-- Get complete audit trail for an entity.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (50)
			l_result := database.query_with_args (
				"SELECT * FROM audit_log WHERE entity_type = ? AND entity_id = ? ORDER BY created_at DESC",
				<<a_entity_type, a_entity_id>>
			)
			across l_result.rows as ic loop
				Result.extend (row_to_audit_log (ic))
			end
		end

	user_activity (a_user_id: INTEGER_64; a_limit: INTEGER): ARRAYED_LIST [DMS_AUDIT_LOG]
			-- Get recent activity for a user.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (a_limit)
			l_result := database.query_with_args (
				"SELECT * FROM audit_log WHERE user_id = ? ORDER BY created_at DESC LIMIT ?",
				<<a_user_id, a_limit>>
			)
			across l_result.rows as ic loop
				Result.extend (row_to_audit_log (ic))
			end
		end

	audit_log_count: INTEGER
			-- Total audit log entries.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query ("SELECT COUNT(*) as cnt FROM audit_log")
			if not l_result.is_empty then
				Result := l_result.first.integer_value ("cnt")
			end
		end

feature -- Trash Management (Soft Delete System)

	empty_trash (a_owner_id: INTEGER_64; a_days_old: INTEGER)
			-- Permanently delete items in trash older than N days.
		do
			-- Delete old documents
			database.execute_with_args (
				"DELETE FROM documents WHERE owner_id = ? AND deleted_at IS NOT NULL AND deleted_at < datetime('now', ?)",
				<<a_owner_id, "-" + a_days_old.out + " days">>
			)
			-- Delete old folders
			database.execute_with_args (
				"DELETE FROM folders WHERE owner_id = ? AND deleted_at IS NOT NULL AND deleted_at < datetime('now', ?)",
				<<a_owner_id, "-" + a_days_old.out + " days">>
			)
		end

	trash_count (a_owner_id: INTEGER_64): INTEGER
			-- Count items in trash.
		local
			l_result: SIMPLE_SQL_RESULT
			l_doc_count, l_folder_count: INTEGER
		do
			l_result := database.query_with_args (
				"SELECT COUNT(*) as cnt FROM documents WHERE owner_id = ? AND deleted_at IS NOT NULL",
				<<a_owner_id>>
			)
			if not l_result.is_empty then
				l_doc_count := l_result.first.integer_value ("cnt")
			end
			l_result := database.query_with_args (
				"SELECT COUNT(*) as cnt FROM folders WHERE owner_id = ? AND deleted_at IS NOT NULL AND parent_id IS NOT NULL",
				<<a_owner_id>>
			)
			if not l_result.is_empty then
				l_folder_count := l_result.first.integer_value ("cnt")
			end
			Result := l_doc_count + l_folder_count
		end

feature -- Schema Migration

	current_schema_version: INTEGER
			-- Get current schema version.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query ("SELECT MAX(version) as ver FROM schema_versions")
			if not l_result.is_empty and then not l_result.first.is_null ("ver") then
				Result := l_result.first.integer_value ("ver")
			end
		end

	applied_migrations: ARRAYED_LIST [DMS_SCHEMA_VERSION]
			-- Get all applied migrations.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (10)
			l_result := database.query ("SELECT * FROM schema_versions ORDER BY version")
			across l_result.rows as ic loop
				Result.extend (row_to_schema_version (ic))
			end
		end

feature {NONE} -- Row Mappers (CRUD Boilerplate - repeated pattern)
	-- This section exposes the repetitive nature of row-to-object mapping

	row_to_user (a_row: SIMPLE_SQL_ROW): DMS_USER
			-- Convert database row to user object.
		do
			create Result.make (
				a_row.integer_64_value ("id"),
				a_row.string_value ("username").to_string_8,
				a_row.string_value ("email").to_string_8,
				a_row.string_value_or_default ("display_name", ""),
				a_row.string_value_or_void ("preferences_json"),
				a_row.string_value ("created_at").to_string_8,
				a_row.string_value ("updated_at").to_string_8,
				a_row.string_value_or_void ("deleted_at")
			)
		end

	row_to_folder (a_row: SIMPLE_SQL_ROW): DMS_FOLDER
			-- Convert database row to folder object.
		do
			create Result.make (
				a_row.integer_64_value ("id"),
				a_row.integer_64_value ("owner_id"),
				a_row.integer_64_value_or_void ("parent_id"),
				a_row.string_value ("name").to_string_8,
				a_row.string_value ("path").to_string_8,
				a_row.string_value ("created_at").to_string_8,
				a_row.string_value ("updated_at").to_string_8,
				a_row.string_value_or_void ("deleted_at")
			)
		end

	row_to_document (a_row: SIMPLE_SQL_ROW): DMS_DOCUMENT
			-- Convert database row to document object.
		do
			create Result.make (
				a_row.integer_64_value ("id"),
				a_row.integer_64_value ("owner_id"),
				a_row.integer_64_value ("folder_id"),
				a_row.string_value ("title").to_string_8,
				a_row.string_value ("content").to_string_8,
				a_row.string_value ("mime_type").to_string_8,
				a_row.integer_64_value ("file_size"),
				a_row.string_value_or_void ("checksum"),
				a_row.integer_value ("current_version"),
				a_row.string_value_or_void ("metadata_json"),
				a_row.string_value ("created_at").to_string_8,
				a_row.string_value ("updated_at").to_string_8,
				a_row.string_value_or_void ("deleted_at"),
				a_row.string_value_or_void ("expires_at"),
				a_row.string_value_or_void ("last_accessed_at")
			)
		end

	row_to_document_version (a_row: SIMPLE_SQL_ROW): DMS_DOCUMENT_VERSION
			-- Convert database row to document version object.
		do
			create Result.make (
				a_row.integer_64_value ("id"),
				a_row.integer_64_value ("document_id"),
				a_row.integer_value ("version_number"),
				a_row.string_value ("title").to_string_8,
				a_row.string_value ("content").to_string_8,
				a_row.integer_64_value ("file_size"),
				a_row.string_value_or_void ("checksum"),
				a_row.integer_64_value ("created_by"),
				a_row.string_value_or_void ("change_summary"),
				a_row.string_value ("created_at").to_string_8
			)
		end

	row_to_comment (a_row: SIMPLE_SQL_ROW): DMS_COMMENT
			-- Convert database row to comment object.
		do
			create Result.make (
				a_row.integer_64_value ("id"),
				a_row.integer_64_value ("document_id"),
				a_row.integer_64_value ("user_id"),
				a_row.integer_64_value_or_void ("parent_comment_id"),
				a_row.string_value ("content").to_string_8,
				a_row.string_value ("created_at").to_string_8,
				a_row.string_value ("updated_at").to_string_8,
				a_row.string_value_or_void ("deleted_at")
			)
		end

	row_to_tag (a_row: SIMPLE_SQL_ROW): DMS_TAG
			-- Convert database row to tag object.
		do
			create Result.make (
				a_row.integer_64_value ("id"),
				a_row.integer_64_value ("owner_id"),
				a_row.string_value ("name").to_string_8,
				a_row.string_value_or_void ("color"),
				a_row.string_value ("created_at").to_string_8
			)
		end

	row_to_share (a_row: SIMPLE_SQL_ROW): DMS_SHARE
			-- Convert database row to share object.
		do
			create Result.make (
				a_row.integer_64_value ("id"),
				a_row.integer_64_value_or_void ("document_id"),
				a_row.integer_64_value_or_void ("folder_id"),
				a_row.integer_64_value ("owner_id"),
				a_row.integer_64_value ("shared_with_user_id"),
				a_row.string_value ("permissions_json").to_string_8,
				a_row.string_value_or_void ("share_link"),
				a_row.string_value_or_void ("expires_at"),
				a_row.string_value ("created_at").to_string_8,
				a_row.string_value_or_void ("revoked_at")
			)
		end

	row_to_audit_log (a_row: SIMPLE_SQL_ROW): DMS_AUDIT_LOG
			-- Convert database row to audit log object.
		do
			create Result.make (
				a_row.integer_64_value ("id"),
				a_row.integer_64_value ("user_id"),
				a_row.string_value ("action").to_string_8,
				a_row.string_value ("entity_type").to_string_8,
				a_row.integer_64_value ("entity_id"),
				a_row.string_value_or_void ("old_value_json"),
				a_row.string_value_or_void ("new_value_json"),
				a_row.string_value_or_void ("ip_address"),
				a_row.string_value_or_void ("user_agent"),
				a_row.string_value ("created_at").to_string_8
			)
		end

	row_to_schema_version (a_row: SIMPLE_SQL_ROW): DMS_SCHEMA_VERSION
			-- Convert database row to schema version object.
		do
			create Result.make (
				a_row.integer_64_value ("id"),
				a_row.integer_value ("version"),
				a_row.string_value ("name").to_string_8,
				a_row.string_value ("description").to_string_8,
				a_row.string_value ("applied_at").to_string_8,
				a_row.string_value_or_void ("checksum"),
				a_row.integer_value_or_default ("execution_time_ms", 0)
			)
		end

feature {NONE} -- Query Helpers

	query_users (a_sql: READABLE_STRING_8): ARRAYED_LIST [DMS_USER]
			-- Execute query and return users.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (20)
			l_result := database.query (a_sql)
			across l_result.rows as ic loop
				Result.extend (row_to_user (ic))
			end
		end

feature {NONE} -- JSON Helpers (Exposes JSON pain point)

	user_to_json (a_user: DMS_USER): STRING_8
			-- Convert user to JSON for audit.
		do
			Result := "{%"id%": " + a_user.id.out + ", %"username%": %"" + a_user.username + "%", %"email%": %"" + a_user.email + "%"}"
		end

	document_to_json (a_doc: DMS_DOCUMENT): STRING_8
			-- Convert document to JSON for audit.
		do
			Result := "{%"id%": " + a_doc.id.out + ", %"title%": %"" + a_doc.title + "%", %"version%": " + a_doc.current_version.out + "}"
		end

invariant
	database_attached: database /= Void

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
