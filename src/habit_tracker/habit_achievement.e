note
	description: "Achievement definition - badges and milestones users can earn"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	HABIT_ACHIEVEMENT

create
	make,
	make_new

feature {NONE} -- Initialization

	make (a_id: INTEGER_64; a_code, a_name, a_description: READABLE_STRING_8;
			a_icon: READABLE_STRING_8; a_xp_reward: INTEGER;
			a_category: READABLE_STRING_8; a_threshold: INTEGER;
			a_is_hidden: BOOLEAN; a_is_repeatable: BOOLEAN)
			-- Initialize from database row.
		require
			code_not_empty: not a_code.is_empty
			name_not_empty: not a_name.is_empty
			xp_positive: a_xp_reward > 0
			category_not_empty: not a_category.is_empty
		do
			id := a_id
			code := a_code.to_string_8
			name := a_name.to_string_8
			description := a_description.to_string_8
			icon := a_icon.to_string_8
			xp_reward := a_xp_reward
			category := a_category.to_string_8
			threshold := a_threshold
			is_hidden := a_is_hidden
			is_repeatable := a_is_repeatable
		ensure
			id_set: id = a_id
			code_set: code.same_string (a_code)
			name_set: name.same_string (a_name)
		end

	make_new (a_code, a_name, a_description: READABLE_STRING_8;
			a_category: READABLE_STRING_8; a_xp_reward: INTEGER)
			-- Create a new achievement definition.
		require
			code_not_empty: not a_code.is_empty
			name_not_empty: not a_name.is_empty
			category_not_empty: not a_category.is_empty
			xp_positive: a_xp_reward > 0
		do
			id := 0
			code := a_code.to_string_8
			name := a_name.to_string_8
			description := a_description.to_string_8
			icon := "trophy"
			xp_reward := a_xp_reward
			category := a_category.to_string_8
			threshold := 1
			is_hidden := False
			is_repeatable := False
		ensure
			id_zero: id = 0
			code_set: code.same_string (a_code)
			name_set: name.same_string (a_name)
			default_icon: icon.same_string ("trophy")
			not_hidden: not is_hidden
			not_repeatable: not is_repeatable
		end

feature -- Access

	id: INTEGER_64
			-- Unique identifier (0 if not yet saved).

	code: STRING_8
			-- Unique code (e.g., "STREAK_7", "FIRST_COMPLETION", "PERFECT_WEEK").

	name: STRING_8
			-- Display name (e.g., "Week Warrior").

	description: STRING_8
			-- Description of how to earn it.

	icon: STRING_8
			-- Icon identifier (e.g., "trophy", "star", "fire").

	xp_reward: INTEGER
			-- XP bonus for earning this achievement.

	category: STRING_8
			-- Category: "streak", "completion", "consistency", "milestone", "special"

	threshold: INTEGER
			-- Numeric threshold for earning (e.g., 7 for 7-day streak).

	is_hidden: BOOLEAN
			-- Is this a secret/surprise achievement?

	is_repeatable: BOOLEAN
			-- Can this be earned multiple times?

feature -- Status

	is_new: BOOLEAN
			-- Has this achievement not yet been saved to database?
		do
			Result := id = 0
		end

	is_streak_achievement: BOOLEAN
			-- Is this a streak-based achievement?
		do
			Result := category.same_string ("streak")
		end

	is_completion_achievement: BOOLEAN
			-- Is this based on total completions?
		do
			Result := category.same_string ("completion")
		end

	is_consistency_achievement: BOOLEAN
			-- Is this for consistent behavior?
		do
			Result := category.same_string ("consistency")
		end

	is_milestone_achievement: BOOLEAN
			-- Is this a milestone achievement?
		do
			Result := category.same_string ("milestone")
		end

	is_special_achievement: BOOLEAN
			-- Is this a special/rare achievement?
		do
			Result := category.same_string ("special")
		end

	rarity_tier: STRING_8
			-- Estimated rarity based on threshold.
		do
			if threshold >= 365 then
				Result := "Legendary"
			elseif threshold >= 100 then
				Result := "Epic"
			elseif threshold >= 30 then
				Result := "Rare"
			elseif threshold >= 7 then
				Result := "Uncommon"
			else
				Result := "Common"
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

	set_icon (a_icon: READABLE_STRING_8)
			-- Update icon.
		require
			not_empty: not a_icon.is_empty
		do
			icon := a_icon.to_string_8
		ensure
			icon_set: icon.same_string (a_icon)
		end

	set_threshold (a_threshold: INTEGER)
			-- Update threshold.
		require
			positive: a_threshold >= 1
		do
			threshold := a_threshold
		ensure
			threshold_set: threshold = a_threshold
		end

	set_hidden (a_hidden: BOOLEAN)
			-- Set hidden status.
		do
			is_hidden := a_hidden
		ensure
			is_hidden_set: is_hidden = a_hidden
		end

	set_repeatable (a_repeatable: BOOLEAN)
			-- Set repeatable status.
		do
			is_repeatable := a_repeatable
		ensure
			is_repeatable_set: is_repeatable = a_repeatable
		end

feature -- Default Achievements (Factory)

	default_achievements: ARRAYED_LIST [TUPLE [code, name, description, category: STRING_8; xp: INTEGER; threshold: INTEGER]]
			-- Standard achievement templates.
		once
			create Result.make (20)
			-- Streak achievements
			Result.extend (["STREAK_3", "Getting Started", "Maintain a 3-day streak", "streak", 25, 3])
			Result.extend (["STREAK_7", "Week Warrior", "Maintain a 7-day streak", "streak", 50, 7])
			Result.extend (["STREAK_14", "Fortnight Fighter", "Maintain a 14-day streak", "streak", 100, 14])
			Result.extend (["STREAK_30", "Monthly Master", "Maintain a 30-day streak", "streak", 250, 30])
			Result.extend (["STREAK_60", "Two Month Titan", "Maintain a 60-day streak", "streak", 500, 60])
			Result.extend (["STREAK_90", "Quarterly Champion", "Maintain a 90-day streak", "streak", 750, 90])
			Result.extend (["STREAK_100", "Century Club", "Maintain a 100-day streak", "streak", 1000, 100])
			Result.extend (["STREAK_365", "Year of Dedication", "Maintain a 365-day streak", "streak", 5000, 365])

			-- Completion achievements
			Result.extend (["COMPLETE_1", "First Step", "Complete your first habit", "completion", 10, 1])
			Result.extend (["COMPLETE_10", "Getting Momentum", "Complete 10 habits total", "completion", 25, 10])
			Result.extend (["COMPLETE_50", "Half Century", "Complete 50 habits total", "completion", 75, 50])
			Result.extend (["COMPLETE_100", "Century Mark", "Complete 100 habits total", "completion", 150, 100])
			Result.extend (["COMPLETE_500", "Habit Machine", "Complete 500 habits total", "completion", 500, 500])
			Result.extend (["COMPLETE_1000", "Habit Legend", "Complete 1000 habits total", "completion", 1000, 1000])

			-- Consistency achievements
			Result.extend (["PERFECT_WEEK", "Perfect Week", "Complete all habits for 7 consecutive days", "consistency", 100, 7])
			Result.extend (["PERFECT_MONTH", "Perfect Month", "Complete all habits for 30 consecutive days", "consistency", 500, 30])

			-- Milestone achievements
			Result.extend (["LEVEL_5", "Rising Star", "Reach level 5", "milestone", 50, 5])
			Result.extend (["LEVEL_10", "Dedicated", "Reach level 10", "milestone", 100, 10])
			Result.extend (["LEVEL_25", "Committed", "Reach level 25", "milestone", 250, 25])
			Result.extend (["LEVEL_50", "Master", "Reach level 50", "milestone", 500, 50])
		end

invariant
	code_not_empty: not code.is_empty
	name_not_empty: not name.is_empty
	icon_not_empty: not icon.is_empty
	category_not_empty: not category.is_empty
	xp_positive: xp_reward > 0
	threshold_positive: threshold >= 1
	id_non_negative: id >= 0

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
