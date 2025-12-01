note
	description: "DMS Document Tag - many-to-many junction table between documents and tags"
	date: "$Date$"
	revision: "$Revision$"

class
	DMS_DOCUMENT_TAG

create
	make,
	make_new

feature {NONE} -- Initialization

	make (a_id: INTEGER_64; a_document_id, a_tag_id: INTEGER_64;
			a_tagged_by: INTEGER_64;
			a_created_at: READABLE_STRING_8)
			-- Initialize from database row.
		do
			id := a_id
			document_id := a_document_id
			tag_id := a_tag_id
			tagged_by := a_tagged_by
			created_at := a_created_at.to_string_8
		end

	make_new (a_document_id, a_tag_id, a_tagged_by: INTEGER_64)
			-- Create a new document-tag association.
		require
			valid_document: a_document_id > 0
			valid_tag: a_tag_id > 0
			valid_user: a_tagged_by > 0
		do
			id := 0
			document_id := a_document_id
			tag_id := a_tag_id
			tagged_by := a_tagged_by
			created_at := ""
		ensure
			is_new: id = 0
		end

feature -- Access

	id: INTEGER_64
			-- Unique identifier.

	document_id: INTEGER_64
			-- Document ID.

	tag_id: INTEGER_64
			-- Tag ID.

	tagged_by: INTEGER_64
			-- User who added the tag.

	created_at: STRING_8
			-- When the tag was added.

feature -- Status

	is_new: BOOLEAN
		do
			Result := id = 0
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

invariant
	document_valid: document_id >= 0
	tag_valid: tag_id >= 0

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
