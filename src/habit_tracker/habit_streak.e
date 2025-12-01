note
	description: "Streak history record - tracks streak starts, ends, and lengths"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	HABIT_STREAK

create
	make,
	make_new

feature {NONE} -- Initialization

	make (a_id: INTEGER_64; a_habit_id: INTEGER_64; a_user_id: INTEGER_64;
			a_start_date: READABLE_STRING_8; a_end_date: detachable READABLE_STRING_8;
			a_length: INTEGER; a_is_active: BOOLEAN)
			-- Initialize from database row.
		require
			valid_habit: a_habit_id > 0
			valid_user: a_user_id > 0
			valid_length: a_length >= 0
			start_date_not_empty: not a_start_date.is_empty
		do
			id := a_id
			habit_id := a_habit_id
			user_id := a_user_id
			start_date := a_start_date.to_string_8
			if attached a_end_date as ed then
				end_date := ed.to_string_8
			end
			length := a_length
			is_active := a_is_active
		ensure
			id_set: id = a_id
			habit_id_set: habit_id = a_habit_id
			user_id_set: user_id = a_user_id
			start_date_set: start_date.same_string (a_start_date)
			length_set: length = a_length
			is_active_set: is_active = a_is_active
		end

	make_new (a_habit_id: INTEGER_64; a_user_id: INTEGER_64; a_start_date: READABLE_STRING_8)
			-- Create a new active streak.
		require
			valid_habit: a_habit_id > 0
			valid_user: a_user_id > 0
			start_date_not_empty: not a_start_date.is_empty
		do
			id := 0
			habit_id := a_habit_id
			user_id := a_user_id
			start_date := a_start_date.to_string_8
			length := 1
			is_active := True
		ensure
			id_zero: id = 0
			habit_id_set: habit_id = a_habit_id
			user_id_set: user_id = a_user_id
			starts_with_one: length = 1
			starts_active: is_active
		end

feature -- Access

	id: INTEGER_64
			-- Unique identifier (0 if not yet saved).

	habit_id: INTEGER_64
			-- Habit this streak is for.

	user_id: INTEGER_64
			-- User who achieved this streak.

	start_date: STRING_8
			-- Date streak started (YYYY-MM-DD).

	end_date: detachable STRING_8
			-- Date streak ended (Void if still active).

	length: INTEGER
			-- Number of consecutive days/periods.

	is_active: BOOLEAN
			-- Is this streak still ongoing?

feature -- Status

	is_new: BOOLEAN
			-- Has this streak not yet been saved to database?
		do
			Result := id = 0
		end

	is_week_streak: BOOLEAN
			-- Is this at least a week-long streak?
		do
			Result := length >= 7
		end

	is_month_streak: BOOLEAN
			-- Is this at least a month-long streak?
		do
			Result := length >= 30
		end

	is_hundred_day_streak: BOOLEAN
			-- Is this at least 100 days?
		do
			Result := length >= 100
		end

	is_legendary_streak: BOOLEAN
			-- Is this a legendary 365+ day streak?
		do
			Result := length >= 365
		end

	streak_tier: STRING_8
			-- Human-readable streak tier.
		do
			if length >= 365 then
				Result := "Legendary"
			elseif length >= 100 then
				Result := "Epic"
			elseif length >= 30 then
				Result := "Monthly"
			elseif length >= 7 then
				Result := "Weekly"
			else
				Result := "Starting"
			end
		end

	streak_emoji: STRING_8
			-- Emoji representing streak tier (for display).
		do
			if length >= 365 then
				Result := "crown"    -- Legendary
			elseif length >= 100 then
				Result := "fire"     -- Epic
			elseif length >= 30 then
				Result := "star"     -- Monthly
			elseif length >= 7 then
				Result := "flame"    -- Weekly
			else
				Result := "spark"    -- Starting
			end
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

	increment_length
			-- Add one day to streak.
		do
			length := length + 1
		ensure
			length_increased: length = old length + 1
		end

	end_streak (a_end_date: READABLE_STRING_8)
			-- Mark streak as ended.
		require
			is_active: is_active
			end_date_not_empty: not a_end_date.is_empty
		do
			end_date := a_end_date.to_string_8
			is_active := False
		ensure
			no_longer_active: not is_active
			end_date_set: attached end_date as ed and then ed.same_string (a_end_date)
		end

	set_length (a_length: INTEGER)
			-- Set length directly (for sync/restore).
		require
			non_negative: a_length >= 0
		do
			length := a_length
		ensure
			length_set: length = a_length
		end

invariant
	valid_habit_id: habit_id > 0
	valid_user_id: user_id > 0
	start_date_not_empty: not start_date.is_empty
	length_non_negative: length >= 0
	id_non_negative: id >= 0
	active_has_no_end: is_active implies end_date = Void
	ended_has_end_date: not is_active implies attached end_date

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
