note
	description: "Tests for HABIT_TRACKER_APP consumer example"
	testing: "covers"
	testing: "execution/serial"

class
	TEST_HABIT_TRACKER_APP

inherit
	TEST_SET_BASE

feature -- Test routines: User Management

	test_create_user
			-- Test creating a user.
		local
			l_app: HABIT_TRACKER_APP
			l_user: HABIT_USER
		do
			create l_app.make
			l_user := l_app.create_user ("johndoe", "john@example.com", "America/New_York")

			assert_false ("is_saved", l_user.is_new)
			assert_strings_equal ("username", "johndoe", l_user.username)
			assert_strings_equal ("email", "john@example.com", l_user.email)
			assert_equal ("starts_level_1", 1, l_user.level)
			assert_equal ("starts_zero_xp", 0, l_user.total_xp)

			l_app.close
		end

	test_find_user_by_username
			-- Test finding a user by username.
		local
			l_app: HABIT_TRACKER_APP
			l_ignored: HABIT_USER
		do
			create l_app.make
			l_ignored := l_app.create_user ("findme", "find@example.com", "UTC")

			if attached l_app.find_user_by_username ("findme") as l_found then
				assert_strings_equal ("email_matches", "find@example.com", l_found.email)
			else
				assert_true ("found", False)
			end

			l_app.close
		end

	test_find_user_by_email
			-- Test finding a user by email.
		local
			l_app: HABIT_TRACKER_APP
			l_ignored: HABIT_USER
		do
			create l_app.make
			l_ignored := l_app.create_user ("emailuser", "unique@example.com", "UTC")

			if attached l_app.find_user_by_email ("unique@example.com") as l_found then
				assert_strings_equal ("username_matches", "emailuser", l_found.username)
			else
				assert_true ("found", False)
			end

			l_app.close
		end

	test_all_users
			-- Test retrieving all users.
		local
			l_app: HABIT_TRACKER_APP
			l_ignored: HABIT_USER
			l_users: ARRAYED_LIST [HABIT_USER]
		do
			create l_app.make
			l_ignored := l_app.create_user ("alpha", "alpha@example.com", "UTC")
			l_ignored := l_app.create_user ("beta", "beta@example.com", "UTC")
			l_ignored := l_app.create_user ("gamma", "gamma@example.com", "UTC")

			l_users := l_app.all_users

			assert_equal ("three_users", 3, l_users.count)
			-- Ordered by username
			assert_strings_equal ("first", "alpha", l_users.first.username)

			l_app.close
		end

feature -- Test routines: Category Management

	test_create_category
			-- Test creating a category.
		local
			l_app: HABIT_TRACKER_APP
			l_user: HABIT_USER
			l_cat: HABIT_CATEGORY
		do
			create l_app.make
			l_user := l_app.create_user ("catuser", "cat@example.com", "UTC")
			l_cat := l_app.create_category (l_user.id, "Health")

			assert_false ("is_saved", l_cat.is_new)
			assert_strings_equal ("name", "Health", l_cat.name)

			l_app.close
		end

	test_create_category_with_style
			-- Test creating a category with custom styling.
		local
			l_app: HABIT_TRACKER_APP
			l_user: HABIT_USER
			l_cat: HABIT_CATEGORY
		do
			create l_app.make
			l_user := l_app.create_user ("styleuser", "style@example.com", "UTC")
			l_cat := l_app.create_category_with_style (l_user.id, "Fitness", "#FF5733", "dumbbell")

			assert_strings_equal ("color", "#FF5733", l_cat.color)
			assert_strings_equal ("icon", "dumbbell", l_cat.icon)

			l_app.close
		end

	test_seed_default_categories
			-- Test seeding default categories.
		local
			l_app: HABIT_TRACKER_APP
			l_user: HABIT_USER
			l_cats: ARRAYED_LIST [HABIT_CATEGORY]
		do
			create l_app.make
			l_user := l_app.create_user ("seeduser", "seed@example.com", "UTC")
			l_app.seed_default_categories (l_user.id)

			l_cats := l_app.user_categories (l_user.id)

			assert_equal ("six_categories", 6, l_cats.count)

			l_app.close
		end

feature -- Test routines: Habit Management

	test_create_habit
			-- Test creating a habit.
		local
			l_app: HABIT_TRACKER_APP
			l_user: HABIT_USER
			l_habit: HABIT
		do
			create l_app.make
			l_user := l_app.create_user ("habituser", "habit@example.com", "UTC")
			l_habit := l_app.create_habit (l_user.id, "Drink Water", "daily")

			assert_false ("is_saved", l_habit.is_new)
			assert_strings_equal ("name", "Drink Water", l_habit.name)
			assert_true ("is_daily", l_habit.is_daily)
			assert_equal ("default_target", 1, l_habit.target_count)
			assert_equal ("default_xp", 10, l_habit.xp_per_completion)

			l_app.close
		end

	test_create_habit_full
			-- Test creating a habit with all options.
		local
			l_app: HABIT_TRACKER_APP
			l_user: HABIT_USER
			l_cat: HABIT_CATEGORY
			l_habit: HABIT
		do
			create l_app.make
			l_user := l_app.create_user ("fulluser", "full@example.com", "UTC")
			l_cat := l_app.create_category (l_user.id, "Health")

			l_habit := l_app.create_habit_full (
				l_user.id, l_cat.id,
				"Drink 8 Glasses", "Stay hydrated throughout the day",
				"daily", 1,
				Void,
				8, 15
			)

			assert_strings_equal ("description", "Stay hydrated throughout the day", l_habit.description)
			assert_equal ("target_8", 8, l_habit.target_count)
			assert_equal ("xp_15", 15, l_habit.xp_per_completion)
			assert_equal ("category_set", l_cat.id, l_habit.category_id)

			l_app.close
		end

	test_user_habits
			-- Test getting user habits.
		local
			l_app: HABIT_TRACKER_APP
			l_user: HABIT_USER
			l_ignored: HABIT
			l_habits: ARRAYED_LIST [HABIT]
		do
			create l_app.make
			l_user := l_app.create_user ("listuser", "list@example.com", "UTC")
			l_ignored := l_app.create_habit (l_user.id, "Exercise", "daily")
			l_ignored := l_app.create_habit (l_user.id, "Meditate", "daily")
			l_ignored := l_app.create_habit (l_user.id, "Read", "daily")

			l_habits := l_app.user_habits (l_user.id)

			assert_equal ("three_habits", 3, l_habits.count)

			l_app.close
		end

	test_archive_habit
			-- Test archiving a habit.
		local
			l_app: HABIT_TRACKER_APP
			l_user: HABIT_USER
			l_habit: HABIT
			l_habits: ARRAYED_LIST [HABIT]
			l_archived: ARRAYED_LIST [HABIT]
		do
			create l_app.make
			l_user := l_app.create_user ("archuser", "arch@example.com", "UTC")
			l_habit := l_app.create_habit (l_user.id, "Old Habit", "daily")

			l_app.archive_habit (l_habit.id)

			l_habits := l_app.user_habits (l_user.id)
			l_archived := l_app.user_archived_habits (l_user.id)

			assert_equal ("no_active", 0, l_habits.count)
			assert_equal ("one_archived", 1, l_archived.count)

			l_app.close
		end

	test_habits_by_category
			-- Test getting habits by category.
		local
			l_app: HABIT_TRACKER_APP
			l_user: HABIT_USER
			l_health, l_work: HABIT_CATEGORY
			l_ignored: HABIT
			l_health_habits: ARRAYED_LIST [HABIT]
		do
			create l_app.make
			l_user := l_app.create_user ("cathabits", "cath@example.com", "UTC")
			l_health := l_app.create_category (l_user.id, "Health")
			l_work := l_app.create_category (l_user.id, "Work")

			l_ignored := l_app.create_habit_full (l_user.id, l_health.id, "Exercise", "", "daily", 1, Void, 1, 10)
			l_ignored := l_app.create_habit_full (l_user.id, l_health.id, "Sleep 8h", "", "daily", 1, Void, 1, 10)
			l_ignored := l_app.create_habit_full (l_user.id, l_work.id, "Review PRs", "", "daily", 1, Void, 1, 10)

			l_health_habits := l_app.user_habits_by_category (l_user.id, l_health.id)

			assert_equal ("two_health_habits", 2, l_health_habits.count)

			l_app.close
		end

feature -- Test routines: Completion and Streaks

	test_complete_habit
			-- Test completing a habit.
		local
			l_app: HABIT_TRACKER_APP
			l_user: HABIT_USER
			l_habit: HABIT
			l_completion: HABIT_COMPLETION
		do
			create l_app.make
			l_user := l_app.create_user ("compuser", "comp@example.com", "UTC")
			l_habit := l_app.create_habit (l_user.id, "Test Habit", "daily")

			l_completion := l_app.complete_habit (l_habit.id, l_user.id)

			assert_false ("is_saved", l_completion.is_new)
			assert_equal ("xp_earned", 10, l_completion.xp_earned)

			-- Check streak updated
			assert_equal ("streak_1", 1, l_app.get_habit_streak (l_habit.id))

			-- Check user XP updated
			assert_true ("user_xp_increased", l_app.user_xp (l_user.id) > 0)

			l_app.close
		end

	test_complete_habit_with_details
			-- Test completing a habit with mood/energy/notes.
		local
			l_app: HABIT_TRACKER_APP
			l_user: HABIT_USER
			l_habit: HABIT
			l_completion: HABIT_COMPLETION
		do
			create l_app.make
			l_user := l_app.create_user ("detailuser", "detail@example.com", "UTC")
			l_habit := l_app.create_habit (l_user.id, "Mood Habit", "daily")

			l_completion := l_app.complete_habit_with_details (l_habit.id, l_user.id, 4, 3, "Felt great!")

			assert_equal ("mood_4", 4, l_completion.mood)
			assert_equal ("energy_3", 3, l_completion.energy)
			assert_strings_equal ("mood_label", "Good", l_completion.mood_label)

			l_app.close
		end

	test_streak_tracking
			-- Test streak tracking over multiple completions.
		local
			l_app: HABIT_TRACKER_APP
			l_user: HABIT_USER
			l_habit: HABIT
			l_ignored: HABIT_COMPLETION
		do
			create l_app.make
			l_user := l_app.create_user ("streakuser", "streak@example.com", "UTC")
			l_habit := l_app.create_habit (l_user.id, "Streak Habit", "daily")

			-- Complete 5 times (simulating consecutive days)
			l_ignored := l_app.complete_habit (l_habit.id, l_user.id)
			l_ignored := l_app.complete_habit (l_habit.id, l_user.id)
			l_ignored := l_app.complete_habit (l_habit.id, l_user.id)
			l_ignored := l_app.complete_habit (l_habit.id, l_user.id)
			l_ignored := l_app.complete_habit (l_habit.id, l_user.id)

			assert_equal ("streak_5", 5, l_app.get_habit_streak (l_habit.id))
			assert_equal ("best_5", 5, l_app.get_best_streak (l_habit.id))

			l_app.close
		end

	test_break_streak
			-- Test breaking a streak.
		local
			l_app: HABIT_TRACKER_APP
			l_user: HABIT_USER
			l_habit: HABIT
			l_ignored: HABIT_COMPLETION
		do
			create l_app.make
			l_user := l_app.create_user ("breakuser", "break@example.com", "UTC")
			l_habit := l_app.create_habit (l_user.id, "Break Habit", "daily")

			-- Build streak
			l_ignored := l_app.complete_habit (l_habit.id, l_user.id)
			l_ignored := l_app.complete_habit (l_habit.id, l_user.id)
			l_ignored := l_app.complete_habit (l_habit.id, l_user.id)

			-- Break it
			l_app.break_habit_streak (l_habit.id)

			assert_equal ("streak_broken", 0, l_app.get_habit_streak (l_habit.id))
			assert_equal ("best_preserved", 3, l_app.get_best_streak (l_habit.id))

			l_app.close
		end

	test_habits_with_active_streaks
			-- Test getting habits with active streaks.
		local
			l_app: HABIT_TRACKER_APP
			l_user: HABIT_USER
			l_h1, l_h2, l_h3: HABIT
			l_ignored: HABIT_COMPLETION
			l_streaking: ARRAYED_LIST [HABIT]
		do
			create l_app.make
			l_user := l_app.create_user ("activeuser", "active@example.com", "UTC")
			l_h1 := l_app.create_habit (l_user.id, "Active 1", "daily")
			l_h2 := l_app.create_habit (l_user.id, "Active 2", "daily")
			l_h3 := l_app.create_habit (l_user.id, "No Streak", "daily")

			-- Give h1 and h2 streaks
			l_ignored := l_app.complete_habit (l_h1.id, l_user.id)
			l_ignored := l_app.complete_habit (l_h2.id, l_user.id)
			l_ignored := l_app.complete_habit (l_h2.id, l_user.id)

			l_streaking := l_app.habits_with_active_streaks (l_user.id)

			assert_equal ("two_with_streaks", 2, l_streaking.count)
			-- Ordered by streak descending
			assert_strings_equal ("h2_first", "Active 2", l_streaking.first.name)

			l_app.close
		end

feature -- Test routines: XP and Leveling

	test_award_xp
			-- Test awarding XP to a user.
		local
			l_app: HABIT_TRACKER_APP
			l_user: HABIT_USER
		do
			create l_app.make
			l_user := l_app.create_user ("xpuser", "xp@example.com", "UTC")

			l_app.award_xp (l_user.id, 50)

			assert_equal ("xp_50", 50, l_app.user_xp (l_user.id))

			l_app.close
		end

	test_level_up
			-- Test leveling up from XP.
		local
			l_app: HABIT_TRACKER_APP
			l_user: HABIT_USER
		do
			create l_app.make
			l_user := l_app.create_user ("leveluser", "level@example.com", "UTC")

			-- Level 1 requires 100 XP to reach level 2
			l_app.award_xp (l_user.id, 100)

			assert_equal ("level_2", 2, l_app.user_level (l_user.id))

			l_app.close
		end

	test_xp_earned_today
			-- Test tracking XP earned today.
		local
			l_app: HABIT_TRACKER_APP
			l_user: HABIT_USER
			l_habit: HABIT
			l_ignored: HABIT_COMPLETION
		do
			create l_app.make
			l_user := l_app.create_user ("todayuser", "today@example.com", "UTC")
			l_habit := l_app.create_habit (l_user.id, "Today Habit", "daily")

			l_ignored := l_app.complete_habit (l_habit.id, l_user.id)
			l_ignored := l_app.complete_habit (l_habit.id, l_user.id)

			assert_true ("xp_earned_today", l_app.xp_earned_today (l_user.id) >= 20)

			l_app.close
		end

feature -- Test routines: Achievements

	test_achievements_seeded
			-- Test that achievements are seeded on startup.
		local
			l_app: HABIT_TRACKER_APP
			l_achievements: ARRAYED_LIST [HABIT_ACHIEVEMENT]
		do
			create l_app.make
			l_achievements := l_app.all_achievements

			assert_true ("has_achievements", l_achievements.count >= 20)

			l_app.close
		end

	test_find_achievement_by_code
			-- Test finding an achievement by code.
		local
			l_app: HABIT_TRACKER_APP
		do
			create l_app.make

			if attached l_app.find_achievement_by_code ("STREAK_7") as l_ach then
				assert_strings_equal ("name", "Week Warrior", l_ach.name)
				assert_equal ("threshold", 7, l_ach.threshold)
			else
				assert_true ("found", False)
			end

			l_app.close
		end

	test_first_completion_achievement
			-- Test earning the first completion achievement.
		local
			l_app: HABIT_TRACKER_APP
			l_user: HABIT_USER
			l_habit: HABIT
			l_ignored: HABIT_COMPLETION
		do
			create l_app.make
			l_user := l_app.create_user ("achuser", "ach@example.com", "UTC")
			l_habit := l_app.create_habit (l_user.id, "First Habit", "daily")

			l_ignored := l_app.complete_habit (l_habit.id, l_user.id)

			assert_true ("first_completion", l_app.has_achievement (l_user.id, "COMPLETE_1"))

			l_app.close
		end

	test_streak_achievement
			-- Test earning streak achievements.
		local
			l_app: HABIT_TRACKER_APP
			l_user: HABIT_USER
			l_habit: HABIT
			l_ignored: HABIT_COMPLETION
			i: INTEGER
		do
			create l_app.make
			l_user := l_app.create_user ("streakach", "streakach@example.com", "UTC")
			l_habit := l_app.create_habit (l_user.id, "Streak Ach", "daily")

			-- Complete 7 times to earn STREAK_3 and STREAK_7
			from i := 1 until i > 7 loop
				l_ignored := l_app.complete_habit (l_habit.id, l_user.id)
				i := i + 1
			end

			assert_true ("streak_3", l_app.has_achievement (l_user.id, "STREAK_3"))
			assert_true ("streak_7", l_app.has_achievement (l_user.id, "STREAK_7"))

			l_app.close
		end

	test_user_achievements
			-- Test retrieving user achievements.
		local
			l_app: HABIT_TRACKER_APP
			l_user: HABIT_USER
			l_habit: HABIT
			l_ignored: HABIT_COMPLETION
			l_user_achs: ARRAYED_LIST [HABIT_USER_ACHIEVEMENT]
		do
			create l_app.make
			l_user := l_app.create_user ("userachs", "userachs@example.com", "UTC")
			l_habit := l_app.create_habit (l_user.id, "Ach Habit", "daily")

			l_ignored := l_app.complete_habit (l_habit.id, l_user.id)

			l_user_achs := l_app.user_achievements (l_user.id)

			assert_true ("has_achievements", l_user_achs.count >= 1)

			l_app.close
		end

	test_achievement_count
			-- Test counting unique achievements.
		local
			l_app: HABIT_TRACKER_APP
			l_user: HABIT_USER
			l_habit: HABIT
			l_ignored: HABIT_COMPLETION
			i: INTEGER
		do
			create l_app.make
			l_user := l_app.create_user ("countach", "countach@example.com", "UTC")
			l_habit := l_app.create_habit (l_user.id, "Count Habit", "daily")

			-- Complete enough to earn multiple achievements
			from i := 1 until i > 5 loop
				l_ignored := l_app.complete_habit (l_habit.id, l_user.id)
				i := i + 1
			end

			assert_true ("multiple_achievements", l_app.achievement_count (l_user.id) >= 2)

			l_app.close
		end

feature -- Test routines: Statistics

	test_completion_count_today
			-- Test counting today's completions.
		local
			l_app: HABIT_TRACKER_APP
			l_user: HABIT_USER
			l_h1, l_h2: HABIT
			l_ignored: HABIT_COMPLETION
		do
			create l_app.make
			l_user := l_app.create_user ("todaycount", "todaycount@example.com", "UTC")
			l_h1 := l_app.create_habit (l_user.id, "Today 1", "daily")
			l_h2 := l_app.create_habit (l_user.id, "Today 2", "daily")

			l_ignored := l_app.complete_habit (l_h1.id, l_user.id)
			l_ignored := l_app.complete_habit (l_h2.id, l_user.id)
			l_ignored := l_app.complete_habit (l_h1.id, l_user.id)

			assert_equal ("three_today", 3, l_app.completion_count_today (l_user.id))

			l_app.close
		end

	test_total_completions
			-- Test total lifetime completions.
		local
			l_app: HABIT_TRACKER_APP
			l_user: HABIT_USER
			l_habit: HABIT
			l_ignored: HABIT_COMPLETION
		do
			create l_app.make
			l_user := l_app.create_user ("totaluser", "total@example.com", "UTC")
			l_habit := l_app.create_habit (l_user.id, "Total Habit", "daily")

			l_ignored := l_app.complete_habit (l_habit.id, l_user.id)
			l_ignored := l_app.complete_habit (l_habit.id, l_user.id)
			l_ignored := l_app.complete_habit (l_habit.id, l_user.id)
			l_ignored := l_app.complete_habit (l_habit.id, l_user.id)
			l_ignored := l_app.complete_habit (l_habit.id, l_user.id)

			assert_equal ("five_total", 5, l_app.total_completions (l_user.id))

			l_app.close
		end

	test_most_consistent_habit
			-- Test finding the most consistent habit.
		local
			l_app: HABIT_TRACKER_APP
			l_user: HABIT_USER
			l_h1, l_h2: HABIT
			l_ignored: HABIT_COMPLETION
		do
			create l_app.make
			l_user := l_app.create_user ("consistent", "consistent@example.com", "UTC")
			l_h1 := l_app.create_habit (l_user.id, "Less Consistent", "daily")
			l_h2 := l_app.create_habit (l_user.id, "Most Consistent", "daily")

			-- h1: 2 completions
			l_ignored := l_app.complete_habit (l_h1.id, l_user.id)
			l_ignored := l_app.complete_habit (l_h1.id, l_user.id)

			-- h2: 5 completions
			l_ignored := l_app.complete_habit (l_h2.id, l_user.id)
			l_ignored := l_app.complete_habit (l_h2.id, l_user.id)
			l_ignored := l_app.complete_habit (l_h2.id, l_user.id)
			l_ignored := l_app.complete_habit (l_h2.id, l_user.id)
			l_ignored := l_app.complete_habit (l_h2.id, l_user.id)

			if attached l_app.most_consistent_habit (l_user.id) as l_best then
				assert_strings_equal ("most_consistent", "Most Consistent", l_best.name)
			else
				assert_true ("found", False)
			end

			l_app.close
		end

	test_longest_active_streak
			-- Test finding the longest active streak.
		local
			l_app: HABIT_TRACKER_APP
			l_user: HABIT_USER
			l_h1, l_h2: HABIT
			l_ignored: HABIT_COMPLETION
			i: INTEGER
		do
			create l_app.make
			l_user := l_app.create_user ("longest", "longest@example.com", "UTC")
			l_h1 := l_app.create_habit (l_user.id, "Short Streak", "daily")
			l_h2 := l_app.create_habit (l_user.id, "Long Streak", "daily")

			-- h1: 3-day streak
			from i := 1 until i > 3 loop
				l_ignored := l_app.complete_habit (l_h1.id, l_user.id)
				i := i + 1
			end

			-- h2: 7-day streak
			from i := 1 until i > 7 loop
				l_ignored := l_app.complete_habit (l_h2.id, l_user.id)
				i := i + 1
			end

			assert_equal ("longest_7", 7, l_app.longest_active_streak (l_user.id))

			l_app.close
		end

feature -- Test routines: Frequency Types

	test_weekly_habit
			-- Test weekly habit frequency type.
		local
			l_app: HABIT_TRACKER_APP
			l_user: HABIT_USER
			l_habit: HABIT
		do
			create l_app.make
			l_user := l_app.create_user ("weeklyuser", "weekly@example.com", "UTC")
			l_habit := l_app.create_habit (l_user.id, "Weekly Task", "weekly")

			assert_true ("is_weekly", l_habit.is_weekly)
			assert_false ("not_daily", l_habit.is_daily)

			l_app.close
		end

	test_weekdays_habit
			-- Test weekdays-only habit.
		local
			l_app: HABIT_TRACKER_APP
			l_user: HABIT_USER
			l_habit: HABIT
		do
			create l_app.make
			l_user := l_app.create_user ("weekdayuser", "weekday@example.com", "UTC")
			l_habit := l_app.create_habit (l_user.id, "Workday Task", "weekdays")

			assert_true ("is_weekdays", l_habit.is_weekdays_only)

			l_app.close
		end

	test_custom_frequency_habit
			-- Test custom frequency with specific days.
		local
			l_app: HABIT_TRACKER_APP
			l_user: HABIT_USER
			l_habit: HABIT
		do
			create l_app.make
			l_user := l_app.create_user ("customuser", "custom@example.com", "UTC")
			l_habit := l_app.create_habit_full (
				l_user.id, 0,
				"MWF Workout", "Monday, Wednesday, Friday",
				"custom", 3,
				"[1,3,5]",  -- Mon, Wed, Fri
				1, 15
			)

			assert_true ("is_custom", l_habit.is_custom_schedule)
			if attached l_habit.frequency_days as l_days then
				assert_strings_equal ("days_json", "[1,3,5]", l_days)
			else
				assert_true ("has_days", False)
			end

			l_app.close
		end

feature -- Test routines: Edge Cases

	test_empty_user_habits
			-- Test getting habits for user with none.
		local
			l_app: HABIT_TRACKER_APP
			l_user: HABIT_USER
			l_habits: ARRAYED_LIST [HABIT]
		do
			create l_app.make
			l_user := l_app.create_user ("emptyuser", "empty@example.com", "UTC")

			l_habits := l_app.user_habits (l_user.id)

			assert_equal ("no_habits", 0, l_habits.count)

			l_app.close
		end

	test_user_with_no_achievements
			-- Test user with no achievements.
		local
			l_app: HABIT_TRACKER_APP
			l_user: HABIT_USER
		do
			create l_app.make
			l_user := l_app.create_user ("noachuser", "noach@example.com", "UTC")

			assert_equal ("no_achievements", 0, l_app.achievement_count (l_user.id))
			assert_false ("no_streak_3", l_app.has_achievement (l_user.id, "STREAK_3"))

			l_app.close
		end

	test_habit_count
			-- Test counting active habits.
		local
			l_app: HABIT_TRACKER_APP
			l_user: HABIT_USER
			l_h1, l_h2, l_h3: HABIT
		do
			create l_app.make
			l_user := l_app.create_user ("countuser", "count@example.com", "UTC")

			assert_equal ("zero_initially", 0, l_app.habit_count (l_user.id))

			l_h1 := l_app.create_habit (l_user.id, "Habit 1", "daily")
			l_h2 := l_app.create_habit (l_user.id, "Habit 2", "daily")
			l_h3 := l_app.create_habit (l_user.id, "Habit 3", "daily")

			assert_equal ("three_habits", 3, l_app.habit_count (l_user.id))

			-- Archive one
			l_app.archive_habit (l_h2.id)

			assert_equal ("two_active", 2, l_app.habit_count (l_user.id))

			l_app.close
		end

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
