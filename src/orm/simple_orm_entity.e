note
	description: "[
		Base class for ORM entities.

		Provides common functionality for database-backed entities including
		primary key handling, timestamps, and column mapping.

		Usage:
			class USER inherit SIMPLE_ORM_ENTITY
			feature
				table_name: STRING_8 = "users"

				-- Required deferred implementations
				fields: ARRAYED_LIST [SIMPLE_ORM_FIELD]
					once
						create Result.make (3)
						Result.extend (create {SIMPLE_ORM_FIELD}.make_primary_key ("id"))
						Result.extend (create {SIMPLE_ORM_FIELD}.make ("email", {SIMPLE_ORM_FIELD}.type_string))
						Result.extend (create {SIMPLE_ORM_FIELD}.make ("name", {SIMPLE_ORM_FIELD}.type_string))
					end

				get_field_value (a_name: STRING): detachable ANY
					do
						if a_name.same_string ("email") then Result := email
						elseif a_name.same_string ("name") then Result := name
						end
					end

				set_field_value (a_name: STRING; a_value: detachable ANY)
					do
						if a_name.same_string ("email") then
							if attached {STRING} a_value as s then email := s end
						elseif a_name.same_string ("name") then
							if attached {STRING} a_value as s then name := s end
						end
					end
			end
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	SIMPLE_ORM_ENTITY

feature -- Access

	id: INTEGER_64
			-- Primary key (0 if not yet persisted).

	created_at: detachable STRING_8
			-- Timestamp when entity was created (ISO 8601).

	updated_at: detachable STRING_8
			-- Timestamp when entity was last updated (ISO 8601).

feature -- Schema

	table_name: STRING_8
			-- Name of the database table for this entity.
		deferred
		ensure
			not_empty: not Result.is_empty
		end

	primary_key_column: STRING_8
			-- Name of the primary key column.
		do
			Result := "id"
		ensure
			not_empty: not Result.is_empty
		end

	fields: ARRAYED_LIST [SIMPLE_ORM_FIELD]
			-- List of field definitions for this entity.
			-- Should include all columns including primary key.
		deferred
		ensure
			not_empty: not Result.is_empty
		end

feature -- Field Access

	get_field_value (a_field_name: READABLE_STRING_8): detachable ANY
			-- Get value of field by name.
			-- Returns Void if field doesn't exist or value is null.
		require
			field_name_not_empty: not a_field_name.is_empty
		deferred
		end

	set_field_value (a_field_name: READABLE_STRING_8; a_value: detachable ANY)
			-- Set value of field by name.
		require
			field_name_not_empty: not a_field_name.is_empty
		deferred
		end

feature -- Status

	is_new: BOOLEAN
			-- Has this entity not yet been saved to database?
		do
			Result := id = 0
		ensure
			definition: Result = (id = 0)
		end

	is_persisted: BOOLEAN
			-- Has this entity been saved to database?
		do
			Result := id > 0
		ensure
			definition: Result = (id > 0)
		end

	has_field (a_name: READABLE_STRING_8): BOOLEAN
			-- Does this entity have a field with the given name?
		do
			Result := across fields as ic some ic.name.is_case_insensitive_equal (a_name) end
		end

	field_by_name (a_name: READABLE_STRING_8): detachable SIMPLE_ORM_FIELD
			-- Get field descriptor by name.
		do
			across fields as ic loop
				if ic.name.is_case_insensitive_equal (a_name) then
					Result := ic
				end
			end
		end

feature -- Modification

	set_id (a_id: INTEGER_64)
			-- Set the primary key (called after insert).
		require
			was_new: id = 0
			valid_id: a_id > 0
		do
			id := a_id
		ensure
			id_set: id = a_id
		end

	set_timestamps (a_created: READABLE_STRING_8; a_updated: READABLE_STRING_8)
			-- Set created/updated timestamps.
		do
			created_at := a_created.to_string_8
			updated_at := a_updated.to_string_8
		ensure
			created_set: attached created_at as c implies c.same_string (a_created)
			updated_set: attached updated_at as u implies u.same_string (a_updated)
		end

	touch_updated
			-- Update the updated_at timestamp to current time.
			-- Note: In real use, ORM sets this automatically on save.
		do
			-- Timestamp is set by database or ORM
		end

feature -- Column Conversion

	to_column_hash: HASH_TABLE [detachable ANY, STRING_8]
			-- Convert entity to column name/value pairs.
			-- Excludes primary key (for insert) and auto-timestamps.
		local
			l_value: detachable ANY
		do
			create Result.make (fields.count)
			across fields as ic loop
				if not ic.is_primary_key and not ic.is_auto_increment then
					-- Skip timestamp fields if they use database defaults
					if not ic.name.is_case_insensitive_equal ("created_at") and
					   not ic.name.is_case_insensitive_equal ("updated_at") then
						l_value := get_field_value (ic.name)
						Result.put (l_value, ic.name)
					end
				end
			end
		end

	from_row (a_row: SIMPLE_SQL_ROW)
			-- Populate entity from database row.
		require
			row_attached: a_row /= Void
		local
			l_value: detachable ANY
		do
			across fields as ic loop
				if ic.is_primary_key then
					id := a_row.integer_64_value (ic.name)
				elseif ic.name.is_case_insensitive_equal ("created_at") then
					if not a_row.is_null ("created_at") then
						created_at := a_row.string_value ("created_at").to_string_8
					end
				elseif ic.name.is_case_insensitive_equal ("updated_at") then
					if not a_row.is_null ("updated_at") then
						updated_at := a_row.string_value ("updated_at").to_string_8
					end
				else
					if not a_row.is_null (ic.name) then
						inspect ic.field_type
						when {SIMPLE_ORM_FIELD}.type_string then
							l_value := a_row.string_value (ic.name).to_string_8
						when {SIMPLE_ORM_FIELD}.type_integer then
							l_value := a_row.integer_value (ic.name)
						when {SIMPLE_ORM_FIELD}.type_integer_64 then
							l_value := a_row.integer_64_value (ic.name)
						when {SIMPLE_ORM_FIELD}.type_real then
							l_value := a_row.real_value (ic.name)
						when {SIMPLE_ORM_FIELD}.type_boolean then
							l_value := a_row.integer_value (ic.name) = 1
						when {SIMPLE_ORM_FIELD}.type_datetime then
							l_value := a_row.string_value (ic.name).to_string_8
						else
							l_value := a_row.string_value (ic.name).to_string_8
						end
						set_field_value (ic.name, l_value)
					else
						set_field_value (ic.name, Void)
					end
				end
			end
		end

feature -- SQL Generation

	create_table_sql: STRING_8
			-- Generate CREATE TABLE SQL for this entity.
		local
			l_first: BOOLEAN
		do
			create Result.make (200)
			Result.append ("CREATE TABLE IF NOT EXISTS ")
			Result.append (table_name)
			Result.append (" (")
			l_first := True
			across fields as ic loop
				if not l_first then
					Result.append (", ")
				end
				Result.append (ic.sql_column_definition)
				l_first := False
			end
			Result.append (")")
		end

invariant
	id_non_negative: id >= 0

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
