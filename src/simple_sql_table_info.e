note
	description: "Information about a database table from schema introspection"
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
		do
			create Result.make (columns.count)
			across columns as ic loop
				Result.extend (ic.name)
			end
		end

	primary_key_columns: ARRAYED_LIST [SIMPLE_SQL_COLUMN_INFO]
			-- Columns that are part of the primary key
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
		do
			Result := table_type.same_string ("table")
		end

	is_view: BOOLEAN
			-- Is this a view?
		do
			Result := table_type.same_string ("view")
		end

	has_column (a_name: READABLE_STRING_8): BOOLEAN
			-- Does this table have a column with given name?
		require
			name_not_empty: not a_name.is_empty
		do
			Result := attached column (a_name)
		end

	column_count: INTEGER
			-- Number of columns
		do
			Result := columns.count
		end

	has_primary_key: BOOLEAN
			-- Does this table have a primary key?
		do
			across columns as ic loop
				if ic.is_primary_key then
					Result := True
				end
			end
		end

	has_foreign_keys: BOOLEAN
			-- Does this table have foreign key constraints?
		do
			Result := not foreign_keys.is_empty
		end

feature -- Element Change

	add_column (a_column: SIMPLE_SQL_COLUMN_INFO)
			-- Add column info
		require
			column_attached: attached a_column
		do
			columns.extend (a_column)
		ensure
			column_added: columns.has (a_column)
		end

	add_index (a_index: SIMPLE_SQL_INDEX_INFO)
			-- Add index info
		require
			index_attached: attached a_index
		do
			indexes.extend (a_index)
		ensure
			index_added: indexes.has (a_index)
		end

	add_foreign_key (a_fk: SIMPLE_SQL_FOREIGN_KEY_INFO)
			-- Add foreign key info
		require
			fk_attached: attached a_fk
		do
			foreign_keys.extend (a_fk)
		ensure
			fk_added: foreign_keys.has (a_fk)
		end

	set_sql (a_sql: READABLE_STRING_8)
			-- Set the original CREATE statement
		require
			sql_not_empty: not a_sql.is_empty
		do
			sql := a_sql.to_string_8
		ensure
			sql_set: attached sql as l_sql and then l_sql.same_string (a_sql)
		end

feature -- Output

	description: STRING_8
			-- Human-readable description
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

end
