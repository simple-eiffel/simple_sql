note
	description: "Information about a database column from schema introspection"
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
		require
			name_not_empty: not a_name.is_empty
		do
			column_id := a_cid
			name := a_name.to_string_8
			declared_type := a_type.to_string_8
			is_not_null := a_notnull
			if attached a_default as l_default then
				default_value := l_default.to_string_8
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
		do
			Result := not is_not_null
		end

	is_primary_key: BOOLEAN
			-- Is this column part of the primary key?
		do
			Result := primary_key_index > 0
		end

	has_default: BOOLEAN
			-- Does this column have a default value?
		do
			Result := attached default_value
		end

feature -- Type Classification

	is_integer_type: BOOLEAN
			-- Is this an integer-affinity type?
		local
			l_upper: STRING_8
		do
			l_upper := declared_type.as_upper
			Result := l_upper.has_substring ("INT")
		end

	is_text_type: BOOLEAN
			-- Is this a text-affinity type?
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
		local
			l_upper: STRING_8
		do
			l_upper := declared_type.as_upper
			Result := l_upper.has_substring ("BLOB") or declared_type.is_empty
		end

	sqlite_affinity: STRING_8
			-- SQLite type affinity (INTEGER, TEXT, REAL, BLOB, NUMERIC)
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
			if attached default_value as l_default then
				Result.append (" DEFAULT ")
				Result.append (l_default)
			end
		end

invariant
	name_not_empty: not name.is_empty
	declared_type_attached: attached declared_type
	primary_key_index_valid: primary_key_index >= 0

end
