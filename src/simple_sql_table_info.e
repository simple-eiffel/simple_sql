note
	description: "[
		Structured metadata for a single database table, aggregating column
		definitions, index structures, and foreign key constraints into one
		introspection object. Built by SIMPLE_SQL_SCHEMA's table_info query
		from SQLite PRAGMA results.

		Provides both structural queries (column_names, primary_key_columns,
		has_column) and type classification (is_table vs is_view) for runtime
		schema inspection. MML model queries enable formal verification of
		metadata collection state.
	]"
	purpose: "Aggregated table metadata container for runtime schema inspection"
	collaborators: "SIMPLE_SQL_SCHEMA, SIMPLE_SQL_COLUMN_INFO, SIMPLE_SQL_INDEX_INFO, SIMPLE_SQL_FOREIGN_KEY_INFO, MML_SEQUENCE"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_TABLE_INFO

create
	make

feature {NONE} -- Initialization

	make (a_name: READABLE_STRING_8; a_type: READABLE_STRING_8)
			-- Create table info
		note
			semantic_role: "[
				Initializes metadata container with table
				identity, preparing empty collections for
				columns, indexes, and foreign keys.
			]"
		require
			name_not_empty: not a_name.is_empty
		do
			name := a_name.to_string_8
			table_type := a_type.to_string_8
			create columns.make (10)
			create indexes.make (5)
			create foreign_keys.make (3)
		ensure
			name_set: name.same_string (a_name)
			type_set: table_type.same_string (a_type)
		end

feature -- Access

	name: STRING_8
			-- Table name

	table_type: STRING_8
			-- Type: "table" or "view"

	columns: ARRAYED_LIST [SIMPLE_SQL_COLUMN_INFO]
			-- Column definitions

	indexes: ARRAYED_LIST [SIMPLE_SQL_INDEX_INFO]
			-- Indexes on this table

	foreign_keys: ARRAYED_LIST [SIMPLE_SQL_FOREIGN_KEY_INFO]
			-- Foreign key constraints

	sql: detachable STRING_8
			-- Original CREATE TABLE/VIEW statement

feature -- Column Access

	column (a_name: READABLE_STRING_8): detachable SIMPLE_SQL_COLUMN_INFO
			-- Find column by name
		note
			semantic_role: "[
				Named column lookup for inspecting
				individual column metadata.
			]"
		require
			name_not_empty: not a_name.is_empty
		do
			across columns as ic loop
				if ic.name.same_string_general (a_name) then
					Result := ic
				end
			end
		end

	column_names: ARRAYED_LIST [STRING_8]
			-- List of column names
		note
			semantic_role: "[
				Extracts column names from full metadata
				for display and query construction.
			]"
		do
			create Result.make (columns.count)
			across columns as ic loop
				Result.extend (ic.name)
			end
		end

	primary_key_columns: ARRAYED_LIST [SIMPLE_SQL_COLUMN_INFO]
			-- Columns that are part of the primary key
		note
			semantic_role: "[
				Filters primary key columns for unique
				identification and relationship analysis.
			]"
		do
			create Result.make (3)
			across columns as ic loop
				if ic.is_primary_key then
					Result.extend (ic)
				end
			end
		end

feature -- Status

	is_table: BOOLEAN
			-- Is this a regular table (not a view)?
		note
			semantic_role: "[
				Table type predicate distinguishing
				writable tables from read-only views.
			]"
		do
			Result := table_type.same_string ("table")
		end

	is_view: BOOLEAN
			-- Is this a view?
		note
			semantic_role: "[
				View type predicate for identifying
				computed/virtual tables.
			]"
		do
			Result := table_type.same_string ("view")
		end

	has_column (a_name: READABLE_STRING_8): BOOLEAN
			-- Does this table have a column with given name?
		note
			semantic_role: "[
				Column existence predicate for validating
				column references before use.
			]"
		require
			name_not_empty: not a_name.is_empty
		do
			Result := attached column (a_name)
		end

	column_count: INTEGER
			-- Number of columns
		note
			semantic_role: "[
				Column count for schema summary display
				and capacity estimation.
			]"
		do
			Result := columns.count
		end

	has_primary_key: BOOLEAN
			-- Does this table have a primary key?
		note
			semantic_role: "[
				Primary key existence check for data
				integrity assessment.
			]"
		do
			across columns as ic loop
				if ic.is_primary_key then
					Result := True
				end
			end
		end

	has_foreign_keys: BOOLEAN
			-- Does this table have foreign key constraints?
		note
			semantic_role: "[
				Foreign key existence check for
				relationship discovery.
			]"
		do
			Result := not foreign_keys.is_empty
		end

feature -- Element Change

	add_column (a_column: SIMPLE_SQL_COLUMN_INFO)
			-- Add column info
		note
			semantic_role: "[
				Appends column metadata during table_info
				assembly by SIMPLE_SQL_SCHEMA.
			]"
			modifies: "columns"
		require
			column_attached: attached a_column
		do
			columns.extend (a_column)
		ensure
			column_added: columns.has (a_column)
			count_increased: columns.count = old columns.count + 1
			model_extended: columns_model.count = old columns_model.count + 1
			model_last: columns_model.last = a_column
			indexes_unchanged: indexes.count = old indexes.count
			fk_unchanged: foreign_keys.count = old foreign_keys.count
		end

	add_index (a_index: SIMPLE_SQL_INDEX_INFO)
			-- Add index info
		note
			semantic_role: "[
				Appends index metadata during table_info
				assembly by SIMPLE_SQL_SCHEMA.
			]"
			modifies: "indexes"
		require
			index_attached: attached a_index
		do
			indexes.extend (a_index)
		ensure
			index_added: indexes.has (a_index)
			count_increased: indexes.count = old indexes.count + 1
			model_extended: indexes_model.count = old indexes_model.count + 1
			model_last: indexes_model.last = a_index
			columns_unchanged: columns.count = old columns.count
			fk_unchanged: foreign_keys.count = old foreign_keys.count
		end

	add_foreign_key (a_fk: SIMPLE_SQL_FOREIGN_KEY_INFO)
			-- Add foreign key info
		note
			semantic_role: "[
				Appends foreign key metadata during
				table_info assembly by SIMPLE_SQL_SCHEMA.
			]"
			modifies: "foreign_keys"
		require
			fk_attached: attached a_fk
		do
			foreign_keys.extend (a_fk)
		ensure
			fk_added: foreign_keys.has (a_fk)
			count_increased: foreign_keys.count = old foreign_keys.count + 1
			model_extended: foreign_keys_model.count = old foreign_keys_model.count + 1
			model_last: foreign_keys_model.last = a_fk
			columns_unchanged: columns.count = old columns.count
			indexes_unchanged: indexes.count = old indexes.count
		end

	set_sql (a_sql: READABLE_STRING_8)
			-- Set the original CREATE statement
		note
			semantic_role: "[
				Records the original DDL for schema
				reconstruction and display.
			]"
			modifies: "sql"
		require
			sql_not_empty: not a_sql.is_empty
		do
			sql := a_sql.to_string_8
		ensure
			sql_set: attached sql as l_sql and then l_sql.same_string (a_sql)
		end

feature -- Model Queries

	columns_model: MML_SEQUENCE [SIMPLE_SQL_COLUMN_INFO]
			-- Mathematical model of column definitions in order.
		note
			semantic_role: "[
				MML specification of column ordering for
				formal contract verification.
			]"
		do
			create Result
			across columns as ic loop
				Result := Result & ic
			end
		ensure
			count_matches: Result.count = columns.count
		end

	indexes_model: MML_SEQUENCE [SIMPLE_SQL_INDEX_INFO]
			-- Mathematical model of indexes in order.
		note
			semantic_role: "[
				MML specification of index ordering for
				formal contract verification.
			]"
		do
			create Result
			across indexes as ic loop
				Result := Result & ic
			end
		ensure
			count_matches: Result.count = indexes.count
		end

	foreign_keys_model: MML_SEQUENCE [SIMPLE_SQL_FOREIGN_KEY_INFO]
			-- Mathematical model of foreign keys in order.
		note
			semantic_role: "[
				MML specification of foreign key ordering
				for formal contract verification.
			]"
		do
			create Result
			across foreign_keys as ic loop
				Result := Result & ic
			end
		ensure
			count_matches: Result.count = foreign_keys.count
		end

feature -- Output

	description: STRING_8
			-- Human-readable description
		note
			semantic_role: "[
				Generates a summary string for display in
				schema reports and debug output.
			]"
		do
			create Result.make (200)
			Result.append (table_type.as_upper)
			Result.append (" ")
			Result.append (name)
			Result.append (" (")
			Result.append_integer (columns.count)
			Result.append (" columns")
			if not indexes.is_empty then
				Result.append (", ")
				Result.append_integer (indexes.count)
				Result.append (" indexes")
			end
			if not foreign_keys.is_empty then
				Result.append (", ")
				Result.append_integer (foreign_keys.count)
				Result.append (" foreign keys")
			end
			Result.append (")")
		end

invariant
	name_not_empty: not name.is_empty
	table_type_valid: table_type.same_string ("table") or table_type.same_string ("view")
	columns_attached: attached columns
	indexes_attached: attached indexes
	foreign_keys_attached: attached foreign_keys

	-- Model consistency
	model_columns_count: columns_model.count = column_count
	model_indexes_count: indexes_model.count = indexes.count
	model_fkeys_count: foreign_keys_model.count = foreign_keys.count

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		simple_sql - High-level SQLite API for Eiffel
		https://github.com/simple-eiffel/simple_sql
	]"

end
