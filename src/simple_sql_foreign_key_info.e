note
	description: "[
		Metadata descriptor for a single foreign key constraint from SQLite PRAGMA foreign_key_list.
		Captures from/to table, composite column mappings, and ON UPDATE/ON DELETE actions.
		Exposes inter-table relationships for simple_sql schema analysis and integrity checking.
	]"
	purpose: "Represent a foreign key constraint with column mappings and referential actions"
	collaborators: "SIMPLE_SQL_TABLE_INFO, SIMPLE_SQL_SCHEMA"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_FOREIGN_KEY_INFO

create
	make

feature {NONE} -- Initialization

	make (a_id: INTEGER; a_from_table: READABLE_STRING_8; a_to_table: READABLE_STRING_8)
			-- Create foreign key info
		note
			semantic_role: "[
				Establishes the foreign key relationship
				identity with default NO ACTION
				referential actions.
			]"
		require
			from_table_not_empty: not a_from_table.is_empty
			to_table_not_empty: not a_to_table.is_empty
		do
			id := a_id
			from_table := a_from_table.to_string_8
			to_table := a_to_table.to_string_8
			create column_mappings.make (3)
			on_update := "NO ACTION"
			on_delete := "NO ACTION"
		ensure
			id_set: id = a_id
			from_table_set: from_table.same_string (a_from_table)
			to_table_set: to_table.same_string (a_to_table)
			empty_mappings: column_mappings.is_empty
		end

feature -- Access

	id: INTEGER
			-- Foreign key ID (for composite keys, multiple rows share same ID)

	from_table: STRING_8
			-- Source table containing the foreign key

	to_table: STRING_8
			-- Referenced table

	column_mappings: ARRAYED_LIST [TUPLE [from_column: STRING_8; to_column: STRING_8]]
			-- Column mappings (from -> to)

	on_update: STRING_8
			-- ON UPDATE action (NO ACTION, RESTRICT, SET NULL, SET DEFAULT, CASCADE)

	on_delete: STRING_8
			-- ON DELETE action (NO ACTION, RESTRICT, SET NULL, SET DEFAULT, CASCADE)

feature -- Status

	is_composite: BOOLEAN
			-- Does this foreign key involve multiple columns?
		note
			semantic_role: "[
				Composite key detection for handling
				multi-column foreign key relationships.
			]"
		do
			Result := column_mappings.count > 1
		end

feature -- Element Change

	add_column_mapping (a_from: READABLE_STRING_8; a_to: READABLE_STRING_8)
			-- Add a column mapping
		note
			semantic_role: "[
				Appends a from/to column pair during
				foreign key assembly from PRAGMA results.
			]"
			modifies: "column_mappings"
		require
			from_not_empty: not a_from.is_empty
			to_not_empty: not a_to.is_empty
		do
			column_mappings.extend ([a_from.to_string_8, a_to.to_string_8])
		ensure
			count_incremented: column_mappings.count = old column_mappings.count + 1
			on_update_unchanged: on_update.same_string (old on_update.twin)
			on_delete_unchanged: on_delete.same_string (old on_delete.twin)
		end

	set_on_update (a_action: READABLE_STRING_8)
			-- Set ON UPDATE action
		note
			semantic_role: "[
				Configures the referential update action
				reported by PRAGMA foreign_key_list.
			]"
			modifies: "on_update"
		require
			action_not_empty: not a_action.is_empty
		do
			on_update := a_action.to_string_8
		ensure
			on_update_set: on_update.same_string (a_action)
		end

	set_on_delete (a_action: READABLE_STRING_8)
			-- Set ON DELETE action
		note
			semantic_role: "[
				Configures the referential delete action
				reported by PRAGMA foreign_key_list.
			]"
			modifies: "on_delete"
		require
			action_not_empty: not a_action.is_empty
		do
			on_delete := a_action.to_string_8
		ensure
			on_delete_set: on_delete.same_string (a_action)
		end

feature -- Model Queries

	column_mappings_model: MML_SEQUENCE [TUPLE [from_column: STRING_8; to_column: STRING_8]]
			-- Mathematical model of column mappings in order.
		note
			semantic_role: "[
				Provides an MML sequence model of
				column mappings for contract
				verification.
			]"
		do
			create Result
			across column_mappings as ic loop
				Result := Result & ic
			end
		ensure
			count_matches: Result.count = column_mappings.count
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
			Result.append ("FOREIGN KEY (")
			from i := 1 until i > column_mappings.count loop
				if i > 1 then
					Result.append (", ")
				end
				Result.append (column_mappings [i].from_column)
				i := i + 1
			end
			Result.append (") REFERENCES ")
			Result.append (to_table)
			Result.append (" (")
			from i := 1 until i > column_mappings.count loop
				if i > 1 then
					Result.append (", ")
				end
				Result.append (column_mappings [i].to_column)
				i := i + 1
			end
			Result.append (")")
			if not on_update.same_string ("NO ACTION") then
				Result.append (" ON UPDATE ")
				Result.append (on_update)
			end
			if not on_delete.same_string ("NO ACTION") then
				Result.append (" ON DELETE ")
				Result.append (on_delete)
			end
		end

invariant
	from_table_not_empty: not from_table.is_empty
	to_table_not_empty: not to_table.is_empty
	column_mappings_attached: attached column_mappings
	on_update_attached: attached on_update
	on_delete_attached: attached on_delete
	model_count_consistent: column_mappings_model.count = column_mappings.count

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		simple_sql - High-level SQLite API for Eiffel
		https://github.com/simple-eiffel/simple_sql
	]"

end
