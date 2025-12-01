note
	description: "DMS Tag - tag definition for document categorization"
	date: "$Date$"
	revision: "$Revision$"

class
	DMS_TAG

create
	make,
	make_new

feature {NONE} -- Initialization

	make (a_id: INTEGER_64; a_owner_id: INTEGER_64;
			a_name: READABLE_STRING_8;
			a_color: detachable READABLE_STRING_8;
			a_created_at: READABLE_STRING_8)
			-- Initialize from database row.
		require
			name_not_empty: not a_name.is_empty
		do
			id := a_id
			owner_id := a_owner_id
			name := a_name.to_string_8
			color := if attached a_color as c then c.to_string_8 else "#808080" end
			created_at := a_created_at.to_string_8
			cached_document_count := 0
		end

	make_new (a_owner_id: INTEGER_64; a_name: READABLE_STRING_8)
			-- Create a new tag.
		require
			name_not_empty: not a_name.is_empty
			valid_owner: a_owner_id > 0
		do
			id := 0
			owner_id := a_owner_id
			name := a_name.to_string_8
			color := "#808080"
			created_at := ""
			cached_document_count := 0
		ensure
			is_new: id = 0
		end

feature -- Access

	id: INTEGER_64
			-- Unique identifier.

	owner_id: INTEGER_64
			-- Owner user ID.

	name: STRING_8
			-- Tag name.

	color: STRING_8
			-- Hex color for display.

	created_at: STRING_8
			-- Creation timestamp.

feature -- Cached Relations

	cached_document_count: INTEGER
			-- Number of documents with this tag (requires join or subquery).

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

	set_name (a_name: READABLE_STRING_8)
		require
			not_empty: not a_name.is_empty
		do
			name := a_name.to_string_8
		end

	set_color (a_color: READABLE_STRING_8)
		do
			color := a_color.to_string_8
		end

	set_created_at (a_timestamp: READABLE_STRING_8)
		do
			created_at := a_timestamp.to_string_8
		end

	set_cached_document_count (a_count: INTEGER)
		do
			cached_document_count := a_count
		end

invariant
	name_not_empty: not name.is_empty
	color_not_empty: not color.is_empty

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
