note
	description: "DMS Share - sharing permissions with JSON for complex permission structures"
	date: "$Date$"
	revision: "$Revision$"

class
	DMS_SHARE

create
	make,
	make_new

feature {NONE} -- Initialization

	make (a_id: INTEGER_64; a_document_id: detachable INTEGER_64_REF;
			a_folder_id: detachable INTEGER_64_REF;
			a_owner_id, a_shared_with_user_id: INTEGER_64;
			a_permissions_json: READABLE_STRING_8;
			a_share_link: detachable READABLE_STRING_8;
			a_expires_at: detachable READABLE_STRING_8;
			a_created_at: READABLE_STRING_8;
			a_revoked_at: detachable READABLE_STRING_8)
			-- Initialize from database row.
		require
			has_target: a_document_id /= Void or a_folder_id /= Void
		do
			id := a_id
			document_id := a_document_id
			folder_id := a_folder_id
			owner_id := a_owner_id
			shared_with_user_id := a_shared_with_user_id
			permissions_json := a_permissions_json.to_string_8
			share_link := if attached a_share_link as l then l.to_string_8 else Void end
			expires_at := if attached a_expires_at as e then e.to_string_8 else Void end
			created_at := a_created_at.to_string_8
			revoked_at := if attached a_revoked_at as r then r.to_string_8 else Void end
		end

	make_new (a_owner_id, a_shared_with_user_id: INTEGER_64; a_permissions_json: READABLE_STRING_8)
			-- Create a new share.
		require
			valid_owner: a_owner_id > 0
		do
			id := 0
			owner_id := a_owner_id
			shared_with_user_id := a_shared_with_user_id
			permissions_json := a_permissions_json.to_string_8
			created_at := ""
		ensure
			is_new: id = 0
		end

feature -- Access

	id: INTEGER_64
			-- Unique identifier.

	document_id: detachable INTEGER_64_REF
			-- Shared document ID (mutually exclusive with folder_id).

	folder_id: detachable INTEGER_64_REF
			-- Shared folder ID (mutually exclusive with document_id).

	owner_id: INTEGER_64
			-- User who created the share.

	shared_with_user_id: INTEGER_64
			-- User the item is shared with (0 for public link).

	permissions_json: STRING_8
			-- JSON permissions object.
			-- Example: {"read": true, "write": false, "delete": false, "share": false, "download": true}

	share_link: detachable STRING_8
			-- Public share link token (for link-based sharing).

	expires_at: detachable STRING_8
			-- Share expiration timestamp.

	created_at: STRING_8
			-- When the share was created.

	revoked_at: detachable STRING_8
			-- When the share was revoked (soft delete for shares).

feature -- Status

	is_new: BOOLEAN
		do
			Result := id = 0
		end

	is_document_share: BOOLEAN
			-- Is this a document share?
		do
			Result := document_id /= Void
		end

	is_folder_share: BOOLEAN
			-- Is this a folder share?
		do
			Result := folder_id /= Void
		end

	is_user_share: BOOLEAN
			-- Is this shared with a specific user?
		do
			Result := shared_with_user_id > 0
		end

	is_link_share: BOOLEAN
			-- Is this a public link share?
		do
			Result := share_link /= Void
		end

	is_active: BOOLEAN
			-- Is the share currently active?
		do
			Result := revoked_at = Void
		end

	is_revoked: BOOLEAN
			-- Has the share been revoked?
		do
			Result := revoked_at /= Void
		end

	is_expired: BOOLEAN
			-- Has the share expired?
			-- Note: Requires date comparison - exposes date/time pain point
		do
			-- Simplified check
			Result := False -- Would need actual date comparison
		end

feature -- Permission Queries (JSON parsing pain point)
	-- These expose the need for JSON column handling

	can_read: BOOLEAN
			-- Does this share grant read permission?
			-- Note: Requires JSON parsing - exposes JSON pain point
		do
			-- Simplified: check if "read": true exists in JSON
			Result := permissions_json.has_substring ("%"read%": true") or
					  permissions_json.has_substring ("%"read%":true")
		end

	can_write: BOOLEAN
			-- Does this share grant write permission?
		do
			Result := permissions_json.has_substring ("%"write%": true") or
					  permissions_json.has_substring ("%"write%":true")
		end

	can_delete: BOOLEAN
			-- Does this share grant delete permission?
		do
			Result := permissions_json.has_substring ("%"delete%": true") or
					  permissions_json.has_substring ("%"delete%":true")
		end

	can_share: BOOLEAN
			-- Does this share grant re-sharing permission?
		do
			Result := permissions_json.has_substring ("%"share%": true") or
					  permissions_json.has_substring ("%"share%":true")
		end

	can_download: BOOLEAN
			-- Does this share grant download permission?
		do
			Result := permissions_json.has_substring ("%"download%": true") or
					  permissions_json.has_substring ("%"download%":true")
		end

feature -- Default Permissions

	default_read_only_permissions: STRING_8
			-- Read-only permission set.
		once
			Result := "{%"read%": true, %"write%": false, %"delete%": false, %"share%": false, %"download%": true}"
		end

	default_edit_permissions: STRING_8
			-- Read/write permission set.
		once
			Result := "{%"read%": true, %"write%": true, %"delete%": false, %"share%": false, %"download%": true}"
		end

	default_full_permissions: STRING_8
			-- Full permission set.
		once
			Result := "{%"read%": true, %"write%": true, %"delete%": true, %"share%": true, %"download%": true}"
		end

feature -- Modification

	set_id (a_id: INTEGER_64)
		require
			was_new: id = 0
		do
			id := a_id
		end

	set_document_id (a_doc_id: INTEGER_64)
		require
			valid: a_doc_id > 0
			no_folder: folder_id = Void
		do
			create document_id
			if attached document_id as d then
				d.set_item (a_doc_id)
			end
		ensure
			is_document_share: is_document_share
		end

	set_folder_id (a_folder_id: INTEGER_64)
		require
			valid: a_folder_id > 0
			no_document: document_id = Void
		do
			create folder_id
			if attached folder_id as f then
				f.set_item (a_folder_id)
			end
		ensure
			is_folder_share: is_folder_share
		end

	set_permissions_json (a_json: READABLE_STRING_8)
		do
			permissions_json := a_json.to_string_8
		end

	set_share_link (a_link: READABLE_STRING_8)
		do
			share_link := a_link.to_string_8
		end

	set_expires_at (a_timestamp: detachable READABLE_STRING_8)
		do
			expires_at := if attached a_timestamp as t then t.to_string_8 else Void end
		end

	set_created_at (a_timestamp: READABLE_STRING_8)
		do
			created_at := a_timestamp.to_string_8
		end

	revoke (a_timestamp: READABLE_STRING_8)
			-- Revoke this share.
		require
			not_revoked: not is_revoked
		do
			revoked_at := a_timestamp.to_string_8
		ensure
			is_revoked: is_revoked
		end

	unrevoke
			-- Restore a revoked share.
		require
			was_revoked: is_revoked
		do
			revoked_at := Void
		ensure
			not_revoked: not is_revoked
		end

invariant
	permissions_not_empty: not permissions_json.is_empty

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
