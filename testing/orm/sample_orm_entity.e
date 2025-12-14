note
	description: "Sample entity for ORM testing"
	author: "Larry Rix"

class
	SAMPLE_ORM_ENTITY

inherit
	SIMPLE_ORM_ENTITY

create
	make,
	make_default

feature {NONE} -- Initialization

	make (a_name: READABLE_STRING_8; a_email: READABLE_STRING_8; a_age: INTEGER)
			-- Create entity with values.
		require
			name_not_empty: not a_name.is_empty
			email_not_empty: not a_email.is_empty
			positive_age: a_age > 0
		do
			name := a_name.to_string_8
			email := a_email.to_string_8
			age := a_age
			is_active := True
		ensure
			name_set: name.same_string (a_name)
			email_set: email.same_string (a_email)
			age_set: age = a_age
		end

	make_default
			-- Create default empty entity.
		do
			name := ""
			email := ""
			age := 0
			is_active := False
		end

feature -- Access

	name: STRING_8
			-- User name.

	email: STRING_8
			-- User email.

	age: INTEGER
			-- User age.

	is_active: BOOLEAN
			-- Is user active?

feature -- Schema (from SIMPLE_ORM_ENTITY)

	table_name: STRING_8 = "sample_users"
			-- Database table name.

	fields: ARRAYED_LIST [SIMPLE_ORM_FIELD]
			-- Field definitions.
		local
			l_field: SIMPLE_ORM_FIELD
		once
			create Result.make (5)
			-- Primary key
			Result.extend (create {SIMPLE_ORM_FIELD}.make_primary_key ("id"))
			-- Name field
			create l_field.make ("name", {SIMPLE_ORM_FIELD}.type_string)
			l_field.set_nullable (False)
			Result.extend (l_field)
			-- Email field
			create l_field.make ("email", {SIMPLE_ORM_FIELD}.type_string)
			l_field.set_nullable (False)
			Result.extend (l_field)
			-- Age field
			create l_field.make ("age", {SIMPLE_ORM_FIELD}.type_integer)
			l_field.set_nullable (False)
			Result.extend (l_field)
			-- Is active field
			create l_field.make ("is_active", {SIMPLE_ORM_FIELD}.type_boolean)
			l_field.set_default (True)
			Result.extend (l_field)
		end

feature -- Field Access (from SIMPLE_ORM_ENTITY)

	get_field_value (a_field_name: READABLE_STRING_8): detachable ANY
			-- Get value of field by name.
		do
			if a_field_name.is_case_insensitive_equal ("name") then
				Result := name
			elseif a_field_name.is_case_insensitive_equal ("email") then
				Result := email
			elseif a_field_name.is_case_insensitive_equal ("age") then
				Result := age
			elseif a_field_name.is_case_insensitive_equal ("is_active") then
				Result := is_active
			end
		end

	set_field_value (a_field_name: READABLE_STRING_8; a_value: detachable ANY)
			-- Set value of field by name.
		do
			if a_field_name.is_case_insensitive_equal ("name") then
				if attached {READABLE_STRING_8} a_value as s then
					name := s.to_string_8
				end
			elseif a_field_name.is_case_insensitive_equal ("email") then
				if attached {READABLE_STRING_8} a_value as s then
					email := s.to_string_8
				end
			elseif a_field_name.is_case_insensitive_equal ("age") then
				if attached {INTEGER} a_value as i then
					age := i
				end
			elseif a_field_name.is_case_insensitive_equal ("is_active") then
				if attached {BOOLEAN} a_value as b then
					is_active := b
				end
			end
		end

feature -- Modification

	set_name (a_name: READABLE_STRING_8)
			-- Update name.
		require
			not_empty: not a_name.is_empty
		do
			name := a_name.to_string_8
		ensure
			name_set: name.same_string (a_name)
		end

	set_email (a_email: READABLE_STRING_8)
			-- Update email.
		require
			not_empty: not a_email.is_empty
		do
			email := a_email.to_string_8
		ensure
			email_set: email.same_string (a_email)
		end

	set_age (a_age: INTEGER)
			-- Update age.
		require
			positive: a_age > 0
		do
			age := a_age
		ensure
			age_set: age = a_age
		end

	set_active (a_active: BOOLEAN)
			-- Update active status.
		do
			is_active := a_active
		ensure
			active_set: is_active = a_active
		end

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
