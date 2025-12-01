note
	description: "A single completion record for a habit with optional mood/energy tracking"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	HABIT_COMPLETION

create
	make,
	make_new

feature {NONE} -- Initialization

	make (a_id: INTEGER_64; a_habit_id: INTEGER_64; a_user_id: INTEGER_64;
			a_completed_at: READABLE_STRING_8; a_completion_count: INTEGER;
			a_mood: detachable INTEGER_REF; a_energy: detachable INTEGER_REF;
			a_notes: detachable READABLE_STRING_8;
			a_xp_earned: INTEGER)
			-- Initialize from database row.
		require
			valid_habit: a_habit_id > 0
			valid_user: a_user_id > 0
			valid_count: a_completion_count >= 1
			valid_mood: attached a_mood implies (a_mood.item >= 1 and a_mood.item <= 5)
			valid_energy: attached a_energy implies (a_energy.item >= 1 and a_energy.item <= 5)
			xp_non_negative: a_xp_earned >= 0
		do
			id := a_id
			habit_id := a_habit_id
			user_id := a_user_id
			completed_at := a_completed_at.to_string_8
			completion_count := a_completion_count
			if attached a_mood then
				mood := a_mood.item
			end
			if attached a_energy then
				energy := a_energy.item
			end
			if attached a_notes as n then
				notes := n.to_string_8
			end
			xp_earned := a_xp_earned
		ensure
			id_set: id = a_id
			habit_id_set: habit_id = a_habit_id
			user_id_set: user_id = a_user_id
		end

	make_new (a_habit_id: INTEGER_64; a_user_id: INTEGER_64; a_xp_earned: INTEGER)
			-- Create a new completion (not yet saved).
		require
			valid_habit: a_habit_id > 0
			valid_user: a_user_id > 0
			xp_non_negative: a_xp_earned >= 0
		do
			id := 0
			habit_id := a_habit_id
			user_id := a_user_id
			completed_at := ""
			completion_count := 1
			mood := 0
			energy := 0
			xp_earned := a_xp_earned
		ensure
			id_zero: id = 0
			habit_id_set: habit_id = a_habit_id
			user_id_set: user_id = a_user_id
			single_completion: completion_count = 1
		end

feature -- Access

	id: INTEGER_64
			-- Unique identifier (0 if not yet saved).

	habit_id: INTEGER_64
			-- Habit this completion is for.

	user_id: INTEGER_64
			-- User who completed the habit.

	completed_at: STRING_8
			-- Timestamp when completed (ISO 8601).

	completion_count: INTEGER
			-- How many times completed in this session (for target_count habits).

	mood: INTEGER
			-- Optional mood rating (1-5, 0 if not set).
			-- 1=Bad, 2=Poor, 3=OK, 4=Good, 5=Great

	energy: INTEGER
			-- Optional energy level (1-5, 0 if not set).
			-- 1=Exhausted, 2=Tired, 3=Normal, 4=Energized, 5=Supercharged

	notes: detachable STRING_8
			-- Optional notes about this completion.

	xp_earned: INTEGER
			-- XP earned for this completion (base + streak bonus).

feature -- Status

	is_new: BOOLEAN
			-- Has this completion not yet been saved to database?
		do
			Result := id = 0
		end

	has_mood: BOOLEAN
			-- Was mood recorded?
		do
			Result := mood > 0
		end

	has_energy: BOOLEAN
			-- Was energy recorded?
		do
			Result := energy > 0
		end

	has_notes: BOOLEAN
			-- Were notes recorded?
		do
			Result := attached notes as n and then not n.is_empty
		end

	mood_label: STRING_8
			-- Human-readable mood description.
		do
			inspect mood
			when 1 then Result := "Bad"
			when 2 then Result := "Poor"
			when 3 then Result := "OK"
			when 4 then Result := "Good"
			when 5 then Result := "Great"
			else
				Result := "Not recorded"
			end
		end

	energy_label: STRING_8
			-- Human-readable energy description.
		do
			inspect energy
			when 1 then Result := "Exhausted"
			when 2 then Result := "Tired"
			when 3 then Result := "Normal"
			when 4 then Result := "Energized"
			when 5 then Result := "Supercharged"
			else
				Result := "Not recorded"
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

	set_completion_count (a_count: INTEGER)
			-- Set completion count.
		require
			positive: a_count >= 1
		do
			completion_count := a_count
		ensure
			count_set: completion_count = a_count
		end

	set_mood (a_mood: INTEGER)
			-- Set mood rating.
		require
			valid_range: a_mood >= 0 and a_mood <= 5
		do
			mood := a_mood
		ensure
			mood_set: mood = a_mood
		end

	set_energy (a_energy: INTEGER)
			-- Set energy level.
		require
			valid_range: a_energy >= 0 and a_energy <= 5
		do
			energy := a_energy
		ensure
			energy_set: energy = a_energy
		end

	set_notes (a_notes: detachable READABLE_STRING_8)
			-- Set completion notes.
		do
			if attached a_notes as n then
				notes := n.to_string_8
			else
				notes := Void
			end
		end

	set_completed_at (a_timestamp: READABLE_STRING_8)
			-- Set completion timestamp.
		require
			not_empty: not a_timestamp.is_empty
		do
			completed_at := a_timestamp.to_string_8
		end

invariant
	valid_habit_id: habit_id > 0
	valid_user_id: user_id > 0
	valid_completion_count: completion_count >= 1
	mood_in_range: mood >= 0 and mood <= 5
	energy_in_range: energy >= 0 and energy <= 5
	xp_non_negative: xp_earned >= 0
	id_non_negative: id >= 0

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
