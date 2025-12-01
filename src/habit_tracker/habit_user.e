note
	description: "A user in the habit tracking system with XP and level progression"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	HABIT_USER

create
	make,
	make_new

feature {NONE} -- Initialization

	make (a_id: INTEGER_64; a_username, a_email: READABLE_STRING_8;
			a_timezone: READABLE_STRING_8; a_total_xp: INTEGER;
			a_level: INTEGER; a_settings: detachable READABLE_STRING_8;
			a_created_at: READABLE_STRING_8)
			-- Initialize from database row.
		require
			username_not_empty: not a_username.is_empty
			email_not_empty: not a_email.is_empty
			timezone_not_empty: not a_timezone.is_empty
			xp_non_negative: a_total_xp >= 0
			level_positive: a_level >= 1
		do
			id := a_id
			username := a_username.to_string_8
			email := a_email.to_string_8
			timezone := a_timezone.to_string_8
			total_xp := a_total_xp
			level := a_level
			if attached a_settings as s then
				settings := s.to_string_8
			end
			created_at := a_created_at.to_string_8
		ensure
			id_set: id = a_id
			username_set: username.same_string (a_username)
			email_set: email.same_string (a_email)
		end

	make_new (a_username, a_email: READABLE_STRING_8; a_timezone: READABLE_STRING_8)
			-- Create a new user (not yet saved).
		require
			username_not_empty: not a_username.is_empty
			email_not_empty: not a_email.is_empty
			timezone_not_empty: not a_timezone.is_empty
		do
			id := 0
			username := a_username.to_string_8
			email := a_email.to_string_8
			timezone := a_timezone.to_string_8
			total_xp := 0
			level := 1
			created_at := ""
		ensure
			id_zero: id = 0
			username_set: username.same_string (a_username)
			starts_at_level_1: level = 1
			starts_with_zero_xp: total_xp = 0
		end

feature -- Access

	id: INTEGER_64
			-- Unique identifier (0 if not yet saved).

	username: STRING_8
			-- User's display name.

	email: STRING_8
			-- User's email address.

	timezone: STRING_8
			-- User's timezone (e.g., "America/New_York").

	total_xp: INTEGER
			-- Total experience points earned.

	level: INTEGER
			-- Current level (calculated from XP).

	settings: detachable STRING_8
			-- JSON settings (notification preferences, theme, etc.)

	created_at: STRING_8
			-- Timestamp when created.

feature -- XP and Leveling

	xp_for_next_level: INTEGER
			-- XP required to reach next level.
			-- Formula: 100 * level^1.5 (gets progressively harder)
		do
			Result := (100 * (level ^ 1.5)).truncated_to_integer
		ensure
			positive: Result > 0
		end

	xp_progress_percentage: REAL_64
			-- Progress toward next level (0.0 to 100.0).
		local
			l_current_level_xp: INTEGER
			l_prev_level_total: INTEGER
		do
			l_prev_level_total := xp_for_level (level)
			l_current_level_xp := total_xp - l_prev_level_total
			if xp_for_next_level > 0 then
				Result := (l_current_level_xp / xp_for_next_level) * 100.0
			end
			Result := Result.min (100.0).max (0.0)
		ensure
			in_range: Result >= 0.0 and Result <= 100.0
		end

	xp_for_level (a_level: INTEGER): INTEGER
			-- Total XP required to reach a given level.
		require
			level_positive: a_level >= 1
		local
			i: INTEGER
		do
			from i := 1 until i >= a_level loop
				Result := Result + (100 * (i ^ 1.5)).truncated_to_integer
				i := i + 1
			end
		ensure
			non_negative: Result >= 0
		end

	calculated_level: INTEGER
			-- Level based on current XP.
		local
			l_xp_remaining: INTEGER
			l_level_xp: INTEGER
		do
			Result := 1
			l_xp_remaining := total_xp
			from until l_xp_remaining < (100 * (Result ^ 1.5)).truncated_to_integer loop
				l_level_xp := (100 * (Result ^ 1.5)).truncated_to_integer
				l_xp_remaining := l_xp_remaining - l_level_xp
				Result := Result + 1
			end
		ensure
			at_least_one: Result >= 1
		end

feature -- Status

	is_new: BOOLEAN
			-- Has this user not yet been saved to database?
		do
			Result := id = 0
		end

feature -- Modification

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

	add_xp (a_xp: INTEGER)
			-- Add XP and potentially level up.
		require
			positive_xp: a_xp > 0
		do
			total_xp := total_xp + a_xp
			level := calculated_level
		ensure
			xp_increased: total_xp = old total_xp + a_xp
			level_updated: level = calculated_level
		end

	set_settings (a_settings: detachable READABLE_STRING_8)
			-- Update settings JSON.
		do
			if attached a_settings as s then
				settings := s.to_string_8
			else
				settings := Void
			end
		end

	set_created_at (a_timestamp: READABLE_STRING_8)
			-- Set creation timestamp.
		require
			not_empty: not a_timestamp.is_empty
		do
			created_at := a_timestamp.to_string_8
		end

invariant
	username_not_empty: not username.is_empty
	email_not_empty: not email.is_empty
	timezone_not_empty: not timezone.is_empty
	level_positive: level >= 1
	xp_non_negative: total_xp >= 0
	id_non_negative: id >= 0

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
