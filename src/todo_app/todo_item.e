note
	description: "[
		TODO_ITEM - A todo item entity with full task management features.

		Supports:
		- Hierarchical tasks (parent_id for subtasks)
		- Status workflow (pending, in_progress, waiting, completed, archived)
		- Context tagging (office, home, phone, errands)
		- Energy level tracking (1=low, 2=medium, 3=high focus)
		- Time estimation and tracking
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TODO_ITEM

inherit
	ANY
		redefine
			out
		end

create
	make,
	make_new,
	make_full

feature {NONE} -- Initialization

	make (a_id: INTEGER_64; a_title: READABLE_STRING_8; a_description: detachable READABLE_STRING_8;
			a_priority: INTEGER; a_is_completed: BOOLEAN; a_due_date: detachable READABLE_STRING_8;
			a_created_at: READABLE_STRING_8; a_updated_at: READABLE_STRING_8)
			-- Initialize from database row (legacy compatibility).
		require
			title_not_empty: not a_title.is_empty
			valid_priority: a_priority >= 1 and a_priority <= 5
			created_at_not_empty: not a_created_at.is_empty
			updated_at_not_empty: not a_updated_at.is_empty
		do
			id := a_id
			title := a_title.twin
			if attached a_description as al_desc then
				description := al_desc.twin
			end
			priority := a_priority
			is_completed := a_is_completed
			if attached a_due_date as al_dd then
				due_date := al_dd.twin
			end
			created_at := a_created_at.twin
			updated_at := a_updated_at.twin
			-- New fields default to sensible values
			status := if a_is_completed then Status_completed else Status_pending end
			context := ""
			energy_level := 2
			estimated_minutes := 0
			actual_minutes := 0
			parent_id := 0
		ensure
			id_set: id = a_id
			title_set: title.same_string (a_title)
			priority_set: priority = a_priority
			is_completed_set: is_completed = a_is_completed
		end

	make_full (a_id: INTEGER_64; a_title: READABLE_STRING_8; a_description: detachable READABLE_STRING_8;
			a_priority: INTEGER; a_status: READABLE_STRING_8; a_due_date: detachable READABLE_STRING_8;
			a_context: READABLE_STRING_8; a_energy_level: INTEGER;
			a_estimated_minutes, a_actual_minutes: INTEGER; a_parent_id: INTEGER_64;
			a_created_at: READABLE_STRING_8; a_updated_at: READABLE_STRING_8)
			-- Initialize with all fields from database row.
		require
			title_not_empty: not a_title.is_empty
			valid_priority: a_priority >= 1 and a_priority <= 5
			valid_status: is_valid_status (a_status)
			valid_energy: a_energy_level >= 1 and a_energy_level <= 3
			created_at_not_empty: not a_created_at.is_empty
			updated_at_not_empty: not a_updated_at.is_empty
		do
			id := a_id
			title := a_title.twin
			if attached a_description as al_desc then
				description := al_desc.twin
			end
			priority := a_priority
			status := a_status.twin
			is_completed := a_status.same_string (Status_completed)
			if attached a_due_date as al_dd then
				due_date := al_dd.twin
			end
			context := a_context.twin
			energy_level := a_energy_level
			estimated_minutes := a_estimated_minutes
			actual_minutes := a_actual_minutes
			parent_id := a_parent_id
			created_at := a_created_at.twin
			updated_at := a_updated_at.twin
		ensure
			id_set: id = a_id
			title_set: title.same_string (a_title)
			priority_set: priority = a_priority
			status_set: status.same_string (a_status)
			parent_id_set: parent_id = a_parent_id
		end

	make_new (a_title: READABLE_STRING_8; a_priority: INTEGER)
			-- Create a new todo item (not yet saved to database).
		require
			title_not_empty: not a_title.is_empty
			valid_priority: a_priority >= 1 and a_priority <= 5
		do
			id := 0
			title := a_title.twin
			priority := a_priority
			is_completed := False
			status := Status_pending
			context := ""
			energy_level := 2
			estimated_minutes := 0
			actual_minutes := 0
			parent_id := 0
			created_at := ""
			updated_at := ""
		ensure
			id_zero: id = 0
			title_set: title.same_string (a_title)
			priority_set: priority = a_priority
			not_completed: not is_completed
			status_pending: status.same_string (Status_pending)
		end

feature -- Access

	id: INTEGER_64
			-- Unique identifier (0 if not yet saved).

	title: STRING_8
			-- Task title (required).

	description: detachable STRING_8
			-- Optional detailed description.

	priority: INTEGER
			-- Priority level (1=highest, 5=lowest).

	is_completed: BOOLEAN
			-- Has the task been completed?

	due_date: detachable STRING_8
			-- Optional due date (ISO 8601 format: YYYY-MM-DD).

	created_at: STRING_8
			-- Timestamp when created (ISO 8601).

	updated_at: STRING_8
			-- Timestamp when last updated (ISO 8601).

	status: STRING_8
			-- Workflow status: pending, in_progress, waiting, completed, archived.

	context: STRING_8
			-- Context tag: office, home, phone, errands, or custom.

	energy_level: INTEGER
			-- Focus required: 1=low (mindless), 2=medium, 3=high (deep work).

	estimated_minutes: INTEGER
			-- Estimated time to complete in minutes.

	actual_minutes: INTEGER
			-- Actual time spent in minutes.

	parent_id: INTEGER_64
			-- Parent task ID for subtasks (0 if top-level).

feature -- Status Constants

	Status_pending: STRING_8 = "pending"
	Status_in_progress: STRING_8 = "in_progress"
	Status_waiting: STRING_8 = "waiting"
	Status_completed: STRING_8 = "completed"
	Status_archived: STRING_8 = "archived"

feature -- Context Constants

	Context_office: STRING_8 = "office"
	Context_home: STRING_8 = "home"
	Context_phone: STRING_8 = "phone"
	Context_errands: STRING_8 = "errands"

feature -- Validation

	is_valid_status (a_status: READABLE_STRING_8): BOOLEAN
			-- Is this a valid status value?
		do
			Result := a_status.same_string (Status_pending) or else
				a_status.same_string (Status_in_progress) or else
				a_status.same_string (Status_waiting) or else
				a_status.same_string (Status_completed) or else
				a_status.same_string (Status_archived)
		end

feature -- Status Queries

	is_new: BOOLEAN
			-- Has this item not yet been saved to database?
		do
			Result := id = 0
		end

	is_overdue: BOOLEAN
			-- Is the item past its due date and not completed?
			-- Note: Simple string comparison works for ISO 8601 dates.
		do
			if attached due_date as dd and then not is_completed then
				-- Would need current date comparison in real app
				Result := False -- Placeholder
			end
		end

	is_subtask: BOOLEAN
			-- Is this a subtask of another task?
		do
			Result := parent_id > 0
		end

	is_pending: BOOLEAN
			-- Is status pending?
		do
			Result := status.same_string (Status_pending)
		end

	is_in_progress: BOOLEAN
			-- Is status in_progress?
		do
			Result := status.same_string (Status_in_progress)
		end

	is_waiting: BOOLEAN
			-- Is status waiting (blocked on something)?
		do
			Result := status.same_string (Status_waiting)
		end

	is_archived: BOOLEAN
			-- Is status archived?
		do
			Result := status.same_string (Status_archived)
		end

	is_active: BOOLEAN
			-- Is task still active (not completed or archived)?
		do
			Result := not is_completed and not is_archived
		end

feature -- Modification

	set_title (a_title: READABLE_STRING_8)
			-- Update the title.
		require
			title_not_empty: not a_title.is_empty
		do
			title := a_title.twin
		ensure
			title_set: title.same_string (a_title)
		end

	set_description (a_description: detachable READABLE_STRING_8)
			-- Update the description.
		do
			if attached a_description as al_desc then
				description := al_desc.twin
			else
				description := Void
			end
		ensure
			description_set: attached a_description as d implies attached description as dd and then dd.same_string (d)
			description_void: a_description = Void implies description = Void
		end

	set_priority (a_priority: INTEGER)
			-- Update the priority.
		require
			valid_priority: a_priority >= 1 and a_priority <= 5
		do
			priority := a_priority
		ensure
			priority_set: priority = a_priority
		end

	set_due_date (a_due_date: detachable READABLE_STRING_8)
			-- Update the due date.
		do
			if attached a_due_date as al_dd then
				due_date := al_dd.twin
			else
				due_date := Void
			end
		end

	mark_completed
			-- Mark the item as completed.
		do
			is_completed := True
		ensure
			completed: is_completed
		end

	mark_incomplete
			-- Mark the item as not completed.
		do
			is_completed := False
		ensure
			not_completed: not is_completed
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

	set_timestamps (a_created: READABLE_STRING_8; a_updated: READABLE_STRING_8)
			-- Set timestamps (called after insert/update).
		require
			created_not_empty: not a_created.is_empty
			updated_not_empty: not a_updated.is_empty
		do
			created_at := a_created.to_string_8
			updated_at := a_updated.to_string_8
		ensure
			created_set: created_at.same_string (a_created)
			updated_set: updated_at.same_string (a_updated)
		end

	set_status (a_status: READABLE_STRING_8)
			-- Set workflow status.
		require
			valid_status: is_valid_status (a_status)
		do
			status := a_status.twin
			is_completed := a_status.same_string (Status_completed)
		ensure
			status_set: status.same_string (a_status)
			completed_synced: is_completed = a_status.same_string (Status_completed)
		end

	set_context (a_context: READABLE_STRING_8)
			-- Set context tag.
		do
			context := a_context.twin
		ensure
			context_set: context.same_string (a_context)
		end

	set_energy_level (a_level: INTEGER)
			-- Set energy level required.
		require
			valid_level: a_level >= 1 and a_level <= 3
		do
			energy_level := a_level
		ensure
			level_set: energy_level = a_level
		end

	set_estimated_minutes (a_minutes: INTEGER)
			-- Set estimated time.
		require
			non_negative: a_minutes >= 0
		do
			estimated_minutes := a_minutes
		ensure
			set: estimated_minutes = a_minutes
		end

	set_actual_minutes (a_minutes: INTEGER)
			-- Set actual time spent.
		require
			non_negative: a_minutes >= 0
		do
			actual_minutes := a_minutes
		ensure
			set: actual_minutes = a_minutes
		end

	add_actual_minutes (a_minutes: INTEGER)
			-- Add to actual time spent.
		require
			positive: a_minutes > 0
		do
			actual_minutes := actual_minutes + a_minutes
		ensure
			added: actual_minutes = old actual_minutes + a_minutes
		end

	set_parent_id (a_parent_id: INTEGER_64)
			-- Set parent task for subtasks.
		require
			valid_parent: a_parent_id >= 0
			not_self: a_parent_id /= id
		do
			parent_id := a_parent_id
		ensure
			set: parent_id = a_parent_id
		end

	start_work
			-- Mark as in progress.
		do
			set_status (Status_in_progress)
		ensure
			in_progress: is_in_progress
		end

	mark_waiting
			-- Mark as waiting/blocked.
		do
			set_status (Status_waiting)
		ensure
			waiting: is_waiting
		end

	archive
			-- Archive the task.
		do
			set_status (Status_archived)
		ensure
			archived: is_archived
		end

feature -- Fluent Builders

	with_description (a_description: READABLE_STRING_8): like Current
			-- Set description and return self for chaining.
		do
			set_description (a_description)
			Result := Current
		ensure
			description_set: attached description as d implies d.same_string (a_description)
		end

	with_due_date (a_due_date: READABLE_STRING_8): like Current
			-- Set due date and return self for chaining.
		do
			set_due_date (a_due_date)
			Result := Current
		end

	with_context (a_context: READABLE_STRING_8): like Current
			-- Set context and return self for chaining.
		do
			set_context (a_context)
			Result := Current
		ensure
			context_set: context.same_string (a_context)
		end

	with_energy (a_level: INTEGER): like Current
			-- Set energy level and return self for chaining.
		require
			valid_level: a_level >= 1 and a_level <= 3
		do
			set_energy_level (a_level)
			Result := Current
		ensure
			level_set: energy_level = a_level
		end

	with_estimate (a_minutes: INTEGER): like Current
			-- Set estimated minutes and return self for chaining.
		require
			non_negative: a_minutes >= 0
		do
			set_estimated_minutes (a_minutes)
			Result := Current
		ensure
			set: estimated_minutes = a_minutes
		end

	with_parent (a_parent_id: INTEGER_64): like Current
			-- Set parent task and return self for chaining.
		require
			valid_parent: a_parent_id >= 0
		do
			set_parent_id (a_parent_id)
			Result := Current
		ensure
			set: parent_id = a_parent_id
		end

	as_subtask_of (a_parent_id: INTEGER_64): like Current
			-- Alias for with_parent for readability.
		require
			valid_parent: a_parent_id > 0
		do
			Result := with_parent (a_parent_id)
		ensure
			set: parent_id = a_parent_id
		end

feature -- Output

	out: STRING_8
			-- String representation.
		do
			create Result.make (100)
			Result.append ("[")
			if is_completed then
				Result.append ("X")
			else
				Result.append (" ")
			end
			Result.append ("] ")
			Result.append ("(P")
			Result.append_integer (priority)
			Result.append (") ")
			Result.append (title)
			if attached due_date as al_dd then
				Result.append (" [Due: ")
				Result.append (al_dd)
				Result.append ("]")
			end
		end

invariant
	title_not_empty: not title.is_empty
	valid_priority: priority >= 1 and priority <= 5
	id_non_negative: id >= 0
	valid_status: is_valid_status (status)
	valid_energy_level: energy_level >= 1 and energy_level <= 3
	valid_estimates: estimated_minutes >= 0 and actual_minutes >= 0
	parent_id_non_negative: parent_id >= 0
	context_attached: context /= Void

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
