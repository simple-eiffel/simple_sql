note
	description: "[
		Metadata descriptor for a single database index from SQLite PRAGMA index_list/index_info.
		Captures index name, owning table, uniqueness, origin classification, and ordered column list.
		Exposes index structure for simple_sql schema analysis and performance documentation.
	]"
	purpose: "Represent an index with its origin, uniqueness, and column composition"
	collaborators: "SIMPLE_SQL_TABLE_INFO, SIMPLE_SQL_SCHEMA"
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
		note
			semantic_role: "[
				Captures PRAGMA index_list fields and
				prepares column list for population
				by load_index_columns.
			]"
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
			empty_columns: columns.is_empty
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
		note
			semantic_role: "[
				Primary key origin detection for
				distinguishing PK indexes from other
				unique indexes.
			]"
		do
			Result := origin.same_string ("pk")
		end

	is_from_constraint: BOOLEAN
			-- Was this index created from a UNIQUE constraint?
		note
			semantic_role: "[
				Constraint origin detection for
				distinguishing implicit from explicit
				indexes.
			]"
		do
			Result := origin.same_string ("u")
		end

	is_explicit: BOOLEAN
			-- Was this index created explicitly with CREATE INDEX?
		note
			semantic_role: "[
				Explicit creation detection for
				identifying user-defined performance
				indexes.
			]"
		do
			Result := origin.same_string ("c")
		end

feature -- Element Change

	add_column (a_column: READABLE_STRING_8)
			-- Add a column to this index
		note
			semantic_role: "[
				Appends a column name during index info
				assembly from PRAGMA index_info results.
			]"
			modifies: "columns"
		require
			column_not_empty: not a_column.is_empty
		do
			columns.extend (a_column.to_string_8)
		ensure
			column_added: columns.has (a_column.to_string_8)
			count_incremented: columns.count = old columns.count + 1
			model_extended: columns_model.count = old columns_model.count + 1
			others_unchanged: old columns_model <= columns_model
		end

feature -- Model Queries

	columns_model: MML_SEQUENCE [STRING_8]
			-- Mathematical model of index columns in order.
		note
			semantic_role: "[
				Provides an MML sequence model of
				index columns for contract
				verification.
			]"
		do
			create Result
			across columns as ic loop
				Result := Result & ic
			end
		ensure
			count_matches: Result.count = columns.count
		end

feature -- Output

	description: STRING_8
			-- Human-readable description
		note
			semantic_role: "[
				Generates a DDL-like summary string
				for display in schema reports.
			]"
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
	model_count_consistent: columns_model.count = columns.count

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		simple_sql - High-level SQLite API for Eiffel
		https://github.com/simple-eiffel/simple_sql
	]"

end
