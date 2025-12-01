note
	description: "Test entity class for repository pattern tests"

class
	TEST_USER_ENTITY

create
	make

feature {NONE} -- Initialization

	make (a_id: INTEGER_64; a_name: STRING_8; a_age: INTEGER; a_status: STRING_8)
			-- Create user entity
		require
			id_non_negative: a_id >= 0
			name_not_empty: not a_name.is_empty
			age_non_negative: a_age >= 0
			status_not_empty: not a_status.is_empty
		do
			id := a_id
			name := a_name
			age := a_age
			status := a_status
		ensure
			id_set: id = a_id
			name_set: name = a_name
			age_set: age = a_age
			status_set: status = a_status
		end

feature -- Access

	id: INTEGER_64
			-- Primary key (0 for new unsaved entities)

	name: STRING_8
			-- User name

	age: INTEGER
			-- User age

	status: STRING_8
			-- User status (active, inactive, etc.)

feature -- Element Change

	set_id (a_id: INTEGER_64)
			-- Set the ID (typically after insert)
		require
			id_non_negative: a_id >= 0
		do
			id := a_id
		ensure
			id_set: id = a_id
		end

	set_name (a_name: STRING_8)
			-- Set the name
		require
			name_not_empty: not a_name.is_empty
		do
			name := a_name
		ensure
			name_set: name = a_name
		end

	set_age (a_age: INTEGER)
			-- Set the age
		require
			age_non_negative: a_age >= 0
		do
			age := a_age
		ensure
			age_set: age = a_age
		end

	set_status (a_status: STRING_8)
			-- Set the status
		require
			status_not_empty: not a_status.is_empty
		do
			status := a_status
		ensure
			status_set: status = a_status
		end

feature -- Status

	is_new: BOOLEAN
			-- Is this a new entity (not yet persisted)?
		do
			Result := id = 0
		end

invariant
	id_non_negative: id >= 0
	name_attached: name /= Void
	name_not_empty: not name.is_empty
	age_non_negative: age >= 0
	status_attached: status /= Void
	status_not_empty: not status.is_empty

end
