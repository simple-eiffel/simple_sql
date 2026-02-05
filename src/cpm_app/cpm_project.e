note
	description: "A CPM project containing activities and their dependencies"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	CPM_PROJECT

inherit
	ANY
		redefine
			out
		end

create
	make,
	make_new

feature {NONE} -- Initialization

	make (a_id: INTEGER_64; a_name: READABLE_STRING_8; a_description: detachable READABLE_STRING_8;
			a_start_date: detachable READABLE_STRING_8; a_calculated_duration: INTEGER;
			a_created_at, a_updated_at: READABLE_STRING_8)
			-- Initialize from database row.
		require
			name_not_empty: not a_name.is_empty
			created_at_not_empty: not a_created_at.is_empty
			updated_at_not_empty: not a_updated_at.is_empty
		do
			id := a_id
			name := a_name.to_string_8
			if attached a_description as al_desc then
				description := al_desc.to_string_8
			end
			if attached a_start_date as al_sd then
				start_date := al_sd.to_string_8
			end
			calculated_duration := a_calculated_duration
			created_at := a_created_at.to_string_8
			updated_at := a_updated_at.to_string_8
		ensure
			id_set: id = a_id
			name_set: name.same_string (a_name)
			calculated_duration_set: calculated_duration = a_calculated_duration
		end

	make_new (a_name: READABLE_STRING_8)
			-- Create a new project (not yet saved to database).
		require
			name_not_empty: not a_name.is_empty
		do
			id := 0
			name := a_name.to_string_8
			calculated_duration := 0
			created_at := ""
			updated_at := ""
		ensure
			id_zero: id = 0
			name_set: name.same_string (a_name)
			zero_duration: calculated_duration = 0
		end

feature -- Access

	id: INTEGER_64
			-- Unique identifier (0 if not yet saved).

	name: STRING_8
			-- Project name.

	description: detachable STRING_8
			-- Optional project description.

	start_date: detachable STRING_8
			-- Project start date (ISO 8601: YYYY-MM-DD).

	calculated_duration: INTEGER
			-- Total project duration in days (calculated from CPM).

	created_at: STRING_8
			-- Timestamp when created.

	updated_at: STRING_8
			-- Timestamp when last updated.

feature -- Status

	is_new: BOOLEAN
			-- Has this project not yet been saved to database?
		do
			Result := id = 0
		end

feature -- Modification

	set_name (a_name: READABLE_STRING_8)
			-- Update the name.
		require
			name_not_empty: not a_name.is_empty
		do
			name := a_name.to_string_8
		ensure
			name_set: name.same_string (a_name)
		end

	set_description (a_description: detachable READABLE_STRING_8)
			-- Update the description.
		do
			if attached a_description as al_desc then
				description := al_desc.to_string_8
			else
				description := Void
			end
		end

	set_start_date (a_start_date: detachable READABLE_STRING_8)
			-- Update the start date.
		do
			if attached a_start_date as al_sd then
				start_date := al_sd.to_string_8
			else
				start_date := Void
			end
		end

	set_calculated_duration (a_duration: INTEGER)
			-- Set the calculated project duration.
		require
			duration_non_negative: a_duration >= 0
		do
			calculated_duration := a_duration
		ensure
			duration_set: calculated_duration = a_duration
		end

	set_id (a_id: INTEGER_64)
			-- Set the ID (called after insert).
		require
			was_new: id = 0
			valid_id: a_id > 0
		do
			id := a_id
		ensure
			id_set: id = a_id
		end

	set_timestamps (a_created: READABLE_STRING_8; a_updated: READABLE_STRING_8)
			-- Set timestamps (called after insert/update).
		require
			created_not_empty: not a_created.is_empty
			updated_not_empty: not a_updated.is_empty
		do
			created_at := a_created.to_string_8
			updated_at := a_updated.to_string_8
		ensure
			created_set: created_at.same_string (a_created)
			updated_set: updated_at.same_string (a_updated)
		end

feature -- Output

	out: STRING_8
			-- String representation.
		do
			create Result.make (100)
			Result.append ("Project: ")
			Result.append (name)
			Result.append (" (")
			Result.append_integer (calculated_duration)
			Result.append (" days)")
			if attached start_date as al_sd then
				Result.append (" [Start: ")
				Result.append (sd)
				Result.append ("]")
			end
		end

invariant
	name_not_empty: not name.is_empty
	id_non_negative: id >= 0
	duration_non_negative: calculated_duration >= 0

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
