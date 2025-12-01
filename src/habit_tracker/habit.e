note
	description: "A habit to track with flexible scheduling and streak tracking"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	HABIT

create
	make,
	make_new

feature {NONE} -- Initialization

	make (a_id: INTEGER_64; a_user_id: INTEGER_64; a_category_id: detachable INTEGER_64_REF;
			a_name, a_description: READABLE_STRING_8;
			a_frequency_type: READABLE_STRING_8; a_frequency_value: INTEGER;
			a_frequency_days: detachable READABLE_STRING_8;
			a_target_count: INTEGER; a_reminder_time: detachable READABLE_STRING_8;
			a_is_archived: BOOLEAN; a_streak_current, a_streak_best: INTEGER;
			a_total_completions: INTEGER; a_xp_per_completion: INTEGER;
			a_created_at: READABLE_STRING_8)
			-- Initialize from database row.
		require
			name_not_empty: not a_name.is_empty
			valid_user: a_user_id > 0
			valid_frequency_type: is_valid_frequency_type (a_frequency_type)
			target_positive: a_target_count >= 1
		do
			id := a_id
			user_id := a_user_id
			if attached a_category_id then
				category_id := a_category_id.item
			end
			name := a_name.to_string_8
			description := a_description.to_string_8
			frequency_type := a_frequency_type.to_string_8
			frequency_value := a_frequency_value
			if attached a_frequency_days as fd then
				frequency_days := fd.to_string_8
			end
			target_count := a_target_count
			if attached a_reminder_time as rt then
				reminder_time := rt.to_string_8
			end
			is_archived := a_is_archived
			streak_current := a_streak_current
			streak_best := a_streak_best
			total_completions := a_total_completions
			xp_per_completion := a_xp_per_completion
			created_at := a_created_at.to_string_8
		ensure
			id_set: id = a_id
			user_id_set: user_id = a_user_id
			name_set: name.same_string (a_name)
		end

	make_new (a_user_id: INTEGER_64; a_name: READABLE_STRING_8; a_frequency_type: READABLE_STRING_8)
			-- Create a new daily habit with defaults.
		require
			valid_user: a_user_id > 0
			name_not_empty: not a_name.is_empty
			valid_frequency_type: is_valid_frequency_type (a_frequency_type)
		do
			id := 0
			user_id := a_user_id
			category_id := 0
			name := a_name.to_string_8
			description := ""
			frequency_type := a_frequency_type.to_string_8
			frequency_value := 1
			target_count := 1
			is_archived := False
			streak_current := 0
			streak_best := 0
			total_completions := 0
			xp_per_completion := 10 -- Base XP
			created_at := ""
		ensure
			id_zero: id = 0
			user_id_set: user_id = a_user_id
			name_set: name.same_string (a_name)
			frequency_type_set: frequency_type.same_string (a_frequency_type)
			not_archived: not is_archived
			zero_streaks: streak_current = 0 and streak_best = 0
		end

feature -- Access

	id: INTEGER_64
			-- Unique identifier (0 if not yet saved).

	user_id: INTEGER_64
			-- Owner of this habit.

	category_id: INTEGER_64
			-- Category this habit belongs to (0 if none).

	name: STRING_8
			-- Habit name (e.g., "Drink 8 glasses of water").

	description: STRING_8
			-- Optional detailed description.

	frequency_type: STRING_8
			-- "daily", "weekly", "weekdays", "weekends", "custom", "x_per_week"

	frequency_value: INTEGER
			-- For "x_per_week": how many times per week (e.g., 3)
			-- For "daily": 1

	frequency_days: detachable STRING_8
			-- JSON array of days for "custom" type: e.g., "[1,3,5]" for Mon/Wed/Fri
			-- Days: 0=Sunday, 1=Monday, ..., 6=Saturday

	target_count: INTEGER
			-- How many times per day/session (e.g., 8 for 8 glasses).

	reminder_time: detachable STRING_8
			-- Time for reminder notification (HH:MM format).

	is_archived: BOOLEAN
			-- Is this habit archived (hidden but preserved)?

	streak_current: INTEGER
			-- Current consecutive streak length.

	streak_best: INTEGER
			-- Best streak ever achieved.

	total_completions: INTEGER
			-- Lifetime total completion count.

	xp_per_completion: INTEGER
			-- XP earned per completion (base amount).

	created_at: STRING_8
			-- Timestamp when created.

feature -- Status

	is_new: BOOLEAN
			-- Has this habit not yet been saved to database?
		do
			Result := id = 0
		end

	is_daily: BOOLEAN
			-- Is this a daily habit?
		do
			Result := frequency_type.same_string ("daily")
		end

	is_weekly: BOOLEAN
			-- Is this a weekly habit (x times per week)?
		do
			Result := frequency_type.same_string ("weekly") or frequency_type.same_string ("x_per_week")
		end

	is_weekdays_only: BOOLEAN
			-- Is this weekdays only (Mon-Fri)?
		do
			Result := frequency_type.same_string ("weekdays")
		end

	is_weekends_only: BOOLEAN
			-- Is this weekends only (Sat-Sun)?
		do
			Result := frequency_type.same_string ("weekends")
		end

	is_custom_schedule: BOOLEAN
			-- Does this have a custom day schedule?
		do
			Result := frequency_type.same_string ("custom")
		end

	has_active_streak: BOOLEAN
			-- Is there an active streak going?
		do
			Result := streak_current > 0
		end

feature -- Streak Calculations

	streak_xp_bonus: INTEGER
			-- Bonus XP multiplier based on current streak.
			-- 7-day streak = 1.5x, 30-day = 2x, 100-day = 3x
		do
			if streak_current >= 100 then
				Result := xp_per_completion * 2 -- 3x total
			elseif streak_current >= 30 then
				Result := xp_per_completion     -- 2x total
			elseif streak_current >= 7 then
				Result := xp_per_completion // 2 -- 1.5x total
			else
				Result := 0
			end
		ensure
			non_negative: Result >= 0
		end

	total_xp_for_completion: INTEGER
			-- Total XP earned for a completion (base + streak bonus).
		do
			Result := xp_per_completion + streak_xp_bonus
		ensure
			at_least_base: Result >= xp_per_completion
		end

feature -- Validation

	is_valid_frequency_type (a_type: READABLE_STRING_8): BOOLEAN
			-- Is this a valid frequency type?
		do
			Result := a_type.same_string ("daily") or else
				a_type.same_string ("weekly") or else
				a_type.same_string ("weekdays") or else
				a_type.same_string ("weekends") or else
				a_type.same_string ("custom") or else
				a_type.same_string ("x_per_week")
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

	set_category_id (a_category_id: INTEGER_64)
			-- Assign to a category.
		require
			valid_category: a_category_id >= 0
		do
			category_id := a_category_id
		ensure
			category_id_set: category_id = a_category_id
		end

	set_name (a_name: READABLE_STRING_8)
			-- Update habit name.
		require
			not_empty: not a_name.is_empty
		do
			name := a_name.to_string_8
		ensure
			name_set: name.same_string (a_name)
		end

	set_description (a_description: READABLE_STRING_8)
			-- Update description.
		do
			description := a_description.to_string_8
		end

	set_target_count (a_count: INTEGER)
			-- Update target count.
		require
			positive: a_count >= 1
		do
			target_count := a_count
		ensure
			target_count_set: target_count = a_count
		end

	set_frequency_days (a_days: detachable READABLE_STRING_8)
			-- Set custom frequency days JSON.
		do
			if attached a_days as d then
				frequency_days := d.to_string_8
			else
				frequency_days := Void
			end
		end

	set_reminder_time (a_time: detachable READABLE_STRING_8)
			-- Set reminder time.
		do
			if attached a_time as t then
				reminder_time := t.to_string_8
			else
				reminder_time := Void
			end
		end

	set_archived (a_archived: BOOLEAN)
			-- Archive or unarchive habit.
		do
			is_archived := a_archived
		ensure
			is_archived_set: is_archived = a_archived
		end

	set_streak (a_current, a_best: INTEGER)
			-- Update streak values.
		require
			current_non_negative: a_current >= 0
			best_non_negative: a_best >= 0
			best_at_least_current: a_best >= a_current
		do
			streak_current := a_current
			streak_best := a_best
		ensure
			streak_current_set: streak_current = a_current
			streak_best_set: streak_best = a_best
		end

	increment_streak
			-- Increment current streak and update best if needed.
		do
			streak_current := streak_current + 1
			if streak_current > streak_best then
				streak_best := streak_current
			end
		ensure
			streak_increased: streak_current = old streak_current + 1
			best_updated: streak_best >= streak_current
		end

	break_streak
			-- Reset current streak to 0.
		do
			streak_current := 0
		ensure
			streak_broken: streak_current = 0
			best_preserved: streak_best = old streak_best
		end

	increment_total_completions
			-- Add one to total completions.
		do
			total_completions := total_completions + 1
		ensure
			incremented: total_completions = old total_completions + 1
		end

	set_xp_per_completion (a_xp: INTEGER)
			-- Update base XP.
		require
			positive: a_xp > 0
		do
			xp_per_completion := a_xp
		ensure
			xp_set: xp_per_completion = a_xp
		end

	set_created_at (a_timestamp: READABLE_STRING_8)
			-- Set creation timestamp.
		require
			not_empty: not a_timestamp.is_empty
		do
			created_at := a_timestamp.to_string_8
		end

invariant
	name_not_empty: not name.is_empty
	valid_user_id: user_id > 0
	valid_frequency_type: is_valid_frequency_type (frequency_type)
	target_count_positive: target_count >= 1
	streak_current_non_negative: streak_current >= 0
	streak_best_non_negative: streak_best >= 0
	best_at_least_current: streak_best >= streak_current
	total_completions_non_negative: total_completions >= 0
	xp_positive: xp_per_completion > 0
	id_non_negative: id >= 0

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
