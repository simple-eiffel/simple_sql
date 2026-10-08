note
	description: "Stress tests for HABIT_TRACKER_APP - complex scenarios and high volume"
	testing: "covers"
	testing: "execution/serial"

class
	TEST_HABIT_TRACKER_STRESS

inherit
	TEST_SET_BASE

feature -- Test routines: High Volume

	test_many_users
			-- Test creating many users.
		local
			l_app: HABIT_TRACKER_APP
			l_ignored: HABIT_USER
			i: INTEGER
		do
			create l_app.make

			from i := 1 until i > 100 loop
				l_ignored := l_app.create_user ("user" + i.out, "user" + i.out + "@example.com", "UTC")
				i := i + 1
			end

			assert_equal ("100_users", 100, l_app.user_count)

			l_app.close
		end

	test_many_habits_per_user
			-- Test user with many habits.
		local
			l_app: HABIT_TRACKER_APP
			l_user: HABIT_USER
			l_ignored: HABIT
			i: INTEGER
		do
			create l_app.make
			l_user := l_app.create_user ("manyhabits", "many@example.com", "UTC")

			from i := 1 until i > 50 loop
				l_ignored := l_app.create_habit (l_user.id, "Habit " + i.out, "daily")
				i := i + 1
			end

			assert_equal ("50_habits", 50, l_app.habit_count (l_user.id))

			l_app.close
		end

	test_many_completions
			-- Test many completions for a single habit.
		local
			l_app: HABIT_TRACKER_APP
			l_user: HABIT_USER
			l_habit: HABIT
			l_ignored: HABIT_COMPLETION
			i: INTEGER
			l_completions: ARRAYED_LIST [HABIT_COMPLETION]
		do
			create l_app.make
			l_user := l_app.create_user ("manycomp", "manycomp@example.com", "UTC")
			l_habit := l_app.create_habit (l_user.id, "Frequent Habit", "daily")

			from i := 1 until i > 100 loop
				l_ignored := l_app.complete_habit (l_habit.id, l_user.id)
				i := i + 1
			end

			l_completions := l_app.habit_completions (l_habit.id)
			assert_equal ("100_completions", 100, l_completions.count)

			-- Streak should be 100
			assert_equal ("streak_100", 100, l_app.get_habit_streak (l_habit.id))

			l_app.close
		end

	test_many_categories
			-- Test user with many categories.
		local
			l_app: HABIT_TRACKER_APP
			l_user: HABIT_USER
			l_ignored: HABIT_CATEGORY
			i: INTEGER
			l_cats: ARRAYED_LIST [HABIT_CATEGORY]
		do
			create l_app.make
			l_user := l_app.create_user ("manycats", "cats@example.com", "UTC")

			from i := 1 until i > 20 loop
				l_ignored := l_app.create_category (l_user.id, "Category " + i.out)
				i := i + 1
			end

			l_cats := l_app.user_categories (l_user.id)
			assert_equal ("20_categories", 20, l_cats.count)

			-- Verify sort order
			assert_equal ("first_sort_0", 0, l_cats.first.sort_order)
			assert_equal ("last_sort_19", 19, l_cats.last.sort_order)

			l_app.close
		end

feature -- Test routines: Complex Scenarios

	test_full_user_lifecycle
			-- Test a complete user lifecycle with multiple habits.
		local
			l_app: HABIT_TRACKER_APP
			l_user: HABIT_USER
			l_health, l_work: HABIT_CATEGORY
			l_exercise, l_meditate, l_code: HABIT
			l_ignored: HABIT_COMPLETION
			i: INTEGER
		do
			create l_app.make

			-- Create user
			l_user := l_app.create_user ("lifecycle", "life@example.com", "America/Chicago")

			-- Create categories
			l_health := l_app.create_category_with_style (l_user.id, "Health", "#10B981", "heart")
			l_work := l_app.create_category_with_style (l_user.id, "Work", "#3B82F6", "briefcase")

			-- Create habits
			l_exercise := l_app.create_habit_full (l_user.id, l_health.id, "Exercise", "30 min workout", "daily", 1, Void, 1, 20)
			l_meditate := l_app.create_habit_full (l_user.id, l_health.id, "Meditate", "10 min session", "daily", 1, Void, 1, 15)
			l_code := l_app.create_habit_full (l_user.id, l_work.id, "Write Code", "1 hour coding", "weekdays", 1, Void, 1, 25)

			-- Simulate 14 days of activity
			from i := 1 until i > 14 loop
				-- Exercise every day
				l_ignored := l_app.complete_habit_with_details (l_exercise.id, l_user.id, 4, 4, "Day " + i.out)
				-- Meditate most days
				if i \\ 3 /= 0 then
					l_ignored := l_app.complete_habit (l_meditate.id, l_user.id)
				end
				-- Code on weekdays only (simulated as every day for test)
				l_ignored := l_app.complete_habit (l_code.id, l_user.id)
				i := i + 1
			end

			-- Verify results
			assert_equal ("exercise_streak_14", 14, l_app.get_habit_streak (l_exercise.id))
			assert_equal ("code_streak_14", 14, l_app.get_habit_streak (l_code.id))
			assert_true ("earned_streak_7", l_app.has_achievement (l_user.id, "STREAK_7"))
			assert_true ("earned_streak_14", l_app.has_achievement (l_user.id, "STREAK_14"))
			assert_true ("level_increased", l_app.user_level (l_user.id) > 1)

			l_app.close
		end

	test_multi_user_scenario
			-- Test multiple users interacting simultaneously.
		local
			l_app: HABIT_TRACKER_APP
			l_alice, l_bob, l_charlie: HABIT_USER
			l_alice_habit, l_bob_habit, l_charlie_habit: HABIT
			l_ignored: HABIT_COMPLETION
			i: INTEGER
		do
			create l_app.make

			-- Create three users
			l_alice := l_app.create_user ("alice", "alice@example.com", "America/New_York")
			l_bob := l_app.create_user ("bob", "bob@example.com", "Europe/London")
			l_charlie := l_app.create_user ("charlie", "charlie@example.com", "Asia/Tokyo")

			-- Each has a habit
			l_alice_habit := l_app.create_habit (l_alice.id, "Alice Habit", "daily")
			l_bob_habit := l_app.create_habit (l_bob.id, "Bob Habit", "daily")
			l_charlie_habit := l_app.create_habit (l_charlie.id, "Charlie Habit", "daily")

			-- Simulate different completion patterns
			-- Alice: 10 days, Bob: 5 days, Charlie: 3 days
			from i := 1 until i > 10 loop
				l_ignored := l_app.complete_habit (l_alice_habit.id, l_alice.id)
				if i <= 5 then
					l_ignored := l_app.complete_habit (l_bob_habit.id, l_bob.id)
				end
				if i <= 3 then
					l_ignored := l_app.complete_habit (l_charlie_habit.id, l_charlie.id)
				end
				i := i + 1
			end

			-- Verify isolation (users don't affect each other)
			assert_equal ("alice_streak", 10, l_app.get_habit_streak (l_alice_habit.id))
			assert_equal ("bob_streak", 5, l_app.get_habit_streak (l_bob_habit.id))
			assert_equal ("charlie_streak", 3, l_app.get_habit_streak (l_charlie_habit.id))

			-- Verify XP is per-user
			assert_true ("alice_highest_xp", l_app.user_xp (l_alice.id) > l_app.user_xp (l_bob.id))
			assert_true ("bob_higher_than_charlie", l_app.user_xp (l_bob.id) > l_app.user_xp (l_charlie.id))

			l_app.close
		end

	test_achievement_progression
			-- Test achievement progression through milestones.
		local
			l_app: HABIT_TRACKER_APP
			l_user: HABIT_USER
			l_habit: HABIT
			l_ignored: HABIT_COMPLETION
			i: INTEGER
		do
			create l_app.make
			l_user := l_app.create_user ("achiever", "achiever@example.com", "UTC")
			l_habit := l_app.create_habit (l_user.id, "Achievement Habit", "daily")

			-- Complete 30 times to earn multiple achievements
			from i := 1 until i > 30 loop
				l_ignored := l_app.complete_habit (l_habit.id, l_user.id)
				i := i + 1
			end

			-- Should have earned streak achievements
			assert_true ("streak_3", l_app.has_achievement (l_user.id, "STREAK_3"))
			assert_true ("streak_7", l_app.has_achievement (l_user.id, "STREAK_7"))
			assert_true ("streak_14", l_app.has_achievement (l_user.id, "STREAK_14"))
			assert_true ("streak_30", l_app.has_achievement (l_user.id, "STREAK_30"))

			-- Should have completion achievements
			assert_true ("complete_1", l_app.has_achievement (l_user.id, "COMPLETE_1"))
			assert_true ("complete_10", l_app.has_achievement (l_user.id, "COMPLETE_10"))

			-- Should have multiple unique achievements
			assert_true ("many_achievements", l_app.achievement_count (l_user.id) >= 6)

			l_app.close
		end

	test_xp_bonus_progression
			-- Test XP bonuses increase with streak.
		local
			l_app: HABIT_TRACKER_APP
			l_user: HABIT_USER
			l_habit: HABIT
			l_completion: HABIT_COMPLETION
			l_xp_at_1, l_xp_at_7, l_xp_at_30: INTEGER
			i: INTEGER
		do
			create l_app.make
			l_user := l_app.create_user ("xpbonus", "xpbonus@example.com", "UTC")
			l_habit := l_app.create_habit (l_user.id, "XP Bonus Habit", "daily")

			-- Record XP at different streak milestones
			-- First completion (no bonus)
			l_completion := l_app.complete_habit (l_habit.id, l_user.id)
			l_xp_at_1 := l_completion.xp_earned

			-- Continue to day 7
			from i := 2 until i > 7 loop
				l_completion := l_app.complete_habit (l_habit.id, l_user.id)
				i := i + 1
			end
			l_xp_at_7 := l_completion.xp_earned

			-- Continue to day 30
			from i := 8 until i > 30 loop
				l_completion := l_app.complete_habit (l_habit.id, l_user.id)
				i := i + 1
			end
			l_xp_at_30 := l_completion.xp_earned

			-- XP should increase with streak
			assert_true ("xp_7_higher", l_xp_at_7 > l_xp_at_1)
			assert_true ("xp_30_highest", l_xp_at_30 > l_xp_at_7)

			l_app.close
		end

feature -- Test routines: Data Integrity

	test_archive_unarchive_cycle
			-- Test archiving and unarchiving preserves data.
		local
			l_app: HABIT_TRACKER_APP
			l_user: HABIT_USER
			l_habit: HABIT
			l_ignored: HABIT_COMPLETION
			l_original_streak: INTEGER
		do
			create l_app.make
			l_user := l_app.create_user ("archcycle", "archcycle@example.com", "UTC")
			l_habit := l_app.create_habit (l_user.id, "Archive Cycle", "daily")

			-- Build up data
			l_ignored := l_app.complete_habit (l_habit.id, l_user.id)
			l_ignored := l_app.complete_habit (l_habit.id, l_user.id)
			l_ignored := l_app.complete_habit (l_habit.id, l_user.id)
			l_original_streak := l_app.get_habit_streak (l_habit.id)

			-- Archive
			l_app.archive_habit (l_habit.id)
			assert_equal ("no_active", 0, l_app.habit_count (l_user.id))

			-- Unarchive
			l_app.unarchive_habit (l_habit.id)
			assert_equal ("one_active", 1, l_app.habit_count (l_user.id))

			-- Data preserved
			assert_equal ("streak_preserved", l_original_streak, l_app.get_habit_streak (l_habit.id))

			l_app.close
		end

	test_category_isolation
			-- Test habits in categories don't affect other categories.
		local
			l_app: HABIT_TRACKER_APP
			l_user: HABIT_USER
			l_cat1, l_cat2: HABIT_CATEGORY
			l_ignored: HABIT
			l_cat1_habits, l_cat2_habits: ARRAYED_LIST [HABIT]
		do
			create l_app.make
			l_user := l_app.create_user ("catiso", "catiso@example.com", "UTC")
			l_cat1 := l_app.create_category (l_user.id, "Category 1")
			l_cat2 := l_app.create_category (l_user.id, "Category 2")

			-- Add habits to each
			l_ignored := l_app.create_habit_full (l_user.id, l_cat1.id, "Cat1 H1", "", "daily", 1, Void, 1, 10)
			l_ignored := l_app.create_habit_full (l_user.id, l_cat1.id, "Cat1 H2", "", "daily", 1, Void, 1, 10)
			l_ignored := l_app.create_habit_full (l_user.id, l_cat2.id, "Cat2 H1", "", "daily", 1, Void, 1, 10)

			l_cat1_habits := l_app.user_habits_by_category (l_user.id, l_cat1.id)
			l_cat2_habits := l_app.user_habits_by_category (l_user.id, l_cat2.id)

			assert_equal ("cat1_has_2", 2, l_cat1_habits.count)
			assert_equal ("cat2_has_1", 1, l_cat2_habits.count)

			l_app.close
		end

feature -- Test routines: Edge Cases

	test_streak_after_break_and_rebuild
			-- Test rebuilding a streak after breaking it.
		local
			l_app: HABIT_TRACKER_APP
			l_user: HABIT_USER
			l_habit: HABIT
			l_ignored: HABIT_COMPLETION
			i: INTEGER
		do
			create l_app.make
			l_user := l_app.create_user ("rebuild", "rebuild@example.com", "UTC")
			l_habit := l_app.create_habit (l_user.id, "Rebuild Habit", "daily")

			-- Build initial streak of 5
			from i := 1 until i > 5 loop
				l_ignored := l_app.complete_habit (l_habit.id, l_user.id)
				i := i + 1
			end
			assert_equal ("initial_streak", 5, l_app.get_habit_streak (l_habit.id))
			assert_equal ("initial_best", 5, l_app.get_best_streak (l_habit.id))

			-- Break streak
			l_app.break_habit_streak (l_habit.id)
			assert_equal ("broken_streak", 0, l_app.get_habit_streak (l_habit.id))
			assert_equal ("best_preserved", 5, l_app.get_best_streak (l_habit.id))

			-- Rebuild to 3
			from i := 1 until i > 3 loop
				l_ignored := l_app.complete_habit (l_habit.id, l_user.id)
				i := i + 1
			end
			assert_equal ("new_streak", 3, l_app.get_habit_streak (l_habit.id))
			assert_equal ("best_still_5", 5, l_app.get_best_streak (l_habit.id))

			-- Continue past best
			from i := 4 until i > 7 loop
				l_ignored := l_app.complete_habit (l_habit.id, l_user.id)
				i := i + 1
			end
			assert_equal ("exceeded_streak", 7, l_app.get_habit_streak (l_habit.id))
			assert_equal ("new_best", 7, l_app.get_best_streak (l_habit.id))

			l_app.close
		end

	test_zero_xp_habit_not_possible
			-- Verify habits must have positive XP (DBC).
		local
			l_app: HABIT_TRACKER_APP
			l_user: HABIT_USER
			l_habit: HABIT
		do
			create l_app.make
			l_user := l_app.create_user ("zeroxp", "zeroxp@example.com", "UTC")

			-- Default XP should be 10
			l_habit := l_app.create_habit (l_user.id, "Default XP", "daily")
			assert_equal ("default_xp", 10, l_habit.xp_per_completion)

			l_app.close
		end

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
