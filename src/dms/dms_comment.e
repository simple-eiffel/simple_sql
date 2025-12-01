note
	description: "DMS Comment - threaded comments on documents (exposes N+1 problem)"
	date: "$Date$"
	revision: "$Revision$"

class
	DMS_COMMENT

create
	make,
	make_new

feature {NONE} -- Initialization

	make (a_id: INTEGER_64; a_document_id, a_user_id: INTEGER_64;
			a_parent_comment_id: detachable INTEGER_64_REF;
			a_content: READABLE_STRING_8;
			a_created_at, a_updated_at: READABLE_STRING_8;
			a_deleted_at: detachable READABLE_STRING_8)
			-- Initialize from database row.
		require
			content_not_empty: not a_content.is_empty
		do
			id := a_id
			document_id := a_document_id
			user_id := a_user_id
			parent_comment_id := a_parent_comment_id
			content := a_content.to_string_8
			created_at := a_created_at.to_string_8
			updated_at := a_updated_at.to_string_8
			deleted_at := if attached a_deleted_at as d then d.to_string_8 else Void end
			-- These will be set via eager loading or separate query (N+1 exposure)
			cached_user_display_name := Void
			cached_reply_count := 0
		end

	make_new (a_document_id, a_user_id: INTEGER_64; a_content: READABLE_STRING_8)
			-- Create a new top-level comment.
		require
			content_not_empty: not a_content.is_empty
			valid_document: a_document_id > 0
			valid_user: a_user_id > 0
		do
			id := 0
			document_id := a_document_id
			user_id := a_user_id
			parent_comment_id := Void
			content := a_content.to_string_8
			created_at := ""
			updated_at := ""
		ensure
			is_new: id = 0
			is_top_level: is_top_level
		end

feature -- Access

	id: INTEGER_64
			-- Unique identifier.

	document_id: INTEGER_64
			-- Document this comment belongs to.

	user_id: INTEGER_64
			-- User who wrote the comment.

	parent_comment_id: detachable INTEGER_64_REF
			-- Parent comment ID for threaded replies (Void for top-level).

	content: STRING_8
			-- Comment text.

	created_at: STRING_8
			-- Creation timestamp.

	updated_at: STRING_8
			-- Last update timestamp.

	deleted_at: detachable STRING_8
			-- Soft delete timestamp.

feature -- Cached Relations (N+1 Problem Exposure)

	cached_user_display_name: detachable STRING_8
			-- Cached user display name (requires separate query without eager loading).
			-- This exposes the N+1 problem: fetching 100 comments = 100 user queries.

	cached_reply_count: INTEGER
			-- Cached count of replies (requires separate query).

feature -- Status

	is_new: BOOLEAN
		do
			Result := id = 0
		end

	is_top_level: BOOLEAN
			-- Is this a top-level comment (not a reply)?
		do
			Result := parent_comment_id = Void
		end

	is_reply: BOOLEAN
			-- Is this a reply to another comment?
		do
			Result := parent_comment_id /= Void
		end

	is_deleted: BOOLEAN
		do
			Result := deleted_at /= Void
		end

	is_active: BOOLEAN
		do
			Result := deleted_at = Void
		end

	is_edited: BOOLEAN
			-- Has comment been edited after creation?
		do
			Result := not created_at.same_string (updated_at)
		end

feature -- Modification

	set_id (a_id: INTEGER_64)
		require
			was_new: id = 0
		do
			id := a_id
		end

	set_content (a_content: READABLE_STRING_8)
		require
			not_empty: not a_content.is_empty
		do
			content := a_content.to_string_8
		end

	set_parent_comment_id (a_parent_id: INTEGER_64)
			-- Make this a reply to another comment.
		require
			valid_parent: a_parent_id > 0
		do
			create parent_comment_id
			if attached parent_comment_id as p then
				p.set_item (a_parent_id)
			end
		ensure
			is_reply: is_reply
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

	-- Cached relation setters (used by eager loading)

	set_cached_user_display_name (a_name: READABLE_STRING_8)
			-- Cache the user's display name.
		do
			cached_user_display_name := a_name.to_string_8
		end

	set_cached_reply_count (a_count: INTEGER)
			-- Cache the reply count.
		do
			cached_reply_count := a_count
		end

invariant
	content_not_empty: not content.is_empty

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
