note
	description: "An activity/task in a CPM (Critical Path Method) project network"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	CPM_ACTIVITY

inherit
	ANY
		redefine
			out
		end

create
	make,
	make_new

feature {NONE} -- Initialization

	make (a_id: INTEGER_64; a_code: READABLE_STRING_8; a_name: READABLE_STRING_8;
			a_description: detachable READABLE_STRING_8; a_duration: INTEGER;
			a_early_start, a_early_finish, a_late_start, a_late_finish, a_float: INTEGER;
			a_is_critical: BOOLEAN; a_project_id: INTEGER_64)
			-- Initialize from database row.
		require
			code_not_empty: not a_code.is_empty
			name_not_empty: not a_name.is_empty
			duration_non_negative: a_duration >= 0
		do
			id := a_id
			code := a_code.to_string_8
			name := a_name.to_string_8
			if attached a_description as al_desc then
				description := al_desc.to_string_8
			end
			duration := a_duration
			early_start := a_early_start
			early_finish := a_early_finish
			late_start := a_late_start
			late_finish := a_late_finish
			float := a_float
			is_critical := a_is_critical
			project_id := a_project_id
		ensure
			id_set: id = a_id
			code_set: code.same_string (a_code)
			name_set: name.same_string (a_name)
			duration_set: duration = a_duration
			project_id_set: project_id = a_project_id
		end

	make_new (a_code: READABLE_STRING_8; a_name: READABLE_STRING_8; a_duration: INTEGER; a_project_id: INTEGER_64)
			-- Create a new activity (not yet saved to database).
		require
			code_not_empty: not a_code.is_empty
			name_not_empty: not a_name.is_empty
			duration_non_negative: a_duration >= 0
			valid_project: a_project_id > 0
		do
			id := 0
			code := a_code.to_string_8
			name := a_name.to_string_8
			duration := a_duration
			project_id := a_project_id
			-- Schedule values default to 0 until calculated
			early_start := 0
			early_finish := 0
			late_start := 0
			late_finish := 0
			float := 0
			is_critical := False
		ensure
			id_zero: id = 0
			code_set: code.same_string (a_code)
			name_set: name.same_string (a_name)
			duration_set: duration = a_duration
			project_id_set: project_id = a_project_id
			not_critical: not is_critical
		end

feature -- Access

	id: INTEGER_64
			-- Unique identifier (0 if not yet saved).

	code: STRING_8
			-- Short activity code (e.g., "A", "B", "FOUND-01").

	name: STRING_8
			-- Activity name/title.

	description: detachable STRING_8
			-- Optional detailed description.

	duration: INTEGER
			-- Duration in days.

	early_start: INTEGER
			-- Earliest start time (days from project start).

	early_finish: INTEGER
			-- Earliest finish time (ES + duration).

	late_start: INTEGER
			-- Latest start time without delaying project.

	late_finish: INTEGER
			-- Latest finish time without delaying project.

	float: INTEGER
			-- Total float (slack) = LS - ES or LF - EF.

	is_critical: BOOLEAN
			-- Is this activity on the critical path? (float = 0)

	project_id: INTEGER_64
			-- Foreign key to project.

feature -- Status

	is_new: BOOLEAN
			-- Has this item not yet been saved to database?
		do
			Result := id = 0
		end

	is_milestone: BOOLEAN
			-- Is this a milestone (zero duration)?
		do
			Result := duration = 0
		end

feature -- Modification

	set_code (a_code: READABLE_STRING_8)
			-- Update the code.
		require
			code_not_empty: not a_code.is_empty
		do
			code := a_code.to_string_8
		ensure
			code_set: code.same_string (a_code)
		end

	set_name (a_name: READABLE_STRING_8)
			-- Update the name.
		require
			name_not_empty: not a_name.is_empty
		do
			name := a_name.to_string_8
		ensure
			name_set: name.same_string (a_name)
		end

	set_description (a_description: detachable READABLE_STRING_8)
			-- Update the description.
		do
			if attached a_description as al_desc then
				description := al_desc.to_string_8
			else
				description := Void
			end
		end

	set_duration (a_duration: INTEGER)
			-- Update the duration.
		require
			duration_non_negative: a_duration >= 0
		do
			duration := a_duration
		ensure
			duration_set: duration = a_duration
		end

	set_schedule (a_es, a_ef, a_ls, a_lf, a_float: INTEGER; a_critical: BOOLEAN)
			-- Set calculated schedule values.
		require
			valid_early: a_ef >= a_es
			valid_late: a_lf >= a_ls
			valid_float: a_float >= 0
			critical_means_zero_float: a_critical implies a_float = 0
		do
			early_start := a_es
			early_finish := a_ef
			late_start := a_ls
			late_finish := a_lf
			float := a_float
			is_critical := a_critical
		ensure
			early_start_set: early_start = a_es
			early_finish_set: early_finish = a_ef
			late_start_set: late_start = a_ls
			late_finish_set: late_finish = a_lf
			float_set: float = a_float
			is_critical_set: is_critical = a_critical
		end

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

feature -- Output

	out: STRING_8
			-- String representation.
		do
			create Result.make (100)
			Result.append (code)
			Result.append (": ")
			Result.append (name)
			Result.append (" (")
			Result.append_integer (duration)
			Result.append ("d)")
			if is_critical then
				Result.append (" [CRITICAL]")
			else
				Result.append (" [Float: ")
				Result.append_integer (float)
				Result.append ("d]")
			end
		end

invariant
	code_not_empty: not code.is_empty
	name_not_empty: not name.is_empty
	duration_non_negative: duration >= 0
	id_non_negative: id >= 0
	float_non_negative: float >= 0
	critical_consistency: is_critical implies float = 0

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
