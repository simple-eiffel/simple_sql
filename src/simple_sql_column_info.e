note
	description: "[
		A structured metadata record for a single SQLite column as reported by
		PRAGMA table_info.
		Captures position, name, declared type, nullability, default value, and
		primary key participation, with type affinity classification following
		SQLite's affinity determination rules.
		Provides schema introspection data used throughout the simple_sql library.
	]"
	purpose: "Represent column metadata with SQLite type affinity classification"
	collaborators: "SIMPLE_SQL_TABLE_INFO, SIMPLE_SQL_SCHEMA"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_COLUMN_INFO

create
	make

feature {NONE} -- Initialization

	make (a_cid: INTEGER; a_name: READABLE_STRING_8; a_type: READABLE_STRING_8;
			a_notnull: BOOLEAN; a_default: detachable READABLE_STRING_8; a_pk: INTEGER)
			-- Create column info from PRAGMA table_info results
		note
			semantic_role: "[
				Captures all PRAGMA table_info fields
				into structured attributes for schema
				introspection queries.
			]"
		require
			name_not_empty: not a_name.is_empty
		do
			column_id := a_cid
			name := a_name.to_string_8
			declared_type := a_type.to_string_8
			is_not_null := a_notnull
			if attached a_default as al_l_default then
				default_value := al_l_default.to_string_8
			end
			primary_key_index := a_pk
		ensure
			column_id_set: column_id = a_cid
			name_set: name.same_string (a_name)
			type_set: declared_type.same_string (a_type)
			is_not_null_set: is_not_null = a_notnull
			pk_set: primary_key_index = a_pk
		end

feature -- Access

	column_id: INTEGER
			-- Column index (0-based position in table)

	name: STRING_8
			-- Column name

	declared_type: STRING_8
			-- Declared type as string (e.g., "INTEGER", "TEXT", "REAL", "BLOB")

	default_value: detachable STRING_8
			-- Default value expression (if any)

	primary_key_index: INTEGER
			-- Primary key index (0 = not part of PK, 1+ = position in composite PK)

feature -- Status

	is_not_null: BOOLEAN
			-- Is this column NOT NULL constrained?

	is_nullable: BOOLEAN
			-- Can this column contain NULL?
		note
			semantic_role: "[
				Inverse of is_not_null for readability
				in nullable-aware code paths.
			]"
		do
			Result := not is_not_null
		end

	is_primary_key: BOOLEAN
			-- Is this column part of the primary key?
		note
			semantic_role: "[
				Primary key participation predicate for
				filtering key columns from non-key
				columns.
			]"
		do
			Result := primary_key_index > 0
		end

	has_default: BOOLEAN
			-- Does this column have a default value?
		note
			semantic_role: "[
				Default value presence check for
				determining whether INSERT can omit
				this column.
			]"
		do
			Result := attached default_value
		end

feature -- Type Classification

	is_integer_type: BOOLEAN
			-- Is this an integer-affinity type?
		note
			semantic_role: "[
				SQLite integer affinity detection based
				on declared type substring matching.
			]"
		local
			l_upper: STRING_8
		do
			l_upper := declared_type.as_upper
			Result := l_upper.has_substring ("INT")
		end

	is_text_type: BOOLEAN
			-- Is this a text-affinity type?
		note
			semantic_role: "[
				SQLite text affinity detection based on
				declared type substring matching.
			]"
		local
			l_upper: STRING_8
		do
			l_upper := declared_type.as_upper
			Result := l_upper.has_substring ("CHAR") or
					  l_upper.has_substring ("CLOB") or
					  l_upper.has_substring ("TEXT")
		end

	is_real_type: BOOLEAN
			-- Is this a real-affinity type?
		note
			semantic_role: "[
				SQLite real affinity detection based on
				declared type substring matching.
			]"
		local
			l_upper: STRING_8
		do
			l_upper := declared_type.as_upper
			Result := l_upper.has_substring ("REAL") or
					  l_upper.has_substring ("FLOA") or
					  l_upper.has_substring ("DOUB")
		end

	is_blob_type: BOOLEAN
			-- Is this a blob-affinity type?
		note
			semantic_role: "[
				SQLite blob affinity detection, also
				defaulting typeless columns to blob
				per SQLite rules.
			]"
		local
			l_upper: STRING_8
		do
			l_upper := declared_type.as_upper
			Result := l_upper.has_substring ("BLOB") or declared_type.is_empty
		end

	sqlite_affinity: STRING_8
			-- SQLite type affinity (INTEGER, TEXT, REAL, BLOB, NUMERIC)
		note
			semantic_role: "[
				Resolves the declared type to one of
				SQLite's five type affinities for
				type-aware processing.
			]"
		do
			if is_integer_type then
				Result := "INTEGER"
			elseif is_text_type then
				Result := "TEXT"
			elseif is_blob_type then
				Result := "BLOB"
			elseif is_real_type then
				Result := "REAL"
			else
				Result := "NUMERIC"
			end
		end

feature -- Output

	description: STRING_8
			-- Human-readable description
		note
			semantic_role: "[
				Generates a DDL-like summary string
				for display in schema reports.
			]"
		do
			create Result.make (50)
			Result.append (name)
			Result.append (" ")
			Result.append (declared_type)
			if is_primary_key then
				Result.append (" PRIMARY KEY")
			end
			if is_not_null then
				Result.append (" NOT NULL")
			end
			if attached default_value as al_l_default then
				Result.append (" DEFAULT ")
				Result.append (al_l_default)
			end
		end

invariant
	name_not_empty: not name.is_empty
	declared_type_attached: attached declared_type
	primary_key_index_valid: primary_key_index >= 0

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		simple_sql - High-level SQLite API for Eiffel
		https://github.com/simple-eiffel/simple_sql
	]"

end
