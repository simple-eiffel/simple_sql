note
	description: "Information about a database index from schema introspection"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_INDEX_INFO

create
	make

feature {NONE} -- Initialization

	make (a_name: READABLE_STRING_8; a_table: READABLE_STRING_8; a_unique: BOOLEAN; a_origin: READABLE_STRING_8)
			-- Create index info
		require
			name_not_empty: not a_name.is_empty
			table_not_empty: not a_table.is_empty
		do
			name := a_name.to_string_8
			table_name := a_table.to_string_8
			is_unique := a_unique
			origin := a_origin.to_string_8
			create columns.make (5)
		ensure
			name_set: name.same_string (a_name)
			table_set: table_name.same_string (a_table)
			unique_set: is_unique = a_unique
		end

feature -- Access

	name: STRING_8
			-- Index name

	table_name: STRING_8
			-- Table this index belongs to

	origin: STRING_8
			-- Origin: "c" (CREATE INDEX), "u" (UNIQUE constraint), "pk" (PRIMARY KEY)

	columns: ARRAYED_LIST [STRING_8]
			-- Column names in this index (in order)

feature -- Status

	is_unique: BOOLEAN
			-- Is this a unique index?

	is_primary_key: BOOLEAN
			-- Is this the primary key index?
		do
			Result := origin.same_string ("pk")
		end

	is_from_constraint: BOOLEAN
			-- Was this index created from a UNIQUE constraint?
		do
			Result := origin.same_string ("u")
		end

	is_explicit: BOOLEAN
			-- Was this index created explicitly with CREATE INDEX?
		do
			Result := origin.same_string ("c")
		end

feature -- Element Change

	add_column (a_column: READABLE_STRING_8)
			-- Add a column to this index
		require
			column_not_empty: not a_column.is_empty
		do
			columns.extend (a_column.to_string_8)
		ensure
			column_added: columns.has (a_column.to_string_8)
		end

feature -- Output

	description: STRING_8
			-- Human-readable description
		local
			i: INTEGER
		do
			create Result.make (100)
			if is_unique then
				Result.append ("UNIQUE ")
			end
			Result.append ("INDEX ")
			Result.append (name)
			Result.append (" ON ")
			Result.append (table_name)
			Result.append (" (")
			from i := 1 until i > columns.count loop
				if i > 1 then
					Result.append (", ")
				end
				Result.append (columns [i])
				i := i + 1
			end
			Result.append (")")
		end

invariant
	name_not_empty: not name.is_empty
	table_not_empty: not table_name.is_empty
	columns_attached: attached columns

end
