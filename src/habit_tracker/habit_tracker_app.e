note
	description: "Habit Tracker application facade demonstrating SIMPLE_SQL usage with gamification"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	HABIT_TRACKER_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize Habit Tracker with in-memory database.
		do
			create database.make_memory
			create_schema
			seed_achievements
		end

feature -- Access

	database: SIMPLE_SQL_DATABASE
			-- The underlying database connection.

feature -- User Management

	create_user (a_username, a_email, a_timezone: READABLE_STRING_8): HABIT_USER
			-- Create a new user and return it.
		require
			username_not_empty: not a_username.is_empty
			email_not_empty: not a_email.is_empty
			timezone_not_empty: not a_timezone.is_empty
		local
			l_user: HABIT_USER
			l_result: SIMPLE_SQL_RESULT
		do
			create l_user.make_new (a_username, a_email, a_timezone)
			database.execute_with_args (
				"INSERT INTO users (username, email, timezone, total_xp, level) VALUES (?, ?, ?, 0, 1)",
				<<a_username, a_email, a_timezone>>
			)
			l_user.set_id (database.last_insert_rowid)
			l_result := database.query_with_args ("SELECT created_at FROM users WHERE id = ?", <<l_user.id>>)
			if not l_result.is_empty then
				l_user.set_created_at (l_result.first.string_value ("created_at").to_string_8)
			end
			Result := l_user
		ensure
			result_saved: not Result.is_new
			username_matches: Result.username.same_string (a_username)
		end

	find_user (a_id: INTEGER_64): detachable HABIT_USER
			-- Find user by ID or Void if not found.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args ("SELECT * FROM users WHERE id = ?", <<a_id>>)
			if not l_result.is_empty then
				Result := row_to_user (l_result.first)
			end
		end

	find_user_by_username (a_username: READABLE_STRING_8): detachable HABIT_USER
			-- Find user by username.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args ("SELECT * FROM users WHERE username = ?", <<a_username>>)
			if not l_result.is_empty then
				Result := row_to_user (l_result.first)
			end
		end

	find_user_by_email (a_email: READABLE_STRING_8): detachable HABIT_USER
			-- Find user by email.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args ("SELECT * FROM users WHERE email = ?", <<a_email>>)
			if not l_result.is_empty then
				Result := row_to_user (l_result.first)
			end
		end

	all_users: ARRAYED_LIST [HABIT_USER]
			-- Get all users ordered by username.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (10)
			l_result := database.query ("SELECT * FROM users ORDER BY username")
			across l_result.rows as ic loop
				Result.extend (row_to_user (ic))
			end
		end

	user_count: INTEGER
			-- Total number of users.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query ("SELECT COUNT(*) as cnt FROM users")
			if not l_result.is_empty then
				Result := l_result.first.integer_value ("cnt")
			end
		end

feature -- Category Management

	create_category (a_user_id: INTEGER_64; a_name: READABLE_STRING_8): HABIT_CATEGORY
			-- Create a new category.
		require
			valid_user: a_user_id > 0
			name_not_empty: not a_name.is_empty
		local
			l_cat: HABIT_CATEGORY
			l_sort_order: INTEGER
		do
			l_sort_order := next_category_sort_order (a_user_id)
			create l_cat.make_new (a_user_id, a_name)
			l_cat.set_sort_order (l_sort_order)
			database.execute_with_args (
				"INSERT INTO categories (user_id, name, color, icon, sort_order) VALUES (?, ?, ?, ?, ?)",
				<<a_user_id, a_name, l_cat.color, l_cat.icon, l_sort_order>>
			)
			l_cat.set_id (database.last_insert_rowid)
			Result := l_cat
		ensure
			result_saved: not Result.is_new
			name_matches: Result.name.same_string (a_name)
		end

	create_category_with_style (a_user_id: INTEGER_64; a_name, a_color, a_icon: READABLE_STRING_8): HABIT_CATEGORY
			-- Create a new category with custom styling.
		require
			valid_user: a_user_id > 0
			name_not_empty: not a_name.is_empty
			color_not_empty: not a_color.is_empty
			icon_not_empty: not a_icon.is_empty
		local
			l_cat: HABIT_CATEGORY
			l_sort_order: INTEGER
		do
			l_sort_order := next_category_sort_order (a_user_id)
			create l_cat.make (0, a_user_id, a_name, a_color, a_icon, l_sort_order)
			database.execute_with_args (
				"INSERT INTO categories (user_id, name, color, icon, sort_order) VALUES (?, ?, ?, ?, ?)",
				<<a_user_id, a_name, a_color, a_icon, l_sort_order>>
			)
			l_cat.set_id (database.last_insert_rowid)
			Result := l_cat
		ensure
			result_saved: not Result.is_new
		end

	find_category (a_id: INTEGER_64): detachable HABIT_CATEGORY
			-- Find category by ID.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args ("SELECT * FROM categories WHERE id = ?", <<a_id>>)
			if not l_result.is_empty then
				Result := row_to_category (l_result.first)
			end
		end

	user_categories (a_user_id: INTEGER_64): ARRAYED_LIST [HABIT_CATEGORY]
			-- Get all categories for a user ordered by sort_order.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (10)
			l_result := database.query_with_args (
				"SELECT * FROM categories WHERE user_id = ? ORDER BY sort_order",
				<<a_user_id>>
			)
			across l_result.rows as ic loop
				Result.extend (row_to_category (ic))
			end
		end

	seed_default_categories (a_user_id: INTEGER_64)
			-- Create default category set for a user.
		local
			l_cat: HABIT_CATEGORY
			l_ignored: HABIT_CATEGORY
		do
			-- Create dummy instance just to access default_categories factory
			create l_cat.make_new (a_user_id, "Dummy")
			across l_cat.default_categories as ic loop
				l_ignored := create_category_with_style (a_user_id, ic.name, ic.color, ic.icon)
			end
		end

feature -- Habit Management

	create_habit (a_user_id: INTEGER_64; a_name, a_frequency_type: READABLE_STRING_8): HABIT
			-- Create a new habit with defaults.
		require
			valid_user: a_user_id > 0
			name_not_empty: not a_name.is_empty
		local
			l_habit: HABIT
			l_result: SIMPLE_SQL_RESULT
		do
			create l_habit.make_new (a_user_id, a_name, a_frequency_type)
			database.execute_with_args (
				"INSERT INTO habits (user_id, name, description, frequency_type, frequency_value, target_count, is_archived, streak_current, streak_best, total_completions, xp_per_completion) VALUES (?, ?, '', ?, 1, 1, 0, 0, 0, 0, 10)",
				<<a_user_id, a_name, a_frequency_type>>
			)
			l_habit.set_id (database.last_insert_rowid)
			l_result := database.query_with_args ("SELECT created_at FROM habits WHERE id = ?", <<l_habit.id>>)
			if not l_result.is_empty then
				l_habit.set_created_at (l_result.first.string_value ("created_at").to_string_8)
			end
			Result := l_habit
		ensure
			result_saved: not Result.is_new
			name_matches: Result.name.same_string (a_name)
		end

	create_habit_full (a_user_id: INTEGER_64; a_category_id: INTEGER_64;
			a_name, a_description: READABLE_STRING_8;
			a_frequency_type: READABLE_STRING_8; a_frequency_value: INTEGER;
			a_frequency_days: detachable READABLE_STRING_8;
			a_target_count: INTEGER; a_xp_per_completion: INTEGER): HABIT
			-- Create a habit with all options.
		require
			valid_user: a_user_id > 0
			name_not_empty: not a_name.is_empty
			target_positive: a_target_count >= 1
			xp_positive: a_xp_per_completion > 0
		local
			l_habit: HABIT
			l_result: SIMPLE_SQL_RESULT
		do
			create l_habit.make_new (a_user_id, a_name, a_frequency_type)
			l_habit.set_category_id (a_category_id)
			l_habit.set_description (a_description)
			l_habit.set_frequency_days (a_frequency_days)
			l_habit.set_target_count (a_target_count)
			l_habit.set_xp_per_completion (a_xp_per_completion)

			database.execute_with_args (
				"INSERT INTO habits (user_id, category_id, name, description, frequency_type, frequency_value, frequency_days, target_count, is_archived, streak_current, streak_best, total_completions, xp_per_completion) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, 0, 0, 0, ?)",
				<<a_user_id, a_category_id, a_name, a_description, a_frequency_type, a_frequency_value, a_frequency_days, a_target_count, a_xp_per_completion>>
			)
			l_habit.set_id (database.last_insert_rowid)
			l_result := database.query_with_args ("SELECT created_at FROM habits WHERE id = ?", <<l_habit.id>>)
			if not l_result.is_empty then
				l_habit.set_created_at (l_result.first.string_value ("created_at").to_string_8)
			end
			Result := l_habit
		ensure
			result_saved: not Result.is_new
		end

	find_habit (a_id: INTEGER_64): detachable HABIT
			-- Find habit by ID.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args ("SELECT * FROM habits WHERE id = ?", <<a_id>>)
			if not l_result.is_empty then
				Result := row_to_habit (l_result.first)
			end
		end

	user_habits (a_user_id: INTEGER_64): ARRAYED_LIST [HABIT]
			-- Get all active (non-archived) habits for a user.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (20)
			l_result := database.query_with_args (
				"SELECT * FROM habits WHERE user_id = ? AND is_archived = 0 ORDER BY name",
				<<a_user_id>>
			)
			across l_result.rows as ic loop
				Result.extend (row_to_habit (ic))
			end
		end

	user_habits_by_category (a_user_id: INTEGER_64; a_category_id: INTEGER_64): ARRAYED_LIST [HABIT]
			-- Get habits in a specific category.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (10)
			l_result := database.query_with_args (
				"SELECT * FROM habits WHERE user_id = ? AND category_id = ? AND is_archived = 0 ORDER BY name",
				<<a_user_id, a_category_id>>
			)
			across l_result.rows as ic loop
				Result.extend (row_to_habit (ic))
			end
		end

	user_archived_habits (a_user_id: INTEGER_64): ARRAYED_LIST [HABIT]
			-- Get archived habits for a user.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (10)
			l_result := database.query_with_args (
				"SELECT * FROM habits WHERE user_id = ? AND is_archived = 1 ORDER BY name",
				<<a_user_id>>
			)
			across l_result.rows as ic loop
				Result.extend (row_to_habit (ic))
			end
		end

	archive_habit (a_habit_id: INTEGER_64)
			-- Archive a habit (soft delete).
		do
			database.execute_with_args ("UPDATE habits SET is_archived = 1 WHERE id = ?", <<a_habit_id>>)
		end

	unarchive_habit (a_habit_id: INTEGER_64)
			-- Restore an archived habit.
		do
			database.execute_with_args ("UPDATE habits SET is_archived = 0 WHERE id = ?", <<a_habit_id>>)
		end

	habit_count (a_user_id: INTEGER_64): INTEGER
			-- Count of active habits for a user.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args (
				"SELECT COUNT(*) as cnt FROM habits WHERE user_id = ? AND is_archived = 0",
				<<a_user_id>>
			)
			if not l_result.is_empty then
				Result := l_result.first.integer_value ("cnt")
			end
		end

feature -- Completion Management

	complete_habit (a_habit_id: INTEGER_64; a_user_id: INTEGER_64): HABIT_COMPLETION
			-- Record a habit completion and process gamification.
		require
			valid_habit: a_habit_id > 0
			valid_user: a_user_id > 0
		local
			l_completion: HABIT_COMPLETION
			l_xp: INTEGER
			l_result: SIMPLE_SQL_RESULT
		do
			-- First increment the streak so XP calculation uses the new value
			database.execute_with_args (
				"UPDATE habits SET total_completions = total_completions + 1, streak_current = streak_current + 1 WHERE id = ?",
				<<a_habit_id>>
			)

			-- Update best streak if needed
			database.execute_with_args (
				"UPDATE habits SET streak_best = streak_current WHERE id = ? AND streak_current > streak_best",
				<<a_habit_id>>
			)

			-- Now calculate XP based on the updated streak
			if attached find_habit (a_habit_id) as l_habit then
				-- Calculate XP (base + streak bonus) using updated streak
				l_xp := l_habit.total_xp_for_completion
			else
				l_xp := 10 -- Default if habit not found
			end

			-- Create completion record
			create l_completion.make_new (a_habit_id, a_user_id, l_xp)
			database.execute_with_args (
				"INSERT INTO completions (habit_id, user_id, completion_count, xp_earned) VALUES (?, ?, 1, ?)",
				<<a_habit_id, a_user_id, l_xp>>
			)
			l_completion.set_id (database.last_insert_rowid)
			l_result := database.query_with_args ("SELECT completed_at FROM completions WHERE id = ?", <<l_completion.id>>)
			if not l_result.is_empty then
				l_completion.set_completed_at (l_result.first.string_value ("completed_at").to_string_8)
			end

			-- Award XP to user
			award_xp (a_user_id, l_xp)

			-- Check for achievements
			check_streak_achievements (a_user_id, a_habit_id)
			check_completion_achievements (a_user_id)

			Result := l_completion
		ensure
			result_saved: not Result.is_new
		end

	complete_habit_with_details (a_habit_id: INTEGER_64; a_user_id: INTEGER_64;
			a_mood, a_energy: INTEGER; a_notes: detachable READABLE_STRING_8): HABIT_COMPLETION
			-- Record a habit completion with mood/energy/notes.
		require
			valid_habit: a_habit_id > 0
			valid_user: a_user_id > 0
			valid_mood: a_mood >= 0 and a_mood <= 5
			valid_energy: a_energy >= 0 and a_energy <= 5
		local
			l_completion: HABIT_COMPLETION
			l_xp: INTEGER
			l_result: SIMPLE_SQL_RESULT
		do
			-- First increment the streak so XP calculation uses the new value
			database.execute_with_args (
				"UPDATE habits SET total_completions = total_completions + 1, streak_current = streak_current + 1 WHERE id = ?",
				<<a_habit_id>>
			)
			database.execute_with_args (
				"UPDATE habits SET streak_best = streak_current WHERE id = ? AND streak_current > streak_best",
				<<a_habit_id>>
			)

			-- Now calculate XP based on the updated streak
			if attached find_habit (a_habit_id) as l_habit then
				l_xp := l_habit.total_xp_for_completion
			else
				l_xp := 10 -- Default if habit not found
			end

			create l_completion.make_new (a_habit_id, a_user_id, l_xp)
			l_completion.set_mood (a_mood)
			l_completion.set_energy (a_energy)
			l_completion.set_notes (a_notes)

			database.execute_with_args (
				"INSERT INTO completions (habit_id, user_id, completion_count, mood, energy, notes, xp_earned) VALUES (?, ?, 1, ?, ?, ?, ?)",
				<<a_habit_id, a_user_id, a_mood, a_energy, a_notes, l_xp>>
			)
			l_completion.set_id (database.last_insert_rowid)
			l_result := database.query_with_args ("SELECT completed_at FROM completions WHERE id = ?", <<l_completion.id>>)
			if not l_result.is_empty then
				l_completion.set_completed_at (l_result.first.string_value ("completed_at").to_string_8)
			end

			award_xp (a_user_id, l_xp)
			check_streak_achievements (a_user_id, a_habit_id)
			check_completion_achievements (a_user_id)

			Result := l_completion
		ensure
			result_saved: not Result.is_new
		end

	habit_completions (a_habit_id: INTEGER_64): ARRAYED_LIST [HABIT_COMPLETION]
			-- Get all completions for a habit.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (50)
			l_result := database.query_with_args (
				"SELECT * FROM completions WHERE habit_id = ? ORDER BY completed_at DESC",
				<<a_habit_id>>
			)
			across l_result.rows as ic loop
				Result.extend (row_to_completion (ic))
			end
		end

	user_completions_today (a_user_id: INTEGER_64): ARRAYED_LIST [HABIT_COMPLETION]
			-- Get completions for a user today.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (20)
			l_result := database.query_with_args (
				"SELECT * FROM completions WHERE user_id = ? AND date(completed_at) = date('now') ORDER BY completed_at DESC",
				<<a_user_id>>
			)
			across l_result.rows as ic loop
				Result.extend (row_to_completion (ic))
			end
		end

	completion_count_today (a_user_id: INTEGER_64): INTEGER
			-- Count completions today.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args (
				"SELECT COUNT(*) as cnt FROM completions WHERE user_id = ? AND date(completed_at) = date('now')",
				<<a_user_id>>
			)
			if not l_result.is_empty then
				Result := l_result.first.integer_value ("cnt")
			end
		end

	total_completions (a_user_id: INTEGER_64): INTEGER
			-- Total lifetime completions for a user.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args (
				"SELECT COUNT(*) as cnt FROM completions WHERE user_id = ?",
				<<a_user_id>>
			)
			if not l_result.is_empty then
				Result := l_result.first.integer_value ("cnt")
			end
		end

feature -- Streak Management

	break_habit_streak (a_habit_id: INTEGER_64)
			-- Break the current streak for a habit.
		do
			database.execute_with_args ("UPDATE habits SET streak_current = 0 WHERE id = ?", <<a_habit_id>>)
		end

	get_habit_streak (a_habit_id: INTEGER_64): INTEGER
			-- Get current streak for a habit.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args ("SELECT streak_current FROM habits WHERE id = ?", <<a_habit_id>>)
			if not l_result.is_empty then
				Result := l_result.first.integer_value ("streak_current")
			end
		end

	get_best_streak (a_habit_id: INTEGER_64): INTEGER
			-- Get best streak for a habit.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args ("SELECT streak_best FROM habits WHERE id = ?", <<a_habit_id>>)
			if not l_result.is_empty then
				Result := l_result.first.integer_value ("streak_best")
			end
		end

	longest_active_streak (a_user_id: INTEGER_64): INTEGER
			-- Longest current streak across all habits.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args (
				"SELECT MAX(streak_current) as max_streak FROM habits WHERE user_id = ? AND is_archived = 0",
				<<a_user_id>>
			)
			if not l_result.is_empty then
				Result := l_result.first.integer_value ("max_streak")
			end
		end

	habits_with_active_streaks (a_user_id: INTEGER_64): ARRAYED_LIST [HABIT]
			-- Get habits that have active streaks.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (10)
			l_result := database.query_with_args (
				"SELECT * FROM habits WHERE user_id = ? AND is_archived = 0 AND streak_current > 0 ORDER BY streak_current DESC",
				<<a_user_id>>
			)
			across l_result.rows as ic loop
				Result.extend (row_to_habit (ic))
			end
		end

feature -- XP and Leveling

	award_xp (a_user_id: INTEGER_64; a_xp: INTEGER)
			-- Award XP to a user and recalculate level.
		require
			positive_xp: a_xp > 0
		local
			l_user: detachable HABIT_USER
			l_new_level: INTEGER
		do
			database.execute_with_args ("UPDATE users SET total_xp = total_xp + ? WHERE id = ?", <<a_xp, a_user_id>>)

			-- Recalculate level
			l_user := find_user (a_user_id)
			if attached l_user then
				l_new_level := l_user.calculated_level
				database.execute_with_args ("UPDATE users SET level = ? WHERE id = ?", <<l_new_level, a_user_id>>)

				-- Check for level-up achievements
				check_level_achievements (a_user_id, l_new_level)
			end
		end

	user_xp (a_user_id: INTEGER_64): INTEGER
			-- Get total XP for a user.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args ("SELECT total_xp FROM users WHERE id = ?", <<a_user_id>>)
			if not l_result.is_empty then
				Result := l_result.first.integer_value ("total_xp")
			end
		end

	user_level (a_user_id: INTEGER_64): INTEGER
			-- Get current level for a user.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args ("SELECT level FROM users WHERE id = ?", <<a_user_id>>)
			if not l_result.is_empty then
				Result := l_result.first.integer_value ("level")
			end
		end

	xp_earned_today (a_user_id: INTEGER_64): INTEGER
			-- XP earned today.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args (
				"SELECT COALESCE(SUM(xp_earned), 0) as total FROM completions WHERE user_id = ? AND date(completed_at) = date('now')",
				<<a_user_id>>
			)
			if not l_result.is_empty then
				Result := l_result.first.integer_value ("total")
			end
		end

feature -- Achievement Management

	find_achievement_by_code (a_code: READABLE_STRING_8): detachable HABIT_ACHIEVEMENT
			-- Find achievement by code.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args ("SELECT * FROM achievements WHERE code = ?", <<a_code>>)
			if not l_result.is_empty then
				Result := row_to_achievement (l_result.first)
			end
		end

	all_achievements: ARRAYED_LIST [HABIT_ACHIEVEMENT]
			-- Get all achievements.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (30)
			l_result := database.query ("SELECT * FROM achievements ORDER BY category, threshold")
			across l_result.rows as ic loop
				Result.extend (row_to_achievement (ic))
			end
		end

	user_achievements (a_user_id: INTEGER_64): ARRAYED_LIST [HABIT_USER_ACHIEVEMENT]
			-- Get achievements earned by a user.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (20)
			l_result := database.query_with_args (
				"SELECT * FROM user_achievements WHERE user_id = ? ORDER BY earned_at DESC",
				<<a_user_id>>
			)
			across l_result.rows as ic loop
				Result.extend (row_to_user_achievement (ic))
			end
		end

	has_achievement (a_user_id: INTEGER_64; a_achievement_code: READABLE_STRING_8): BOOLEAN
			-- Does user have this achievement?
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args (
				"SELECT 1 FROM user_achievements ua INNER JOIN achievements a ON ua.achievement_id = a.id WHERE ua.user_id = ? AND a.code = ?",
				<<a_user_id, a_achievement_code>>
			)
			Result := not l_result.is_empty
		end

	achievement_count (a_user_id: INTEGER_64): INTEGER
			-- Count of unique achievements earned.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args (
				"SELECT COUNT(DISTINCT achievement_id) as cnt FROM user_achievements WHERE user_id = ?",
				<<a_user_id>>
			)
			if not l_result.is_empty then
				Result := l_result.first.integer_value ("cnt")
			end
		end

	award_achievement (a_user_id: INTEGER_64; a_achievement_id: INTEGER_64; a_habit_id: INTEGER_64)
			-- Award an achievement to a user.
		local
			l_achievement: detachable HABIT_ACHIEVEMENT
			l_result: SIMPLE_SQL_RESULT
			l_existing_id: INTEGER_64
		do
			l_achievement := find_achievement (a_achievement_id)
			if attached l_achievement then
				-- Check if already earned
				l_result := database.query_with_args (
					"SELECT id FROM user_achievements WHERE user_id = ? AND achievement_id = ?",
					<<a_user_id, a_achievement_id>>
				)

				if l_result.is_empty then
					-- First time earning
					database.execute_with_args (
						"INSERT INTO user_achievements (user_id, achievement_id, habit_id, times_earned, xp_awarded) VALUES (?, ?, ?, 1, ?)",
						<<a_user_id, a_achievement_id, a_habit_id, l_achievement.xp_reward>>
					)
					-- Bonus XP for achievement
					award_xp (a_user_id, l_achievement.xp_reward)
				elseif l_achievement.is_repeatable then
					-- Earn again
					l_existing_id := l_result.first.integer_64_value ("id")
					database.execute_with_args (
						"UPDATE user_achievements SET times_earned = times_earned + 1, xp_awarded = xp_awarded + ? WHERE id = ?",
						<<l_achievement.xp_reward, l_existing_id>>
					)
					award_xp (a_user_id, l_achievement.xp_reward)
				end
			end
		end

feature -- Statistics

	mood_average (a_user_id: INTEGER_64): REAL_64
			-- Average mood across all completions.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args (
				"SELECT AVG(mood) as avg_mood FROM completions WHERE user_id = ? AND mood > 0",
				<<a_user_id>>
			)
			if not l_result.is_empty then
				Result := l_result.first.real_value ("avg_mood")
			end
		end

	energy_average (a_user_id: INTEGER_64): REAL_64
			-- Average energy across all completions.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args (
				"SELECT AVG(energy) as avg_energy FROM completions WHERE user_id = ? AND energy > 0",
				<<a_user_id>>
			)
			if not l_result.is_empty then
				Result := l_result.first.real_value ("avg_energy")
			end
		end

	completions_by_day_of_week (a_user_id: INTEGER_64): HASH_TABLE [INTEGER, INTEGER]
			-- Completion count by day of week (0=Sunday, 6=Saturday).
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (7)
			l_result := database.query_with_args (
				"SELECT strftime('%%w', completed_at) as dow, COUNT(*) as cnt FROM completions WHERE user_id = ? GROUP BY dow",
				<<a_user_id>>
			)
			across l_result.rows as ic loop
				Result.put (ic.integer_value ("cnt"), ic.string_value ("dow").to_integer)
			end
		end

	most_consistent_habit (a_user_id: INTEGER_64): detachable HABIT
			-- Habit with highest total completions.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args (
				"SELECT * FROM habits WHERE user_id = ? AND is_archived = 0 ORDER BY total_completions DESC LIMIT 1",
				<<a_user_id>>
			)
			if not l_result.is_empty then
				Result := row_to_habit (l_result.first)
			end
		end

feature -- Cleanup

	close
			-- Close the database connection.
		do
			database.close
		end

feature {NONE} -- Implementation: Schema

	create_schema
			-- Create the database schema.
		do
			-- Users table
			database.execute ("[
				CREATE TABLE IF NOT EXISTS users (
					id INTEGER PRIMARY KEY AUTOINCREMENT,
					username TEXT NOT NULL UNIQUE,
					email TEXT NOT NULL UNIQUE,
					timezone TEXT NOT NULL DEFAULT 'UTC',
					total_xp INTEGER DEFAULT 0,
					level INTEGER DEFAULT 1,
					settings TEXT,
					created_at TEXT DEFAULT (datetime('now'))
				)
			]")

			-- Categories table
			database.execute ("[
				CREATE TABLE IF NOT EXISTS categories (
					id INTEGER PRIMARY KEY AUTOINCREMENT,
					user_id INTEGER NOT NULL,
					name TEXT NOT NULL,
					color TEXT NOT NULL DEFAULT '#6366F1',
					icon TEXT NOT NULL DEFAULT 'folder',
					sort_order INTEGER DEFAULT 0,
					FOREIGN KEY (user_id) REFERENCES users(id)
				)
			]")

			-- Habits table
			database.execute ("[
				CREATE TABLE IF NOT EXISTS habits (
					id INTEGER PRIMARY KEY AUTOINCREMENT,
					user_id INTEGER NOT NULL,
					category_id INTEGER,
					name TEXT NOT NULL,
					description TEXT DEFAULT '',
					frequency_type TEXT NOT NULL DEFAULT 'daily',
					frequency_value INTEGER DEFAULT 1,
					frequency_days TEXT,
					target_count INTEGER DEFAULT 1,
					reminder_time TEXT,
					is_archived INTEGER DEFAULT 0,
					streak_current INTEGER DEFAULT 0,
					streak_best INTEGER DEFAULT 0,
					total_completions INTEGER DEFAULT 0,
					xp_per_completion INTEGER DEFAULT 10,
					created_at TEXT DEFAULT (datetime('now')),
					FOREIGN KEY (user_id) REFERENCES users(id),
					FOREIGN KEY (category_id) REFERENCES categories(id)
				)
			]")

			-- Completions table
			database.execute ("[
				CREATE TABLE IF NOT EXISTS completions (
					id INTEGER PRIMARY KEY AUTOINCREMENT,
					habit_id INTEGER NOT NULL,
					user_id INTEGER NOT NULL,
					completed_at TEXT DEFAULT (datetime('now')),
					completion_count INTEGER DEFAULT 1,
					mood INTEGER,
					energy INTEGER,
					notes TEXT,
					xp_earned INTEGER NOT NULL,
					FOREIGN KEY (habit_id) REFERENCES habits(id),
					FOREIGN KEY (user_id) REFERENCES users(id)
				)
			]")

			-- Streaks history table
			database.execute ("[
				CREATE TABLE IF NOT EXISTS streaks (
					id INTEGER PRIMARY KEY AUTOINCREMENT,
					habit_id INTEGER NOT NULL,
					user_id INTEGER NOT NULL,
					start_date TEXT NOT NULL,
					end_date TEXT,
					length INTEGER DEFAULT 0,
					is_active INTEGER DEFAULT 1,
					FOREIGN KEY (habit_id) REFERENCES habits(id),
					FOREIGN KEY (user_id) REFERENCES users(id)
				)
			]")

			-- Achievements table
			database.execute ("[
				CREATE TABLE IF NOT EXISTS achievements (
					id INTEGER PRIMARY KEY AUTOINCREMENT,
					code TEXT NOT NULL UNIQUE,
					name TEXT NOT NULL,
					description TEXT NOT NULL,
					icon TEXT NOT NULL DEFAULT 'trophy',
					xp_reward INTEGER NOT NULL,
					category TEXT NOT NULL,
					threshold INTEGER DEFAULT 1,
					is_hidden INTEGER DEFAULT 0,
					is_repeatable INTEGER DEFAULT 0
				)
			]")

			-- User achievements table
			database.execute ("[
				CREATE TABLE IF NOT EXISTS user_achievements (
					id INTEGER PRIMARY KEY AUTOINCREMENT,
					user_id INTEGER NOT NULL,
					achievement_id INTEGER NOT NULL,
					habit_id INTEGER,
					earned_at TEXT DEFAULT (datetime('now')),
					times_earned INTEGER DEFAULT 1,
					xp_awarded INTEGER NOT NULL,
					FOREIGN KEY (user_id) REFERENCES users(id),
					FOREIGN KEY (achievement_id) REFERENCES achievements(id),
					FOREIGN KEY (habit_id) REFERENCES habits(id)
				)
			]")

			-- Indexes
			database.execute ("CREATE INDEX IF NOT EXISTS idx_habits_user ON habits(user_id)")
			database.execute ("CREATE INDEX IF NOT EXISTS idx_habits_category ON habits(category_id)")
			database.execute ("CREATE INDEX IF NOT EXISTS idx_completions_habit ON completions(habit_id)")
			database.execute ("CREATE INDEX IF NOT EXISTS idx_completions_user ON completions(user_id)")
			database.execute ("CREATE INDEX IF NOT EXISTS idx_completions_date ON completions(completed_at)")
			database.execute ("CREATE INDEX IF NOT EXISTS idx_streaks_habit ON streaks(habit_id)")
			database.execute ("CREATE INDEX IF NOT EXISTS idx_user_achievements_user ON user_achievements(user_id)")
		end

	seed_achievements
			-- Seed the achievements table with defaults.
		local
			l_ach: HABIT_ACHIEVEMENT
		do
			-- Create dummy instance just to access default_achievements factory
			create l_ach.make_new ("DUMMY", "Dummy", "Dummy achievement", "milestone", 1)
			across l_ach.default_achievements as ic loop
				database.execute_with_args (
					"INSERT OR IGNORE INTO achievements (code, name, description, category, xp_reward, threshold) VALUES (?, ?, ?, ?, ?, ?)",
					<<ic.code, ic.name, ic.description, ic.category, ic.xp, ic.threshold>>
				)
			end
		end

feature {NONE} -- Implementation: Achievement Checking

	check_streak_achievements (a_user_id: INTEGER_64; a_habit_id: INTEGER_64)
			-- Check and award streak-based achievements.
		local
			l_streak: INTEGER
			l_achievement: detachable HABIT_ACHIEVEMENT
		do
			l_streak := get_habit_streak (a_habit_id)

			-- Check each streak threshold
			if l_streak >= 3 then
				l_achievement := find_achievement_by_code ("STREAK_3")
				if attached l_achievement then
					award_achievement (a_user_id, l_achievement.id, a_habit_id)
				end
			end
			if l_streak >= 7 then
				l_achievement := find_achievement_by_code ("STREAK_7")
				if attached l_achievement then
					award_achievement (a_user_id, l_achievement.id, a_habit_id)
				end
			end
			if l_streak >= 14 then
				l_achievement := find_achievement_by_code ("STREAK_14")
				if attached l_achievement then
					award_achievement (a_user_id, l_achievement.id, a_habit_id)
				end
			end
			if l_streak >= 30 then
				l_achievement := find_achievement_by_code ("STREAK_30")
				if attached l_achievement then
					award_achievement (a_user_id, l_achievement.id, a_habit_id)
				end
			end
			if l_streak >= 60 then
				l_achievement := find_achievement_by_code ("STREAK_60")
				if attached l_achievement then
					award_achievement (a_user_id, l_achievement.id, a_habit_id)
				end
			end
			if l_streak >= 90 then
				l_achievement := find_achievement_by_code ("STREAK_90")
				if attached l_achievement then
					award_achievement (a_user_id, l_achievement.id, a_habit_id)
				end
			end
			if l_streak >= 100 then
				l_achievement := find_achievement_by_code ("STREAK_100")
				if attached l_achievement then
					award_achievement (a_user_id, l_achievement.id, a_habit_id)
				end
			end
			if l_streak >= 365 then
				l_achievement := find_achievement_by_code ("STREAK_365")
				if attached l_achievement then
					award_achievement (a_user_id, l_achievement.id, a_habit_id)
				end
			end
		end

	check_completion_achievements (a_user_id: INTEGER_64)
			-- Check and award completion-based achievements.
		local
			l_total: INTEGER
			l_achievement: detachable HABIT_ACHIEVEMENT
		do
			l_total := total_completions (a_user_id)

			if l_total >= 1 then
				l_achievement := find_achievement_by_code ("COMPLETE_1")
				if attached l_achievement then
					award_achievement (a_user_id, l_achievement.id, 0)
				end
			end
			if l_total >= 10 then
				l_achievement := find_achievement_by_code ("COMPLETE_10")
				if attached l_achievement then
					award_achievement (a_user_id, l_achievement.id, 0)
				end
			end
			if l_total >= 50 then
				l_achievement := find_achievement_by_code ("COMPLETE_50")
				if attached l_achievement then
					award_achievement (a_user_id, l_achievement.id, 0)
				end
			end
			if l_total >= 100 then
				l_achievement := find_achievement_by_code ("COMPLETE_100")
				if attached l_achievement then
					award_achievement (a_user_id, l_achievement.id, 0)
				end
			end
			if l_total >= 500 then
				l_achievement := find_achievement_by_code ("COMPLETE_500")
				if attached l_achievement then
					award_achievement (a_user_id, l_achievement.id, 0)
				end
			end
			if l_total >= 1000 then
				l_achievement := find_achievement_by_code ("COMPLETE_1000")
				if attached l_achievement then
					award_achievement (a_user_id, l_achievement.id, 0)
				end
			end
		end

	check_level_achievements (a_user_id: INTEGER_64; a_level: INTEGER)
			-- Check and award level-based achievements.
		local
			l_achievement: detachable HABIT_ACHIEVEMENT
		do
			if a_level >= 5 then
				l_achievement := find_achievement_by_code ("LEVEL_5")
				if attached l_achievement then
					award_achievement (a_user_id, l_achievement.id, 0)
				end
			end
			if a_level >= 10 then
				l_achievement := find_achievement_by_code ("LEVEL_10")
				if attached l_achievement then
					award_achievement (a_user_id, l_achievement.id, 0)
				end
			end
			if a_level >= 25 then
				l_achievement := find_achievement_by_code ("LEVEL_25")
				if attached l_achievement then
					award_achievement (a_user_id, l_achievement.id, 0)
				end
			end
			if a_level >= 50 then
				l_achievement := find_achievement_by_code ("LEVEL_50")
				if attached l_achievement then
					award_achievement (a_user_id, l_achievement.id, 0)
				end
			end
		end

feature {NONE} -- Implementation: Helpers

	next_category_sort_order (a_user_id: INTEGER_64): INTEGER
			-- Get next sort order for categories.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args (
				"SELECT COALESCE(MAX(sort_order), -1) + 1 as next_order FROM categories WHERE user_id = ?",
				<<a_user_id>>
			)
			if not l_result.is_empty then
				Result := l_result.first.integer_value ("next_order")
			end
		end

	find_achievement (a_id: INTEGER_64): detachable HABIT_ACHIEVEMENT
			-- Find achievement by ID.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args ("SELECT * FROM achievements WHERE id = ?", <<a_id>>)
			if not l_result.is_empty then
				Result := row_to_achievement (l_result.first)
			end
		end

feature {NONE} -- Implementation: Row Mapping

	row_to_user (a_row: SIMPLE_SQL_ROW): HABIT_USER
			-- Convert result row to HABIT_USER.
		do
			create Result.make (
				a_row.integer_64_value ("id"),
				a_row.string_value ("username").to_string_8,
				a_row.string_value ("email").to_string_8,
				a_row.string_value ("timezone").to_string_8,
				a_row.integer_value ("total_xp"),
				a_row.integer_value ("level"),
				a_row.string_value_or_void ("settings"),
				a_row.string_value ("created_at").to_string_8
			)
		end

	row_to_category (a_row: SIMPLE_SQL_ROW): HABIT_CATEGORY
			-- Convert result row to HABIT_CATEGORY.
		do
			create Result.make (
				a_row.integer_64_value ("id"),
				a_row.integer_64_value ("user_id"),
				a_row.string_value ("name").to_string_8,
				a_row.string_value ("color").to_string_8,
				a_row.string_value ("icon").to_string_8,
				a_row.integer_value ("sort_order")
			)
		end

	row_to_habit (a_row: SIMPLE_SQL_ROW): HABIT
			-- Convert result row to HABIT.
		do
			create Result.make (
				a_row.integer_64_value ("id"),
				a_row.integer_64_value ("user_id"),
				a_row.integer_64_value_or_void ("category_id"),
				a_row.string_value ("name").to_string_8,
				a_row.string_value ("description").to_string_8,
				a_row.string_value ("frequency_type").to_string_8,
				a_row.integer_value ("frequency_value"),
				a_row.string_value_or_void ("frequency_days"),
				a_row.integer_value ("target_count"),
				a_row.string_value_or_void ("reminder_time"),
				a_row.boolean_value ("is_archived"),
				a_row.integer_value ("streak_current"),
				a_row.integer_value ("streak_best"),
				a_row.integer_value ("total_completions"),
				a_row.integer_value ("xp_per_completion"),
				a_row.string_value ("created_at").to_string_8
			)
		end

	row_to_completion (a_row: SIMPLE_SQL_ROW): HABIT_COMPLETION
			-- Convert result row to HABIT_COMPLETION.
		do
			create Result.make (
				a_row.integer_64_value ("id"),
				a_row.integer_64_value ("habit_id"),
				a_row.integer_64_value ("user_id"),
				a_row.string_value ("completed_at").to_string_8,
				a_row.integer_value ("completion_count"),
				a_row.integer_value_or_void ("mood"),
				a_row.integer_value_or_void ("energy"),
				a_row.string_value_or_void ("notes"),
				a_row.integer_value ("xp_earned")
			)
		end

	row_to_streak (a_row: SIMPLE_SQL_ROW): HABIT_STREAK
			-- Convert result row to HABIT_STREAK.
		do
			create Result.make (
				a_row.integer_64_value ("id"),
				a_row.integer_64_value ("habit_id"),
				a_row.integer_64_value ("user_id"),
				a_row.string_value ("start_date").to_string_8,
				a_row.string_value_or_void ("end_date"),
				a_row.integer_value ("length"),
				a_row.boolean_value ("is_active")
			)
		end

	row_to_achievement (a_row: SIMPLE_SQL_ROW): HABIT_ACHIEVEMENT
			-- Convert result row to HABIT_ACHIEVEMENT.
		do
			create Result.make (
				a_row.integer_64_value ("id"),
				a_row.string_value ("code").to_string_8,
				a_row.string_value ("name").to_string_8,
				a_row.string_value ("description").to_string_8,
				a_row.string_value ("icon").to_string_8,
				a_row.integer_value ("xp_reward"),
				a_row.string_value ("category").to_string_8,
				a_row.integer_value ("threshold"),
				a_row.boolean_value ("is_hidden"),
				a_row.boolean_value ("is_repeatable")
			)
		end

	row_to_user_achievement (a_row: SIMPLE_SQL_ROW): HABIT_USER_ACHIEVEMENT
			-- Convert result row to HABIT_USER_ACHIEVEMENT.
		do
			create Result.make (
				a_row.integer_64_value ("id"),
				a_row.integer_64_value ("user_id"),
				a_row.integer_64_value ("achievement_id"),
				a_row.integer_64_value_or_void ("habit_id"),
				a_row.string_value ("earned_at").to_string_8,
				a_row.integer_value ("times_earned"),
				a_row.integer_value ("xp_awarded")
			)
		end

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
