note
	description: "[
		Schema introspection facade for SQLite databases, providing read access
		to table definitions, column metadata, index structures, and foreign key
		constraints via SQLite's PRAGMA system. Translates raw PRAGMA output rows
		into structured SIMPLE_SQL_*_INFO objects.

		Central to the simple_sql library's schema-awareness mission: applications
		can discover database structure at runtime without parsing SQL. Also manages
		PRAGMA user_version for migration version tracking.

		All queries are live against the database — results reflect the current
		schema state at the time of each call.
	]"
	purpose: "Runtime schema discovery and version management via SQLite PRAGMAs"
	collaborators: "SIMPLE_SQL_DATABASE, SIMPLE_SQL_TABLE_INFO, SIMPLE_SQL_COLUMN_INFO, SIMPLE_SQL_INDEX_INFO, SIMPLE_SQL_FOREIGN_KEY_INFO, SIMPLE_SQL_RESULT, SIMPLE_SQL_ROW"
	design_pattern: "Facade"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_SCHEMA

create
	make

feature {NONE} -- Initialization

	make (a_database: SIMPLE_SQL_DATABASE)
			-- Create schema inspector for database
		note
			semantic_role: "[
				Binds the inspector to a live database
				connection for subsequent PRAGMA queries.
			]"
		require
			database_open: a_database.is_open
		do
			database := a_database
		ensure
			database_set: database = a_database
		end

feature -- Access

	database: SIMPLE_SQL_DATABASE
			-- Database to inspect

feature -- Table Queries

	tables: ARRAYED_LIST [STRING_8]
			-- List of all table names (excluding sqlite_ internal tables)
		note
			semantic_role: "[
				Enumerates user-defined tables for schema
				discovery and migration planning.
			]"
		local
			l_name: STRING_32
		do
			create Result.make (20)
			Result.compare_objects
			if attached database.query ("SELECT l_name FROM sqlite_master WHERE type='table' AND l_name NOT LIKE 'sqlite_%' ORDER BY l_name") as al_l_result then
				across al_l_result.rows as ic loop
					l_name := ic.string_value ("l_name")
					if not l_name.is_empty then
						Result.extend (l_name.to_string_8)
					end
				end
			end
		end

	views: ARRAYED_LIST [STRING_8]
			-- List of all view names
		note
			semantic_role: "[
				Enumerates database views for schema
				discovery.
			]"
		local
			l_name: STRING_32
		do
			create Result.make (10)
			Result.compare_objects
			if attached database.query ("SELECT l_name FROM sqlite_master WHERE type='view' ORDER BY l_name") as al_l_result then
				across al_l_result.rows as ic loop
					l_name := ic.string_value ("l_name")
					if not l_name.is_empty then
						Result.extend (l_name.to_string_8)
					end
				end
			end
		end

	table_exists (a_name: READABLE_STRING_8): BOOLEAN
			-- Does table exist?
		note
			semantic_role: "[
				Table existence predicate for guarding DDL
				operations and migration checks.
			]"
		require
			name_not_empty: not a_name.is_empty
		do
			if attached database.query ("SELECT 1 FROM sqlite_master WHERE type='table' AND name='" + a_name.to_string_8 + "'") as al_l_result then
				Result := not al_l_result.rows.is_empty
			end
		end

	view_exists (a_name: READABLE_STRING_8): BOOLEAN
			-- Does view exist?
		note
			semantic_role: "[
				View existence predicate for guarding
				view-dependent operations.
			]"
		require
			name_not_empty: not a_name.is_empty
		do
			if attached database.query ("SELECT 1 FROM sqlite_master WHERE type='view' AND name='" + a_name.to_string_8 + "'") as al_l_result then
				Result := not al_l_result.rows.is_empty
			end
		end

feature -- Table Info

	table_info (a_table: READABLE_STRING_8): detachable SIMPLE_SQL_TABLE_INFO
			-- Get detailed info about a table
		note
			semantic_role: "[
				Assembles complete table metadata (columns,
				indexes, foreign keys) into a single
				introspection object.
			]"
		require
			table_not_empty: not a_table.is_empty
		local
			l_type: STRING_8
			l_type_str: STRING_32
			l_sql_str: STRING_32
		do
			-- Get table type
			if attached database.query ("SELECT l_type, sql FROM sqlite_master WHERE name='" + a_table.to_string_8 + "'") as al_l_master then
				if not al_l_master.rows.is_empty and then attached al_l_master.rows.first as al_l_row then
					l_type_str := al_l_row.string_value ("l_type")
					if l_type_str.is_empty then
						l_type := "table"
					else
						l_type := l_type_str.to_string_8
					end
					create Result.make (a_table, l_type)
					l_sql_str := al_l_row.string_value ("sql")
					if not l_sql_str.is_empty then
						Result.set_sql (l_sql_str.to_string_8)
					end
					-- Load columns
					load_columns (Result)
					-- Load indexes
					load_indexes (Result)
					-- Load foreign keys
					load_foreign_keys (Result)
				end
			end
		end

feature -- Column Queries

	columns (a_table: READABLE_STRING_8): ARRAYED_LIST [SIMPLE_SQL_COLUMN_INFO]
			-- Get columns for a table
		note
			semantic_role: "[
				Retrieves ordered column metadata via
				PRAGMA table_info for schema inspection.
			]"
		require
			table_not_empty: not a_table.is_empty
		do
			create Result.make (10)
			if attached database.query ("PRAGMA table_info('" + a_table.to_string_8 + "')") as al_l_result then
				across al_l_result.rows as ic loop
					Result.extend (row_to_column_info (ic))
				end
			end
		end

	column_names (a_table: READABLE_STRING_8): ARRAYED_LIST [STRING_8]
			-- Get column names for a table
		note
			semantic_role: "[
				Lightweight column name enumeration without
				full metadata, for display and validation.
			]"
		require
			table_not_empty: not a_table.is_empty
		local
			l_name: STRING_32
		do
			create Result.make (10)
			Result.compare_objects
			if attached database.query ("PRAGMA table_info('" + a_table.to_string_8 + "')") as al_l_result then
				across al_l_result.rows as ic loop
					l_name := ic.string_value ("l_name")
					if not l_name.is_empty then
						Result.extend (l_name.to_string_8)
					end
				end
			end
		end

feature -- Index Queries

	indexes (a_table: READABLE_STRING_8): ARRAYED_LIST [SIMPLE_SQL_INDEX_INFO]
			-- Get indexes for a table
		note
			semantic_role: "[
				Retrieves index metadata via PRAGMA
				index_list/index_info for performance
				analysis.
			]"
		require
			table_not_empty: not a_table.is_empty
		local
			l_index: SIMPLE_SQL_INDEX_INFO
			l_name: STRING_32
			l_origin: STRING_32
			l_origin_str: STRING_8
		do
			create Result.make (5)
			if attached database.query ("PRAGMA index_list('" + a_table.to_string_8 + "')") as al_l_result then
				across al_l_result.rows as ic loop
					l_name := ic.string_value ("l_name")
					if not l_name.is_empty then
						l_origin := ic.string_value ("l_origin")
						if l_origin.is_empty then
							l_origin_str := "c"
						else
							l_origin_str := l_origin.to_string_8
						end
						create l_index.make (
							l_name.to_string_8,
							a_table.to_string_8,
							ic.integer_value ("unique") = 1,
							l_origin_str
						)
						-- Load index columns
						load_index_columns (l_index)
						Result.extend (l_index)
					end
				end
			end
		end

feature -- Foreign Key Queries

	foreign_keys (a_table: READABLE_STRING_8): ARRAYED_LIST [SIMPLE_SQL_FOREIGN_KEY_INFO]
			-- Get foreign keys for a table
		note
			semantic_role: "[
				Retrieves foreign key constraints via
				PRAGMA foreign_key_list for relationship
				discovery.
			]"
		require
			table_not_empty: not a_table.is_empty
		local
			l_fk: detachable SIMPLE_SQL_FOREIGN_KEY_INFO
			l_current_id: INTEGER
			l_to_table: STRING_32
			l_upd: STRING_32
			l_del: STRING_32
			l_from: STRING_32
			l_to: STRING_32
		do
			create Result.make (3)
			l_current_id := -1
			if attached database.query ("PRAGMA foreign_key_list('" + a_table.to_string_8 + "')") as al_l_result then
				across al_l_result.rows as ic loop
					if ic.integer_value ("id") /= l_current_id then
						-- New foreign key
						l_current_id := ic.integer_value ("id")
						l_to_table := ic.string_value ("table")
						if not l_to_table.is_empty then
							create l_fk.make (l_current_id, a_table.to_string_8, l_to_table.to_string_8)
							l_upd := ic.string_value ("on_update")
							if not l_upd.is_empty then
								l_fk.set_on_update (l_upd.to_string_8)
							end
							l_del := ic.string_value ("on_delete")
							if not l_del.is_empty then
								l_fk.set_on_delete (l_del.to_string_8)
							end
							Result.extend (l_fk)
						end
					end
					-- Add column mapping
					if attached l_fk then
						l_from := ic.string_value ("l_from")
						l_to := ic.string_value ("l_to")
						if not l_from.is_empty and not l_to.is_empty then
							l_fk.add_column_mapping (l_from.to_string_8, l_to.to_string_8)
						end
					end
				end
			end
		end

feature -- Schema Version

	user_version: INTEGER
			-- Get PRAGMA user_version (useful for migrations)
		note
			semantic_role: "[
				Reads the database's migration version
				stamp, the key input for
				SIMPLE_SQL_MIGRATION_RUNNER.
			]"
		do
			if attached database.query ("PRAGMA user_version") as al_l_result then
				if not al_l_result.rows.is_empty and then attached al_l_result.rows.first as al_l_row then
					Result := al_l_row.integer_value ("user_version")
				end
			end
		end

	set_user_version (a_version: INTEGER)
			-- Set PRAGMA user_version
		note
			semantic_role: "[
				Stamps the database with a migration
				version after successful migration
				application.
			]"
			modifies: "database PRAGMA user_version"
		require
			version_non_negative: a_version >= 0
		do
			database.execute ("PRAGMA user_version = " + a_version.out)
		end

	schema_version: INTEGER
			-- Get PRAGMA schema_version (internal SQLite version, changes on schema modification)
		note
			semantic_role: "[
				Reads SQLite's internal schema change
				counter for detecting external
				modifications.
			]"
		do
			if attached database.query ("PRAGMA schema_version") as al_l_result then
				if not al_l_result.rows.is_empty and then attached al_l_result.rows.first as al_l_row then
					Result := al_l_row.integer_value ("schema_version")
				end
			end
		end

feature {NONE} -- Implementation

	load_columns (a_table_info: SIMPLE_SQL_TABLE_INFO)
			-- Load columns into table info
		note
			semantic_role: "[
				Populates a TABLE_INFO's column list from
				PRAGMA table_info results.
			]"
		do
			if attached database.query ("PRAGMA table_info('" + a_table_info.name + "')") as al_l_result then
				across al_l_result.rows as ic loop
					a_table_info.add_column (row_to_column_info (ic))
				end
			end
		end

	load_indexes (a_table_info: SIMPLE_SQL_TABLE_INFO)
			-- Load indexes into table info
		note
			semantic_role: "[
				Populates a TABLE_INFO's index list from
				PRAGMA index_list results.
			]"
		local
			l_index: SIMPLE_SQL_INDEX_INFO
			l_name: STRING_32
			l_origin: STRING_32
			l_origin_str: STRING_8
		do
			if attached database.query ("PRAGMA index_list('" + a_table_info.name + "')") as al_l_result then
				across al_l_result.rows as ic loop
					l_name := ic.string_value ("l_name")
					if not l_name.is_empty then
						l_origin := ic.string_value ("l_origin")
						if l_origin.is_empty then
							l_origin_str := "c"
						else
							l_origin_str := l_origin.to_string_8
						end
						create l_index.make (
							l_name.to_string_8,
							a_table_info.name,
							ic.integer_value ("unique") = 1,
							l_origin_str
						)
						load_index_columns (l_index)
						a_table_info.add_index (l_index)
					end
				end
			end
		end

	load_index_columns (a_index: SIMPLE_SQL_INDEX_INFO)
			-- Load column names into index info
		note
			semantic_role: "[
				Populates an INDEX_INFO's column list from
				PRAGMA index_info results.
			]"
		local
			l_name: STRING_32
		do
			if attached database.query ("PRAGMA index_info('" + a_index.name + "')") as al_l_result then
				across al_l_result.rows as ic loop
					l_name := ic.string_value ("l_name")
					if not l_name.is_empty then
						a_index.add_column (l_name.to_string_8)
					end
				end
			end
		end

	load_foreign_keys (a_table_info: SIMPLE_SQL_TABLE_INFO)
			-- Load foreign keys into table info
		note
			semantic_role: "[
				Populates a TABLE_INFO's foreign key list
				from PRAGMA foreign_key_list results.
			]"
		local
			l_fk: detachable SIMPLE_SQL_FOREIGN_KEY_INFO
			l_current_id: INTEGER
			l_to_table: STRING_32
			l_upd: STRING_32
			l_del: STRING_32
			l_from: STRING_32
			l_to: STRING_32
		do
			l_current_id := -1
			if attached database.query ("PRAGMA foreign_key_list('" + a_table_info.name + "')") as al_l_result then
				across al_l_result.rows as ic loop
					if ic.integer_value ("id") /= l_current_id then
						l_current_id := ic.integer_value ("id")
						l_to_table := ic.string_value ("table")
						if not l_to_table.is_empty then
							create l_fk.make (l_current_id, a_table_info.name, l_to_table.to_string_8)
							l_upd := ic.string_value ("on_update")
							if not l_upd.is_empty then
								l_fk.set_on_update (l_upd.to_string_8)
							end
							l_del := ic.string_value ("on_delete")
							if not l_del.is_empty then
								l_fk.set_on_delete (l_del.to_string_8)
							end
							a_table_info.add_foreign_key (l_fk)
						end
					end
					if attached l_fk then
						l_from := ic.string_value ("l_from")
						l_to := ic.string_value ("l_to")
						if not l_from.is_empty and not l_to.is_empty then
							l_fk.add_column_mapping (l_from.to_string_8, l_to.to_string_8)
						end
					end
				end
			end
		end

	row_to_column_info (a_row: SIMPLE_SQL_ROW): SIMPLE_SQL_COLUMN_INFO
			-- Convert PRAGMA table_info row to SIMPLE_SQL_COLUMN_INFO
		note
			semantic_role: "[
				Transforms a raw PRAGMA row into a
				structured COLUMN_INFO object.
			]"
		local
			l_name, l_type: STRING_8
			l_default: detachable STRING_8
			l_name_str, l_type_str, l_default_str: STRING_32
		do
			l_name_str := a_row.string_value ("l_name")
			if l_name_str.is_empty then
				l_name := ""
			else
				l_name := l_name_str.to_string_8
			end
			l_type_str := a_row.string_value ("l_type")
			if l_type_str.is_empty then
				l_type := ""
			else
				l_type := l_type_str.to_string_8
			end
			l_default_str := a_row.string_value ("dflt_value")
			if not l_default_str.is_empty then
				l_default := l_default_str.to_string_8
			end
			create Result.make (
				a_row.integer_value ("cid"),
				l_name,
				l_type,
				a_row.integer_value ("notnull") = 1,
				l_default,
				a_row.integer_value ("pk")
			)
		end

invariant
	database_attached: attached database

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		simple_sql - High-level SQLite API for Eiffel
		https://github.com/simple-eiffel/simple_sql
	]"

end
