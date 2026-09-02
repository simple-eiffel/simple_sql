note
	description: "[
		A deferred generic repository providing CRUD operations for database entities.
		Delegates table name, primary key, and entity-to-row mapping to concrete
		descendants while implementing find, insert, update, delete, and save using
		the simple_sql query builders.
		Establishes the Repository pattern for entity persistence in the simple_sql library.
	]"
	purpose: "Provide generic CRUD operations for entity persistence via query builders"
	collaborators: "SIMPLE_SQL_DATABASE, SIMPLE_SQL_RESULT, SIMPLE_SQL_ROW, SIMPLE_SQL_SELECT_BUILDER, SIMPLE_SQL_INSERT_BUILDER, SIMPLE_SQL_UPDATE_BUILDER, SIMPLE_SQL_DELETE_BUILDER"
	design_pattern: "Repository"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	SIMPLE_SQL_REPOSITORY [G -> ANY]

feature {NONE} -- Initialization

	make (a_database: SIMPLE_SQL_DATABASE)
			-- Create repository with database connection
		note
			semantic_role: "[
				Captures database reference for all
				repository operations.
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
			-- Database connection

	table_name: STRING_8
			-- Name of the database table
		deferred
		ensure
			not_empty: not Result.is_empty
		end

	primary_key_column: STRING_8
			-- Name of the primary key column
		deferred
		ensure
			not_empty: not Result.is_empty
		end

feature -- Query: All

	find_all: ARRAYED_LIST [G]
			-- Return all entities from the table
		note
			semantic_role: "[
				Selects all rows and maps each to an
				entity via row_to_entity.
			]"
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (10)
			l_result := database.select_builder
				.select_all
				.from_table (table_name)
				.execute
			if attached l_result then
				across l_result.rows as ic loop
					Result.extend (row_to_entity (ic))
				end
			end
		end

	find_all_ordered (a_order_by: READABLE_STRING_8): ARRAYED_LIST [G]
			-- Return all entities ordered by specified column(s)
		note
			semantic_role: "[
				Selects all rows with ORDER BY and
				maps to entities.
			]"
		require
			order_not_empty: not a_order_by.is_empty
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (10)
			l_result := database.select_builder
				.select_all
				.from_table (table_name)
				.order_by (a_order_by)
				.execute
			if attached l_result then
				across l_result.rows as ic loop
					Result.extend (row_to_entity (ic))
				end
			end
		end

	find_all_limited (a_limit: INTEGER; a_offset: INTEGER): ARRAYED_LIST [G]
			-- Return entities with pagination
		note
			semantic_role: "[
				Selects a page of rows with LIMIT and
				OFFSET and maps to entities.
			]"
		require
			positive_limit: a_limit > 0
			non_negative_offset: a_offset >= 0
		local
			l_result: SIMPLE_SQL_RESULT
			l_builder: SIMPLE_SQL_SELECT_BUILDER
		do
			create Result.make (a_limit)
			l_builder := database.select_builder
				.select_all
				.from_table (table_name)
				.limit (a_limit)
			if a_offset > 0 then
				l_builder := l_builder.offset (a_offset)
			end
			l_result := l_builder.execute
			if attached l_result then
				across l_result.rows as ic loop
					Result.extend (row_to_entity (ic))
				end
			end
		ensure
			respects_limit: Result.count <= a_limit
		end

feature -- Query: By ID

	find_by_id (a_id: INTEGER_64): detachable G
			-- Find entity by primary key, or Void if not found
		note
			semantic_role: "[
				Queries a single row by primary key
				and maps to entity.
			]"
		require
			valid_id: a_id > 0
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.select_builder
				.select_all
				.from_table (table_name)
				.where (primary_key_column + " = " + a_id.out)
				.limit (1)
				.execute
			if attached l_result and then not l_result.is_empty then
				Result := row_to_entity (l_result.first)
			end
		end

	exists (a_id: INTEGER_64): BOOLEAN
			-- Does an entity with this ID exist?
		note
			semantic_role: "[
				Checks for row existence by primary key
				without loading data.
			]"
		require
			valid_id: a_id > 0
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.select_builder
				.select_column ("1")
				.from_table (table_name)
				.where (primary_key_column + " = " + a_id.out)
				.limit (1)
				.execute
			Result := attached l_result and then not l_result.is_empty
		end

feature -- Query: Conditional

	find_where (a_conditions: READABLE_STRING_8): ARRAYED_LIST [G]
			-- Find all entities matching conditions
			-- Example: "status = 'active' AND age > 21"
		note
			semantic_role: "[
				Selects rows matching a WHERE clause
				and maps to entities.
			]"
		require
			conditions_not_empty: not a_conditions.is_empty
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (10)
			l_result := database.select_builder
				.select_all
				.from_table (table_name)
				.where (a_conditions)
				.execute
			if attached l_result then
				across l_result.rows as ic loop
					Result.extend (row_to_entity (ic))
				end
			end
		end

	find_where_ordered (a_conditions: READABLE_STRING_8; a_order_by: READABLE_STRING_8): ARRAYED_LIST [G]
			-- Find all entities matching conditions with ordering
		note
			semantic_role: "[
				Selects rows matching WHERE with
				ORDER BY and maps to entities.
			]"
		require
			conditions_not_empty: not a_conditions.is_empty
			order_not_empty: not a_order_by.is_empty
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (10)
			l_result := database.select_builder
				.select_all
				.from_table (table_name)
				.where (a_conditions)
				.order_by (a_order_by)
				.execute
			if attached l_result then
				across l_result.rows as ic loop
					Result.extend (row_to_entity (ic))
				end
			end
		end

	find_first_where (a_conditions: READABLE_STRING_8): detachable G
			-- Find first entity matching conditions, or Void if none
		note
			semantic_role: "[
				Selects the first row matching WHERE
				and maps to entity.
			]"
		require
			conditions_not_empty: not a_conditions.is_empty
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.select_builder
				.select_all
				.from_table (table_name)
				.where (a_conditions)
				.limit (1)
				.execute
			if attached l_result and then not l_result.is_empty then
				Result := row_to_entity (l_result.first)
			end
		end

feature -- Query: Counting

	count: INTEGER
			-- Total number of entities in the table
		note
			semantic_role: "[
				Returns the COUNT(*) of all rows in
				the table.
			]"
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.select_builder
				.select_column ("COUNT(*)")
				.from_table (table_name)
				.execute
			if attached l_result and then not l_result.is_empty then
				if attached {INTEGER_64} l_result.first.item (1) as al_l_count then
					Result := al_l_count.to_integer_32
				end
			end
		ensure
			non_negative: Result >= 0
		end

	count_where (a_conditions: READABLE_STRING_8): INTEGER
			-- Number of entities matching conditions
		note
			semantic_role: "[
				Returns the COUNT(*) of rows matching
				a WHERE clause.
			]"
		require
			conditions_not_empty: not a_conditions.is_empty
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.select_builder
				.select_column ("COUNT(*)")
				.from_table (table_name)
				.where (a_conditions)
				.execute
			if attached l_result and then not l_result.is_empty then
				if attached {INTEGER_64} l_result.first.item (1) as al_l_count then
					Result := al_l_count.to_integer_32
				end
			end
		ensure
			non_negative: Result >= 0
		end

feature -- Command: Insert

	insert (a_entity: G): INTEGER_64
			-- Insert entity and return new primary key ID
			-- Returns 0 if insert failed
		note
			semantic_role: "[
				Maps entity to columns via
				entity_to_columns and executes INSERT
				returning the new row ID.
			]"
		local
			l_columns: HASH_TABLE [detachable ANY, STRING_8]
			l_builder: SIMPLE_SQL_INSERT_BUILDER
			l_keys: ARRAY [STRING_8]
			l_key: STRING_8
			i: INTEGER
		do
			l_columns := entity_to_columns (a_entity)
			l_builder := database.insert_builder.into (table_name)
			l_keys := l_columns.current_keys
			from i := l_keys.lower until i > l_keys.upper loop
				l_key := l_keys [i]
				l_builder := l_builder.set (l_key, l_columns.item (l_key))
				i := i + 1
			end
			Result := l_builder.execute_returning_id
		ensure
			positive_id_on_success: not has_error implies Result > 0
		end

feature -- Command: Update

	update (a_entity: G): BOOLEAN
			-- Update entity by its primary key
			-- Returns True if exactly one row was updated
		note
			semantic_role: "[
				Maps entity to columns, excludes primary
				key from SET, and executes UPDATE.
			]"
		local
			l_columns: HASH_TABLE [detachable ANY, STRING_8]
			l_builder: SIMPLE_SQL_UPDATE_BUILDER
			l_id: INTEGER_64
			l_rows_affected: INTEGER
			l_keys: ARRAY [STRING_8]
			l_key: STRING_8
			i: INTEGER
		do
			l_id := entity_id (a_entity)
			l_columns := entity_to_columns (a_entity)
			l_builder := database.update_builder.table (table_name)
			l_keys := l_columns.current_keys
			from i := l_keys.lower until i > l_keys.upper loop
				l_key := l_keys [i]
				-- Skip primary key in SET clause
				if not l_key.is_case_insensitive_equal (primary_key_column) then
					l_builder := l_builder.set (l_key, l_columns.item (l_key))
				end
				i := i + 1
			end
			l_builder := l_builder.where (primary_key_column + " = " + l_id.out)
			l_rows_affected := l_builder.execute
			Result := l_rows_affected = 1
		ensure
			entity_still_exists: Result implies exists (entity_id (a_entity))
		end

	update_where (a_columns: HASH_TABLE [detachable ANY, STRING_8]; a_conditions: READABLE_STRING_8): INTEGER
			-- Update columns for all entities matching conditions
			-- Returns number of rows affected
		note
			semantic_role: "[
				Applies column updates to all rows
				matching a WHERE clause.
			]"
		require
			columns_not_empty: not a_columns.is_empty
			conditions_not_empty: not a_conditions.is_empty
		local
			l_builder: SIMPLE_SQL_UPDATE_BUILDER
			l_keys: ARRAY [STRING_8]
			l_key: STRING_8
			i: INTEGER
		do
			l_builder := database.update_builder.table (table_name)
			l_keys := a_columns.current_keys
			from i := l_keys.lower until i > l_keys.upper loop
				l_key := l_keys [i]
				l_builder := l_builder.set (l_key, a_columns.item (l_key))
				i := i + 1
			end
			l_builder := l_builder.where (a_conditions)
			Result := l_builder.execute
		ensure
			non_negative: Result >= 0
		end

feature -- Command: Delete

	delete (a_id: INTEGER_64): BOOLEAN
			-- Delete entity by primary key
			-- Returns True if exactly one row was deleted
		note
			semantic_role: "[
				Executes DELETE by primary key via the
				delete builder.
			]"
		require
			valid_id: a_id > 0
		local
			l_rows_affected: INTEGER
		do
			l_rows_affected := database.delete_builder
				.from_table (table_name)
				.where (primary_key_column + " = " + a_id.out)
				.execute
			Result := l_rows_affected = 1
		ensure
			not_exists_if_success: Result implies not exists (a_id)
		end

	delete_where (a_conditions: READABLE_STRING_8): INTEGER
			-- Delete all entities matching conditions
			-- Returns number of rows deleted
		note
			semantic_role: "[
				Executes DELETE for all rows matching
				a WHERE clause.
			]"
		require
			conditions_not_empty: not a_conditions.is_empty
		do
			Result := database.delete_builder
				.from_table (table_name)
				.where (a_conditions)
				.execute
		ensure
			non_negative: Result >= 0
		end

	delete_all: INTEGER
			-- Delete all entities from the table (use with caution!)
			-- Returns number of rows deleted
		note
			semantic_role: "[
				Removes all rows from the table via
				raw DELETE.
			]"
		do
			database.execute ("DELETE FROM " + table_name)
			Result := database.changes_count
		ensure
			non_negative: Result >= 0
		end

feature -- Command: Save (Insert or Update)

	save (a_entity: G): INTEGER_64
			-- Insert new entity or update existing
			-- Returns entity ID (new or existing)
		note
			semantic_role: "[
				Dispatches to insert or update based
				on entity persistence state.
			]"
		local
			l_id: INTEGER_64
		do
			l_id := entity_id (a_entity)
			if l_id > 0 and then exists (l_id) then
				if update (a_entity) then
					Result := l_id
				end
			else
				Result := insert (a_entity)
			end
		end

feature -- Status

	has_error: BOOLEAN
			-- Did the last operation cause an error?
		note
			semantic_role: "[
				Delegates error status check to the
				database.
			]"
		do
			Result := database.has_error
		end

	last_error_message: detachable STRING_32
			-- Error message from last failed operation
		note
			semantic_role: "[
				Delegates error message retrieval to
				the database.
			]"
		do
			Result := database.last_error_message
		end

feature {NONE} -- Implementation (Deferred)

	row_to_entity (a_row: SIMPLE_SQL_ROW): G
			-- Convert database row to entity object
		require
			row_not_void: a_row /= Void
		deferred
		end

	entity_to_columns (a_entity: G): HASH_TABLE [detachable ANY, STRING_8]
			-- Convert entity to column name/value pairs for insert/update
			-- Should include all columns except auto-generated ones (like AUTOINCREMENT id)
		require
			entity_not_void: a_entity /= Void
		deferred
		end

	entity_id (a_entity: G): INTEGER_64
			-- Extract primary key ID from entity
			-- Returns 0 for new entities (not yet persisted)
		require
			entity_not_void: a_entity /= Void
		deferred
		end

invariant
	database_attached: database /= Void
	database_open: database.is_open
	table_name_valid: not table_name.is_empty
	primary_key_valid: not primary_key_column.is_empty

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		simple_sql - High-level SQLite API for Eiffel
		https://github.com/simple-eiffel/simple_sql
	]"

end
