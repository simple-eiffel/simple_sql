note
	description: "DMS Audit Log - tracks all actions on documents (exposes audit trail pattern)"
	date: "$Date$"
	revision: "$Revision$"

class
	DMS_AUDIT_LOG

create
	make,
	make_new

feature {NONE} -- Initialization

	make (a_id: INTEGER_64; a_user_id: INTEGER_64;
			a_action: READABLE_STRING_8;
			a_entity_type: READABLE_STRING_8;
			a_entity_id: INTEGER_64;
			a_old_value_json, a_new_value_json: detachable READABLE_STRING_8;
			a_ip_address: detachable READABLE_STRING_8;
			a_user_agent: detachable READABLE_STRING_8;
			a_created_at: READABLE_STRING_8)
			-- Initialize from database row.
		do
			id := a_id
			user_id := a_user_id
			action := a_action.to_string_8
			entity_type := a_entity_type.to_string_8
			entity_id := a_entity_id
			old_value_json := if attached a_old_value_json as o then o.to_string_8 else Void end
			new_value_json := if attached a_new_value_json as n then n.to_string_8 else Void end
			ip_address := if attached a_ip_address as ip then ip.to_string_8 else Void end
			user_agent := if attached a_user_agent as ua then ua.to_string_8 else Void end
			created_at := a_created_at.to_string_8
		end

	make_new (a_user_id: INTEGER_64; a_action, a_entity_type: READABLE_STRING_8; a_entity_id: INTEGER_64)
			-- Create a new audit log entry.
		require
			action_not_empty: not a_action.is_empty
			entity_type_not_empty: not a_entity_type.is_empty
		do
			id := 0
			user_id := a_user_id
			action := a_action.to_string_8
			entity_type := a_entity_type.to_string_8
			entity_id := a_entity_id
			created_at := ""
		ensure
			is_new: id = 0
		end

feature -- Access

	id: INTEGER_64
			-- Unique identifier.

	user_id: INTEGER_64
			-- User who performed the action.

	action: STRING_8
			-- Action performed: "create", "read", "update", "delete", "restore",
			-- "move", "copy", "share", "unshare", "download", "upload", etc.

	entity_type: STRING_8
			-- Type of entity: "document", "folder", "comment", "user", "share"

	entity_id: INTEGER_64
			-- ID of the affected entity.

	old_value_json: detachable STRING_8
			-- Previous state as JSON (for updates/deletes).

	new_value_json: detachable STRING_8
			-- New state as JSON (for creates/updates).

	ip_address: detachable STRING_8
			-- Client IP address.

	user_agent: detachable STRING_8
			-- Client user agent.

	created_at: STRING_8
			-- When the action occurred.

feature -- Status

	is_new: BOOLEAN
		do
			Result := id = 0
		end

	is_create_action: BOOLEAN
		do
			Result := action.same_string ("create")
		end

	is_read_action: BOOLEAN
		do
			Result := action.same_string ("read")
		end

	is_update_action: BOOLEAN
		do
			Result := action.same_string ("update")
		end

	is_delete_action: BOOLEAN
		do
			Result := action.same_string ("delete") or action.same_string ("soft_delete")
		end

	is_restore_action: BOOLEAN
		do
			Result := action.same_string ("restore")
		end

	has_changes: BOOLEAN
			-- Does this log entry record actual changes?
		do
			Result := old_value_json /= Void or new_value_json /= Void
		end

feature -- Action Constants

	action_create: STRING_8 = "create"
	action_read: STRING_8 = "read"
	action_update: STRING_8 = "update"
	action_delete: STRING_8 = "delete"
	action_soft_delete: STRING_8 = "soft_delete"
	action_restore: STRING_8 = "restore"
	action_move: STRING_8 = "move"
	action_copy: STRING_8 = "copy"
	action_share: STRING_8 = "share"
	action_unshare: STRING_8 = "unshare"
	action_download: STRING_8 = "download"
	action_upload: STRING_8 = "upload"
	action_version: STRING_8 = "version"
	action_comment: STRING_8 = "comment"
	action_tag: STRING_8 = "tag"
	action_untag: STRING_8 = "untag"

feature -- Entity Type Constants

	entity_document: STRING_8 = "document"
	entity_folder: STRING_8 = "folder"
	entity_comment: STRING_8 = "comment"
	entity_user: STRING_8 = "user"
	entity_share: STRING_8 = "share"
	entity_tag: STRING_8 = "tag"

feature -- Modification

	set_id (a_id: INTEGER_64)
		require
			was_new: id = 0
		do
			id := a_id
		end

	set_old_value_json (a_json: READABLE_STRING_8)
		do
			old_value_json := a_json.to_string_8
		end

	set_new_value_json (a_json: READABLE_STRING_8)
		do
			new_value_json := a_json.to_string_8
		end

	set_ip_address (a_ip: READABLE_STRING_8)
		do
			ip_address := a_ip.to_string_8
		end

	set_user_agent (a_ua: READABLE_STRING_8)
		do
			user_agent := a_ua.to_string_8
		end

	set_created_at (a_timestamp: READABLE_STRING_8)
		do
			created_at := a_timestamp.to_string_8
		end

invariant
	action_not_empty: not action.is_empty
	entity_type_not_empty: not entity_type.is_empty

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
