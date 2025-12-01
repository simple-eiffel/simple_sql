note
	description: "Record of an achievement earned by a user"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	HABIT_USER_ACHIEVEMENT

create
	make,
	make_new

feature {NONE} -- Initialization

	make (a_id: INTEGER_64; a_user_id: INTEGER_64; a_achievement_id: INTEGER_64;
			a_habit_id: detachable INTEGER_64_REF; a_earned_at: READABLE_STRING_8;
			a_times_earned: INTEGER; a_xp_awarded: INTEGER)
			-- Initialize from database row.
		require
			valid_user: a_user_id > 0
			valid_achievement: a_achievement_id > 0
			times_positive: a_times_earned >= 1
			xp_positive: a_xp_awarded > 0
			earned_at_not_empty: not a_earned_at.is_empty
		do
			id := a_id
			user_id := a_user_id
			achievement_id := a_achievement_id
			if attached a_habit_id then
				habit_id := a_habit_id.item
			end
			earned_at := a_earned_at.to_string_8
			times_earned := a_times_earned
			xp_awarded := a_xp_awarded
		ensure
			id_set: id = a_id
			user_id_set: user_id = a_user_id
			achievement_id_set: achievement_id = a_achievement_id
		end

	make_new (a_user_id: INTEGER_64; a_achievement_id: INTEGER_64; a_xp_awarded: INTEGER)
			-- Create a new earned achievement record.
		require
			valid_user: a_user_id > 0
			valid_achievement: a_achievement_id > 0
			xp_positive: a_xp_awarded > 0
		do
			id := 0
			user_id := a_user_id
			achievement_id := a_achievement_id
			habit_id := 0
			earned_at := ""
			times_earned := 1
			xp_awarded := a_xp_awarded
		ensure
			id_zero: id = 0
			user_id_set: user_id = a_user_id
			achievement_id_set: achievement_id = a_achievement_id
			earned_once: times_earned = 1
		end

feature -- Access

	id: INTEGER_64
			-- Unique identifier (0 if not yet saved).

	user_id: INTEGER_64
			-- User who earned the achievement.

	achievement_id: INTEGER_64
			-- Achievement that was earned.

	habit_id: INTEGER_64
			-- Habit that triggered the achievement (0 if global achievement).

	earned_at: STRING_8
			-- Timestamp when first earned (ISO 8601).

	times_earned: INTEGER
			-- How many times earned (for repeatable achievements).

	xp_awarded: INTEGER
			-- Total XP awarded (may accumulate for repeatable).

feature -- Status

	is_new: BOOLEAN
			-- Has this record not yet been saved to database?
		do
			Result := id = 0
		end

	is_habit_specific: BOOLEAN
			-- Was this earned for a specific habit?
		do
			Result := habit_id > 0
		end

	is_global: BOOLEAN
			-- Is this a global (non-habit-specific) achievement?
		do
			Result := habit_id = 0
		end

	earned_multiple_times: BOOLEAN
			-- Has this been earned more than once?
		do
			Result := times_earned > 1
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

	set_habit_id (a_habit_id: INTEGER_64)
			-- Associate with a specific habit.
		require
			valid_id: a_habit_id >= 0
		do
			habit_id := a_habit_id
		ensure
			habit_id_set: habit_id = a_habit_id
		end

	increment_times_earned (a_additional_xp: INTEGER)
			-- Record another earning of a repeatable achievement.
		require
			xp_positive: a_additional_xp > 0
		do
			times_earned := times_earned + 1
			xp_awarded := xp_awarded + a_additional_xp
		ensure
			times_increased: times_earned = old times_earned + 1
			xp_increased: xp_awarded = old xp_awarded + a_additional_xp
		end

	set_earned_at (a_timestamp: READABLE_STRING_8)
			-- Set earned timestamp.
		require
			not_empty: not a_timestamp.is_empty
		do
			earned_at := a_timestamp.to_string_8
		end

invariant
	valid_user_id: user_id > 0
	valid_achievement_id: achievement_id > 0
	times_positive: times_earned >= 1
	xp_positive: xp_awarded > 0
	habit_id_non_negative: habit_id >= 0
	id_non_negative: id >= 0

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
