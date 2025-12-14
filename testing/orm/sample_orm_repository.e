note
	description: "Sample repository using SIMPLE_ORM_REPOSITORY for testing"
	author: "Larry Rix"

class
	SAMPLE_ORM_REPOSITORY

inherit
	SIMPLE_ORM_REPOSITORY [SAMPLE_ORM_ENTITY]

create
	make

feature -- Factory

	new_entity: SAMPLE_ORM_ENTITY
			-- Create a new default entity instance.
		do
			create Result.make_default
		end

feature -- Query: Custom

	find_active: ARRAYED_LIST [SAMPLE_ORM_ENTITY]
			-- Find all active users.
		do
			Result := find_where ("is_active = 1")
		ensure
			all_active: across Result as ic all ic.is_active end
		end

	find_by_email (a_email: READABLE_STRING_8): detachable SAMPLE_ORM_ENTITY
			-- Find user by email.
		require
			email_not_empty: not a_email.is_empty
		do
			Result := find_first_where ("email = '" + a_email.to_string_8 + "'")
		end

	find_by_age_range (a_min, a_max: INTEGER): ARRAYED_LIST [SAMPLE_ORM_ENTITY]
			-- Find users in age range.
		require
			valid_range: a_min <= a_max
		do
			Result := find_where ("age >= " + a_min.out + " AND age <= " + a_max.out)
		end

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
