note
	description: "[
		Field descriptor for ORM column mapping.

		Describes how an entity attribute maps to a database column,
		including type information and constraints.

		Usage:
			field := create {SIMPLE_ORM_FIELD}.make ("email", {SIMPLE_ORM_FIELD}.type_string)
			field.set_nullable (False)
			field.set_max_length (255)
	]"
	purpose: "Column descriptor with type mapping, constraints, and DDL generation for ORM entities"
	collaborators: "SIMPLE_ORM_ENTITY"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_ORM_FIELD

create
	make,
	make_primary_key

feature {NONE} -- Initialization

	make (a_name: READABLE_STRING_8; a_type: INTEGER)
			-- Create field with name and type.
		note
			semantic_role: "[
				Initializes a nullable, non-primary-key
				field with given name and type.
			]"
		require
			name_not_empty: not a_name.is_empty
			valid_type: is_valid_type (a_type)
		do
			name := a_name.to_string_8
			field_type := a_type
			is_nullable := True
			is_primary_key := False
			is_auto_increment := False
		ensure
			name_set: name.same_string (a_name)
			type_set: field_type = a_type
			nullable_by_default: is_nullable
			not_primary_key: not is_primary_key
		end

	make_primary_key (a_name: READABLE_STRING_8)
			-- Create auto-incrementing integer primary key field.
		note
			semantic_role: "[
				Initializes a non-nullable auto-increment
				integer primary key.
			]"
		require
			name_not_empty: not a_name.is_empty
		do
			name := a_name.to_string_8
			field_type := type_integer
			is_nullable := False
			is_primary_key := True
			is_auto_increment := True
		ensure
			name_set: name.same_string (a_name)
			type_integer: field_type = type_integer
			not_nullable: not is_nullable
			is_pk: is_primary_key
			is_auto: is_auto_increment
		end

feature -- Access

	name: STRING_8
			-- Column name in database.

	field_type: INTEGER
			-- Field type (use type_* constants).

	is_nullable: BOOLEAN
			-- Can this field be NULL?

	is_primary_key: BOOLEAN
			-- Is this the primary key?

	is_auto_increment: BOOLEAN
			-- Is this an auto-increment field?

	max_length: INTEGER
			-- Maximum length for string fields (0 = unlimited).

	default_value: detachable ANY
			-- Default value for this field.

feature -- Type Constants

	type_string: INTEGER = 1
			-- String/TEXT type.

	type_integer: INTEGER = 2
			-- Integer type.

	type_integer_64: INTEGER = 3
			-- 64-bit integer type.

	type_real: INTEGER = 4
			-- Real/floating point type.

	type_boolean: INTEGER = 5
			-- Boolean type (stored as INTEGER 0/1).

	type_datetime: INTEGER = 6
			-- DateTime type (stored as TEXT in ISO 8601 format).

	type_blob: INTEGER = 7
			-- Binary blob type.

feature -- Status

	is_valid_type (a_type: INTEGER): BOOLEAN
			-- Is `a_type` a valid field type?
		note
			semantic_role: "[
				Validates that a type constant falls
				within the supported range.
			]"
		do
			Result := a_type >= type_string and a_type <= type_blob
		end

	is_string_type: BOOLEAN
			-- Is this a string/text type?
		note
			semantic_role: "[
				Tests whether the field type is
				string/text.
			]"
		do
			Result := field_type = type_string
		end

	is_numeric_type: BOOLEAN
			-- Is this a numeric type (integer or real)?
		note
			semantic_role: "[
				Tests whether the field type is any
				numeric variant.
			]"
		do
			Result := field_type = type_integer or field_type = type_integer_64 or field_type = type_real
		end

feature -- Modification

	set_nullable (a_nullable: BOOLEAN)
			-- Set whether field can be NULL.
		note
			semantic_role: "[
				Configures the nullability constraint for
				this column.
			]"
			modifies: "is_nullable"
		do
			is_nullable := a_nullable
		ensure
			nullable_set: is_nullable = a_nullable
		end

	set_max_length (a_length: INTEGER)
			-- Set maximum length for string fields.
		note
			semantic_role: "[
				Sets the VARCHAR length limit for string
				fields.
			]"
			modifies: "max_length"
		require
			positive_length: a_length > 0
			string_type: field_type = type_string
		do
			max_length := a_length
		ensure
			length_set: max_length = a_length
		end

	set_default (a_value: detachable ANY)
			-- Set default value.
		note
			semantic_role: "[
				Records the default value for DDL
				generation.
			]"
			modifies: "default_value"
		do
			default_value := a_value
		ensure
			default_set: default_value = a_value
		end

feature -- SQL Generation

	sql_type: STRING_8
			-- SQL type for this field.
		note
			semantic_role: "[
				Maps the field type constant to a SQLite
				column type string.
			]"
		do
			inspect field_type
			when type_string then
				if max_length > 0 then
					Result := "VARCHAR(" + max_length.out + ")"
				else
					Result := "TEXT"
				end
			when type_integer then
				Result := "INTEGER"
			when type_integer_64 then
				Result := "INTEGER"
			when type_real then
				Result := "REAL"
			when type_boolean then
				Result := "INTEGER"
			when type_datetime then
				Result := "TEXT"
			when type_blob then
				Result := "BLOB"
			else
				Result := "TEXT"
			end
		end

	sql_column_definition: STRING_8
			-- Full SQL column definition for CREATE TABLE.
		note
			semantic_role: "[
				Assembles name, type, constraints, and
				default into a DDL column clause.
			]"
		do
			create Result.make (50)
			Result.append (name)
			Result.append (" ")
			Result.append (sql_type)
			if is_primary_key then
				Result.append (" PRIMARY KEY")
				if is_auto_increment then
					Result.append (" AUTOINCREMENT")
				end
			elseif not is_nullable then
				Result.append (" NOT NULL")
			end
			if attached default_value as al_dv then
				Result.append (" DEFAULT ")
				if attached {STRING} al_dv as al_s then
					Result.append ("'")
					Result.append (al_s)
					Result.append ("'")
				elseif attached {INTEGER} al_dv as al_i then
					Result.append_integer (al_i)
				elseif attached {BOOLEAN} al_dv as al_b then
					if al_b then
						Result.append ("1")
					else
						Result.append ("0")
					end
				else
					Result.append (al_dv.out)
				end
			end
		end

invariant
	name_not_empty: not name.is_empty
	valid_type: is_valid_type (field_type)
	primary_key_not_nullable: is_primary_key implies not is_nullable

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		simple_sql - High-level SQLite API for Eiffel
		https://github.com/simple-eiffel/simple_sql
	]"

end
