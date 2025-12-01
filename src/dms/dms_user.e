note
	description: "DMS User - account with preferences stored as JSON"
	date: "$Date$"
	revision: "$Revision$"

class
	DMS_USER

create
	make,
	make_new

feature {NONE} -- Initialization

	make (a_id: INTEGER_64; a_username, a_email, a_display_name: READABLE_STRING_8;
			a_preferences_json: detachable READABLE_STRING_8;
			a_created_at, a_updated_at: READABLE_STRING_8;
			a_deleted_at: detachable READABLE_STRING_8)
			-- Initialize from database row.
		require
			username_not_empty: not a_username.is_empty
			email_not_empty: not a_email.is_empty
		do
			id := a_id
			username := a_username.to_string_8
			email := a_email.to_string_8
			display_name := a_display_name.to_string_8
			if attached a_preferences_json as prefs then
				preferences_json := prefs.to_string_8
			else
				preferences_json := "{}"
			end
			created_at := a_created_at.to_string_8
			updated_at := a_updated_at.to_string_8
			deleted_at := if attached a_deleted_at as d then d.to_string_8 else Void end
		ensure
			id_set: id = a_id
			username_set: username.same_string (a_username)
		end

	make_new (a_username, a_email, a_display_name: READABLE_STRING_8)
			-- Create a new user (not yet saved).
		require
			username_not_empty: not a_username.is_empty
			email_not_empty: not a_email.is_empty
		do
			id := 0
			username := a_username.to_string_8
			email := a_email.to_string_8
			display_name := a_display_name.to_string_8
			preferences_json := "{}"
			created_at := ""
			updated_at := ""
		ensure
			is_new: id = 0
			username_set: username.same_string (a_username)
		end

feature -- Access

	id: INTEGER_64
			-- Unique identifier (0 if not yet saved).

	username: STRING_8
			-- Unique username.

	email: STRING_8
			-- Email address.

	display_name: STRING_8
			-- Display name.

	preferences_json: STRING_8
			-- User preferences as JSON.
			-- Example: {"theme": "dark", "notifications": true, "page_size": 25}

	created_at: STRING_8
			-- Creation timestamp.

	updated_at: STRING_8
			-- Last update timestamp.

	deleted_at: detachable STRING_8
			-- Soft delete timestamp (Void if active).

feature -- Status

	is_new: BOOLEAN
			-- Has this user not yet been saved?
		do
			Result := id = 0
		end

	is_deleted: BOOLEAN
			-- Is this user soft-deleted?
		do
			Result := deleted_at /= Void
		end

	is_active: BOOLEAN
			-- Is this user active (not deleted)?
		do
			Result := deleted_at = Void
		end

feature -- Modification

	set_id (a_id: INTEGER_64)
			-- Set the ID after insert.
		require
			was_new: id = 0
			valid_id: a_id > 0
		do
			id := a_id
		ensure
			id_set: id = a_id
		end

	set_display_name (a_name: READABLE_STRING_8)
			-- Update display name.
		do
			display_name := a_name.to_string_8
		ensure
			display_name_set: display_name.same_string (a_name)
		end

	set_email (a_email: READABLE_STRING_8)
			-- Update email.
		require
			not_empty: not a_email.is_empty
		do
			email := a_email.to_string_8
		ensure
			email_set: email.same_string (a_email)
		end

	set_preferences_json (a_json: READABLE_STRING_8)
			-- Update preferences JSON.
		do
			preferences_json := a_json.to_string_8
		ensure
			preferences_set: preferences_json.same_string (a_json)
		end

	set_created_at (a_timestamp: READABLE_STRING_8)
			-- Set creation timestamp.
		do
			created_at := a_timestamp.to_string_8
		end

	set_updated_at (a_timestamp: READABLE_STRING_8)
			-- Set update timestamp.
		do
			updated_at := a_timestamp.to_string_8
		end

	set_deleted_at (a_timestamp: detachable READABLE_STRING_8)
			-- Set soft delete timestamp.
		do
			if attached a_timestamp as t then
				deleted_at := t.to_string_8
			else
				deleted_at := Void
			end
		end

	soft_delete (a_timestamp: READABLE_STRING_8)
			-- Mark as soft deleted.
		require
			not_deleted: not is_deleted
		do
			deleted_at := a_timestamp.to_string_8
		ensure
			is_deleted: is_deleted
		end

	restore
			-- Restore from soft delete.
		require
			was_deleted: is_deleted
		do
			deleted_at := Void
		ensure
			not_deleted: not is_deleted
		end

invariant
	username_not_empty: not username.is_empty
	email_not_empty: not email.is_empty
	preferences_valid: preferences_json /= Void

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
