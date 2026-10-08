note
	description: "Test application root class for habit_tracker tests: runs every test through EQA_TEST_EVALUATOR"
	date: "$Date$"
	revision: "$Revision$"

class
	APPLICATION

create
	make

feature -- Initialization

	make
			-- Run every habit_tracker test and print a summary.
		do
			run_test_habit_tracker_app
			run_test_habit_tracker_stress
			print ("%N========================%N")
			print ("Results: " + passed.out + " passed, " + failed.out + " failed%N")
		end

feature {NONE} -- Runners

	run_test_habit_tracker_app
		local
			l_eval: EQA_TEST_EVALUATOR [TEST_HABIT_TRACKER_APP]
		do
			create l_eval
			report ("TEST_HABIT_TRACKER_APP.test_create_user", l_eval.execute (agent {TEST_HABIT_TRACKER_APP}.test_create_user))
			report ("TEST_HABIT_TRACKER_APP.test_find_user_by_username", l_eval.execute (agent {TEST_HABIT_TRACKER_APP}.test_find_user_by_username))
			report ("TEST_HABIT_TRACKER_APP.test_find_user_by_email", l_eval.execute (agent {TEST_HABIT_TRACKER_APP}.test_find_user_by_email))
			report ("TEST_HABIT_TRACKER_APP.test_all_users", l_eval.execute (agent {TEST_HABIT_TRACKER_APP}.test_all_users))
			report ("TEST_HABIT_TRACKER_APP.test_create_category", l_eval.execute (agent {TEST_HABIT_TRACKER_APP}.test_create_category))
			report ("TEST_HABIT_TRACKER_APP.test_create_category_with_style", l_eval.execute (agent {TEST_HABIT_TRACKER_APP}.test_create_category_with_style))
			report ("TEST_HABIT_TRACKER_APP.test_seed_default_categories", l_eval.execute (agent {TEST_HABIT_TRACKER_APP}.test_seed_default_categories))
			report ("TEST_HABIT_TRACKER_APP.test_create_habit", l_eval.execute (agent {TEST_HABIT_TRACKER_APP}.test_create_habit))
			report ("TEST_HABIT_TRACKER_APP.test_create_habit_full", l_eval.execute (agent {TEST_HABIT_TRACKER_APP}.test_create_habit_full))
			report ("TEST_HABIT_TRACKER_APP.test_user_habits", l_eval.execute (agent {TEST_HABIT_TRACKER_APP}.test_user_habits))
			report ("TEST_HABIT_TRACKER_APP.test_archive_habit", l_eval.execute (agent {TEST_HABIT_TRACKER_APP}.test_archive_habit))
			report ("TEST_HABIT_TRACKER_APP.test_habits_by_category", l_eval.execute (agent {TEST_HABIT_TRACKER_APP}.test_habits_by_category))
			report ("TEST_HABIT_TRACKER_APP.test_complete_habit", l_eval.execute (agent {TEST_HABIT_TRACKER_APP}.test_complete_habit))
			report ("TEST_HABIT_TRACKER_APP.test_complete_habit_with_details", l_eval.execute (agent {TEST_HABIT_TRACKER_APP}.test_complete_habit_with_details))
			report ("TEST_HABIT_TRACKER_APP.test_streak_tracking", l_eval.execute (agent {TEST_HABIT_TRACKER_APP}.test_streak_tracking))
			report ("TEST_HABIT_TRACKER_APP.test_break_streak", l_eval.execute (agent {TEST_HABIT_TRACKER_APP}.test_break_streak))
			report ("TEST_HABIT_TRACKER_APP.test_habits_with_active_streaks", l_eval.execute (agent {TEST_HABIT_TRACKER_APP}.test_habits_with_active_streaks))
			report ("TEST_HABIT_TRACKER_APP.test_award_xp", l_eval.execute (agent {TEST_HABIT_TRACKER_APP}.test_award_xp))
			report ("TEST_HABIT_TRACKER_APP.test_level_up", l_eval.execute (agent {TEST_HABIT_TRACKER_APP}.test_level_up))
			report ("TEST_HABIT_TRACKER_APP.test_xp_earned_today", l_eval.execute (agent {TEST_HABIT_TRACKER_APP}.test_xp_earned_today))
			report ("TEST_HABIT_TRACKER_APP.test_achievements_seeded", l_eval.execute (agent {TEST_HABIT_TRACKER_APP}.test_achievements_seeded))
			report ("TEST_HABIT_TRACKER_APP.test_find_achievement_by_code", l_eval.execute (agent {TEST_HABIT_TRACKER_APP}.test_find_achievement_by_code))
			report ("TEST_HABIT_TRACKER_APP.test_first_completion_achievement", l_eval.execute (agent {TEST_HABIT_TRACKER_APP}.test_first_completion_achievement))
			report ("TEST_HABIT_TRACKER_APP.test_streak_achievement", l_eval.execute (agent {TEST_HABIT_TRACKER_APP}.test_streak_achievement))
			report ("TEST_HABIT_TRACKER_APP.test_user_achievements", l_eval.execute (agent {TEST_HABIT_TRACKER_APP}.test_user_achievements))
			report ("TEST_HABIT_TRACKER_APP.test_achievement_count", l_eval.execute (agent {TEST_HABIT_TRACKER_APP}.test_achievement_count))
			report ("TEST_HABIT_TRACKER_APP.test_completion_count_today", l_eval.execute (agent {TEST_HABIT_TRACKER_APP}.test_completion_count_today))
			report ("TEST_HABIT_TRACKER_APP.test_total_completions", l_eval.execute (agent {TEST_HABIT_TRACKER_APP}.test_total_completions))
			report ("TEST_HABIT_TRACKER_APP.test_most_consistent_habit", l_eval.execute (agent {TEST_HABIT_TRACKER_APP}.test_most_consistent_habit))
			report ("TEST_HABIT_TRACKER_APP.test_longest_active_streak", l_eval.execute (agent {TEST_HABIT_TRACKER_APP}.test_longest_active_streak))
			report ("TEST_HABIT_TRACKER_APP.test_weekly_habit", l_eval.execute (agent {TEST_HABIT_TRACKER_APP}.test_weekly_habit))
			report ("TEST_HABIT_TRACKER_APP.test_weekdays_habit", l_eval.execute (agent {TEST_HABIT_TRACKER_APP}.test_weekdays_habit))
			report ("TEST_HABIT_TRACKER_APP.test_custom_frequency_habit", l_eval.execute (agent {TEST_HABIT_TRACKER_APP}.test_custom_frequency_habit))
			report ("TEST_HABIT_TRACKER_APP.test_empty_user_habits", l_eval.execute (agent {TEST_HABIT_TRACKER_APP}.test_empty_user_habits))
			report ("TEST_HABIT_TRACKER_APP.test_user_with_no_achievements", l_eval.execute (agent {TEST_HABIT_TRACKER_APP}.test_user_with_no_achievements))
			report ("TEST_HABIT_TRACKER_APP.test_habit_count", l_eval.execute (agent {TEST_HABIT_TRACKER_APP}.test_habit_count))
		end

	run_test_habit_tracker_stress
		local
			l_eval: EQA_TEST_EVALUATOR [TEST_HABIT_TRACKER_STRESS]
		do
			create l_eval
			report ("TEST_HABIT_TRACKER_STRESS.test_many_users", l_eval.execute (agent {TEST_HABIT_TRACKER_STRESS}.test_many_users))
			report ("TEST_HABIT_TRACKER_STRESS.test_many_habits_per_user", l_eval.execute (agent {TEST_HABIT_TRACKER_STRESS}.test_many_habits_per_user))
			report ("TEST_HABIT_TRACKER_STRESS.test_many_completions", l_eval.execute (agent {TEST_HABIT_TRACKER_STRESS}.test_many_completions))
			report ("TEST_HABIT_TRACKER_STRESS.test_many_categories", l_eval.execute (agent {TEST_HABIT_TRACKER_STRESS}.test_many_categories))
			report ("TEST_HABIT_TRACKER_STRESS.test_full_user_lifecycle", l_eval.execute (agent {TEST_HABIT_TRACKER_STRESS}.test_full_user_lifecycle))
			report ("TEST_HABIT_TRACKER_STRESS.test_multi_user_scenario", l_eval.execute (agent {TEST_HABIT_TRACKER_STRESS}.test_multi_user_scenario))
			report ("TEST_HABIT_TRACKER_STRESS.test_achievement_progression", l_eval.execute (agent {TEST_HABIT_TRACKER_STRESS}.test_achievement_progression))
			report ("TEST_HABIT_TRACKER_STRESS.test_xp_bonus_progression", l_eval.execute (agent {TEST_HABIT_TRACKER_STRESS}.test_xp_bonus_progression))
			report ("TEST_HABIT_TRACKER_STRESS.test_archive_unarchive_cycle", l_eval.execute (agent {TEST_HABIT_TRACKER_STRESS}.test_archive_unarchive_cycle))
			report ("TEST_HABIT_TRACKER_STRESS.test_category_isolation", l_eval.execute (agent {TEST_HABIT_TRACKER_STRESS}.test_category_isolation))
			report ("TEST_HABIT_TRACKER_STRESS.test_streak_after_break_and_rebuild", l_eval.execute (agent {TEST_HABIT_TRACKER_STRESS}.test_streak_after_break_and_rebuild))
			report ("TEST_HABIT_TRACKER_STRESS.test_zero_xp_habit_not_possible", l_eval.execute (agent {TEST_HABIT_TRACKER_STRESS}.test_zero_xp_habit_not_possible))
		end

feature {NONE} -- Implementation

	passed, failed: INTEGER

	report (a_name: STRING_8; a_result: EQA_PARTIAL_RESULT)
			-- Count and print the outcome of test `a_name'.
		do
			if a_result.is_pass then
				passed := passed + 1
				print ("  PASS: " + a_name + "%N")
			else
				failed := failed + 1
				print ("  FAIL: " + a_name)
				if attached {EQA_RESULT} a_result as l_full and then attached l_full.test_response.exception as l_ex then
					print (" [" + {UTF_CONVERTER}.string_32_to_utf_8_string_8 (l_ex.tag_name) + "]")
				end
				print ("%N")
			end
		end

end
