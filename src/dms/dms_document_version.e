note
	description: "DMS Document Version - immutable snapshot of document at a point in time"
	date: "$Date$"
	revision: "$Revision$"

class
	DMS_DOCUMENT_VERSION

create
	make,
	make_new

feature {NONE} -- Initialization

	make (a_id: INTEGER_64; a_document_id: INTEGER_64; a_version_number: INTEGER;
			a_title, a_content: READABLE_STRING_8;
			a_file_size: INTEGER_64;
			a_checksum: detachable READABLE_STRING_8;
			a_created_by: INTEGER_64;
			a_change_summary: detachable READABLE_STRING_8;
			a_created_at: READABLE_STRING_8)
			-- Initialize from database row.
		do
			id := a_id
			document_id := a_document_id
			version_number := a_version_number
			title := a_title.to_string_8
			content := a_content.to_string_8
			file_size := a_file_size
			checksum := if attached a_checksum as c then c.to_string_8 else Void end
			created_by := a_created_by
			change_summary := if attached a_change_summary as s then s.to_string_8 else Void end
			created_at := a_created_at.to_string_8
		end

	make_new (a_document_id: INTEGER_64; a_version_number: INTEGER;
			a_title, a_content: READABLE_STRING_8;
			a_created_by: INTEGER_64;
			a_change_summary: detachable READABLE_STRING_8)
			-- Create a new version snapshot.
		require
			valid_document: a_document_id > 0
			version_positive: a_version_number > 0
			valid_creator: a_created_by > 0
		do
			id := 0
			document_id := a_document_id
			version_number := a_version_number
			title := a_title.to_string_8
			content := a_content.to_string_8
			file_size := a_content.count.to_integer_64
			created_by := a_created_by
			change_summary := if attached a_change_summary as s then s.to_string_8 else Void end
			created_at := ""
		ensure
			is_new: id = 0
		end

feature -- Access

	id: INTEGER_64
			-- Unique identifier.

	document_id: INTEGER_64
			-- Parent document ID.

	version_number: INTEGER
			-- Version number (1, 2, 3, ...).

	title: STRING_8
			-- Title at this version.

	content: STRING_8
			-- Content at this version.

	file_size: INTEGER_64
			-- Size at this version.

	checksum: detachable STRING_8
			-- Checksum at this version.

	created_by: INTEGER_64
			-- User who created this version.

	change_summary: detachable STRING_8
			-- Optional description of changes.

	created_at: STRING_8
			-- When this version was created.

feature -- Status

	is_new: BOOLEAN
		do
			Result := id = 0
		end

	is_initial_version: BOOLEAN
			-- Is this the first version?
		do
			Result := version_number = 1
		end

feature -- Comparison

	is_content_changed_from (a_previous: DMS_DOCUMENT_VERSION): BOOLEAN
			-- Has content changed from previous version?
		do
			Result := not content.same_string (a_previous.content)
		end

	is_title_changed_from (a_previous: DMS_DOCUMENT_VERSION): BOOLEAN
			-- Has title changed from previous version?
		do
			Result := not title.same_string (a_previous.title)
		end

	content_diff_size (a_previous: DMS_DOCUMENT_VERSION): INTEGER_64
			-- Size difference from previous version.
		do
			Result := file_size - a_previous.file_size
		end

feature -- Modification

	set_id (a_id: INTEGER_64)
		require
			was_new: id = 0
		do
			id := a_id
		end

	set_created_at (a_timestamp: READABLE_STRING_8)
		do
			created_at := a_timestamp.to_string_8
		end

	set_checksum (a_checksum: READABLE_STRING_8)
		do
			checksum := a_checksum.to_string_8
		end

invariant
	version_positive: version_number >= 1
	document_valid: document_id >= 0
	creator_valid: created_by >= 0

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
