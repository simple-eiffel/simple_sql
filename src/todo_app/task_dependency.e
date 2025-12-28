note
	description: "[
		TASK_DEPENDENCY - Represents a dependency between two tasks.

		Supports CPM-style (Critical Path Method) task relationships:
		- Finish-to-Start: Predecessor must finish before successor starts (most common)
		- Start-to-Start: Both tasks start together
		- Finish-to-Finish: Both tasks finish together
		- Start-to-Finish: Predecessor must start before successor can finish (rare)
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TASK_DEPENDENCY

create
	make,
	make_new

feature {NONE} -- Initialization

	make (a_id: INTEGER_64; a_predecessor_id, a_successor_id: INTEGER_64;
			a_dependency_type: READABLE_STRING_8)
			-- Initialize from database row.
		require
			valid_predecessor: a_predecessor_id > 0
			valid_successor: a_successor_id > 0
			not_self_reference: a_predecessor_id /= a_successor_id
			valid_type: is_valid_dependency_type (a_dependency_type)
		do
			id := a_id
			predecessor_id := a_predecessor_id
			successor_id := a_successor_id
			dependency_type := a_dependency_type.twin
		ensure
			id_set: id = a_id
			predecessor_set: predecessor_id = a_predecessor_id
			successor_set: successor_id = a_successor_id
			type_set: dependency_type.same_string (a_dependency_type)
		end

	make_new (a_predecessor_id, a_successor_id: INTEGER_64)
			-- Create a new finish-to-start dependency (default, most common).
		require
			valid_predecessor: a_predecessor_id > 0
			valid_successor: a_successor_id > 0
			not_self_reference: a_predecessor_id /= a_successor_id
		do
			id := 0
			predecessor_id := a_predecessor_id
			successor_id := a_successor_id
			dependency_type := Type_finish_to_start
		ensure
			id_zero: id = 0
			predecessor_set: predecessor_id = a_predecessor_id
			successor_set: successor_id = a_successor_id
			default_type: dependency_type.same_string (Type_finish_to_start)
		end

feature -- Access

	id: INTEGER_64
			-- Unique identifier (0 if not yet saved).

	predecessor_id: INTEGER_64
			-- ID of the predecessor task (the one that must happen first).

	successor_id: INTEGER_64
			-- ID of the successor task (the one that depends on predecessor).

	dependency_type: STRING_8
			-- Type of dependency relationship.

feature -- Dependency Type Constants

	Type_finish_to_start: STRING_8 = "finish_to_start"
			-- Predecessor must finish before successor can start.
			-- Most common type. "Task B can't start until Task A finishes."

	Type_start_to_start: STRING_8 = "start_to_start"
			-- Predecessor must start before successor can start.
			-- "Task B can start as soon as Task A starts."

	Type_finish_to_finish: STRING_8 = "finish_to_finish"
			-- Predecessor must finish before successor can finish.
			-- "Task B can't finish until Task A finishes."

	Type_start_to_finish: STRING_8 = "start_to_finish"
			-- Predecessor must start before successor can finish.
			-- Rarely used. "Task B can't finish until Task A starts."

feature -- Validation

	is_valid_dependency_type (a_type: READABLE_STRING_8): BOOLEAN
			-- Is this a valid dependency type?
		do
			Result := a_type.same_string (Type_finish_to_start) or else
				a_type.same_string (Type_start_to_start) or else
				a_type.same_string (Type_finish_to_finish) or else
				a_type.same_string (Type_start_to_finish)
		end

feature -- Status

	is_new: BOOLEAN
			-- Has this dependency not yet been saved to database?
		do
			Result := id = 0
		end

	is_finish_to_start: BOOLEAN
			-- Is this a finish-to-start dependency?
		do
			Result := dependency_type.same_string (Type_finish_to_start)
		end

	is_start_to_start: BOOLEAN
			-- Is this a start-to-start dependency?
		do
			Result := dependency_type.same_string (Type_start_to_start)
		end

	is_finish_to_finish: BOOLEAN
			-- Is this a finish-to-finish dependency?
		do
			Result := dependency_type.same_string (Type_finish_to_finish)
		end

	is_start_to_finish: BOOLEAN
			-- Is this a start-to-finish dependency?
		do
			Result := dependency_type.same_string (Type_start_to_finish)
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

	set_dependency_type (a_type: READABLE_STRING_8)
			-- Change dependency type.
		require
			valid_type: is_valid_dependency_type (a_type)
		do
			dependency_type := a_type.twin
		ensure
			type_set: dependency_type.same_string (a_type)
		end

feature -- Fluent Builders

	with_type (a_type: READABLE_STRING_8): like Current
			-- Set dependency type and return self for chaining.
		require
			valid_type: is_valid_dependency_type (a_type)
		do
			set_dependency_type (a_type)
			Result := Current
		ensure
			type_set: dependency_type.same_string (a_type)
		end

	as_start_to_start: like Current
			-- Change to start-to-start and return self.
		do
			Result := with_type (Type_start_to_start)
		ensure
			is_start_to_start: is_start_to_start
		end

	as_finish_to_finish: like Current
			-- Change to finish-to-finish and return self.
		do
			Result := with_type (Type_finish_to_finish)
		ensure
			is_finish_to_finish: is_finish_to_finish
		end

feature -- Output

	out: STRING_8
			-- String representation.
		do
			create Result.make (50)
			Result.append ("Task ")
			Result.append_integer_64 (predecessor_id)
			Result.append (" -> Task ")
			Result.append_integer_64 (successor_id)
			Result.append (" (")
			Result.append (dependency_type)
			Result.append (")")
		end

	description: STRING_8
			-- Human-readable description of this dependency.
		do
			create Result.make (100)
			if is_finish_to_start then
				Result.append ("Task ")
				Result.append_integer_64 (successor_id)
				Result.append (" cannot start until Task ")
				Result.append_integer_64 (predecessor_id)
				Result.append (" finishes")
			elseif is_start_to_start then
				Result.append ("Task ")
				Result.append_integer_64 (successor_id)
				Result.append (" cannot start until Task ")
				Result.append_integer_64 (predecessor_id)
				Result.append (" starts")
			elseif is_finish_to_finish then
				Result.append ("Task ")
				Result.append_integer_64 (successor_id)
				Result.append (" cannot finish until Task ")
				Result.append_integer_64 (predecessor_id)
				Result.append (" finishes")
			else
				Result.append ("Task ")
				Result.append_integer_64 (successor_id)
				Result.append (" cannot finish until Task ")
				Result.append_integer_64 (predecessor_id)
				Result.append (" starts")
			end
		end

invariant
	valid_predecessor: predecessor_id >= 0
	valid_successor: successor_id >= 0
	not_self_reference: predecessor_id /= successor_id or else predecessor_id = 0
	valid_type: is_valid_dependency_type (dependency_type)
	id_non_negative: id >= 0

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
