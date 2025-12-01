note
	description: "DMS Document - main document entity with versioning support"
	date: "$Date$"
	revision: "$Revision$"

class
	DMS_DOCUMENT

create
	make,
	make_new

feature {NONE} -- Initialization

	make (a_id: INTEGER_64; a_owner_id, a_folder_id: INTEGER_64;
			a_title, a_content: READABLE_STRING_8;
			a_mime_type: READABLE_STRING_8;
			a_file_size: INTEGER_64;
			a_checksum: detachable READABLE_STRING_8;
			a_current_version: INTEGER;
			a_metadata_json: detachable READABLE_STRING_8;
			a_created_at, a_updated_at: READABLE_STRING_8;
			a_deleted_at, a_expires_at, a_last_accessed_at: detachable READABLE_STRING_8)
			-- Initialize from database row.
		require
			title_not_empty: not a_title.is_empty
		do
			id := a_id
			owner_id := a_owner_id
			folder_id := a_folder_id
			title := a_title.to_string_8
			content := a_content.to_string_8
			mime_type := a_mime_type.to_string_8
			file_size := a_file_size
			checksum := if attached a_checksum as c then c.to_string_8 else Void end
			current_version := a_current_version
			metadata_json := if attached a_metadata_json as m then m.to_string_8 else "{}" end
			created_at := a_created_at.to_string_8
			updated_at := a_updated_at.to_string_8
			deleted_at := if attached a_deleted_at as d then d.to_string_8 else Void end
			expires_at := if attached a_expires_at as e then e.to_string_8 else Void end
			last_accessed_at := if attached a_last_accessed_at as l then l.to_string_8 else Void end
		end

	make_new (a_owner_id, a_folder_id: INTEGER_64; a_title, a_content, a_mime_type: READABLE_STRING_8)
			-- Create a new document.
		require
			title_not_empty: not a_title.is_empty
			valid_owner: a_owner_id > 0
			valid_folder: a_folder_id > 0
		do
			id := 0
			owner_id := a_owner_id
			folder_id := a_folder_id
			title := a_title.to_string_8
			content := a_content.to_string_8
			mime_type := a_mime_type.to_string_8
			file_size := a_content.count.to_integer_64
			current_version := 1
			metadata_json := "{}"
			created_at := ""
			updated_at := ""
		ensure
			is_new: id = 0
			version_1: current_version = 1
		end

feature -- Access

	id: INTEGER_64
			-- Unique identifier.

	owner_id: INTEGER_64
			-- Owner user ID.

	folder_id: INTEGER_64
			-- Parent folder ID.

	title: STRING_8
			-- Document title.

	content: STRING_8
			-- Document content (text or reference to BLOB).

	mime_type: STRING_8
			-- MIME type (e.g., "text/plain", "application/pdf").

	file_size: INTEGER_64
			-- Size in bytes.

	checksum: detachable STRING_8
			-- SHA-256 checksum for integrity.

	current_version: INTEGER
			-- Current version number.

	metadata_json: STRING_8
			-- Additional metadata as JSON.
			-- Example: {"author": "John", "keywords": ["report", "q4"], "custom": {...}}

	created_at: STRING_8
			-- Creation timestamp.

	updated_at: STRING_8
			-- Last update timestamp.

	deleted_at: detachable STRING_8
			-- Soft delete timestamp.

	expires_at: detachable STRING_8
			-- Automatic expiration timestamp.

	last_accessed_at: detachable STRING_8
			-- Last access timestamp (for cleanup policies).

feature -- Status

	is_new: BOOLEAN
		do
			Result := id = 0
		end

	is_deleted: BOOLEAN
		do
			Result := deleted_at /= Void
		end

	is_active: BOOLEAN
		do
			Result := deleted_at = Void
		end

	is_expired: BOOLEAN
			-- Has the document expired?
			-- Note: Requires date comparison - will expose date/time pain point
		do
			-- Simplified: just check if expires_at is set
			-- Real implementation would compare to current time
			Result := False -- Placeholder
		end

	is_text_document: BOOLEAN
			-- Is this a text-based document?
		do
			Result := mime_type.starts_with ("text/")
		end

	is_binary_document: BOOLEAN
			-- Is this a binary document?
		do
			Result := not is_text_document
		end

feature -- Measurement

	word_count: INTEGER
			-- Approximate word count for text documents.
		local
			l_words: LIST [STRING_8]
		do
			if is_text_document then
				l_words := content.split (' ')
				Result := l_words.count
			end
		end

feature -- Modification

	set_id (a_id: INTEGER_64)
		require
			was_new: id = 0
		do
			id := a_id
		end

	set_title (a_title: READABLE_STRING_8)
		require
			not_empty: not a_title.is_empty
		do
			title := a_title.to_string_8
		end

	set_content (a_content: READABLE_STRING_8)
		do
			content := a_content.to_string_8
			file_size := a_content.count.to_integer_64
		end

	set_folder_id (a_folder_id: INTEGER_64)
		require
			valid: a_folder_id > 0
		do
			folder_id := a_folder_id
		end

	set_mime_type (a_mime_type: READABLE_STRING_8)
		do
			mime_type := a_mime_type.to_string_8
		end

	set_checksum (a_checksum: READABLE_STRING_8)
		do
			checksum := a_checksum.to_string_8
		end

	set_metadata_json (a_json: READABLE_STRING_8)
		do
			metadata_json := a_json.to_string_8
		end

	set_expires_at (a_timestamp: detachable READABLE_STRING_8)
		do
			expires_at := if attached a_timestamp as t then t.to_string_8 else Void end
		end

	set_last_accessed_at (a_timestamp: READABLE_STRING_8)
		do
			last_accessed_at := a_timestamp.to_string_8
		end

	increment_version
			-- Increment version number.
		do
			current_version := current_version + 1
		ensure
			version_incremented: current_version = old current_version + 1
		end

	set_current_version (a_version: INTEGER)
		require
			positive: a_version > 0
		do
			current_version := a_version
		end

	set_created_at (a_timestamp: READABLE_STRING_8)
		do
			created_at := a_timestamp.to_string_8
		end

	set_updated_at (a_timestamp: READABLE_STRING_8)
		do
			updated_at := a_timestamp.to_string_8
		end

	set_deleted_at (a_timestamp: detachable READABLE_STRING_8)
		do
			deleted_at := if attached a_timestamp as t then t.to_string_8 else Void end
		end

	soft_delete (a_timestamp: READABLE_STRING_8)
		require
			not_deleted: not is_deleted
		do
			deleted_at := a_timestamp.to_string_8
		ensure
			is_deleted: is_deleted
		end

	restore
		require
			was_deleted: is_deleted
		do
			deleted_at := Void
		ensure
			not_deleted: not is_deleted
		end

invariant
	title_not_empty: not title.is_empty
	version_positive: current_version >= 1
	metadata_attached: metadata_json /= Void

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
