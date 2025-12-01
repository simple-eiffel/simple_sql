note
	description: "[
		Generic repository pattern for database entities.

		Provides common CRUD operations (Create, Read, Update, Delete) for
		database entities. Subclasses must implement deferred features to
		specify table name, primary key, and entity mapping.

		Usage:
			class USER_REPOSITORY inherit SIMPLE_SQL_REPOSITORY [USER]
			feature
				table_name: STRING_8 = "users"
				primary_key_column: STRING_8 = "id"
				row_to_entity (a_row): USER do ... end
				entity_to_columns (a_entity): HASH_TABLE do ... end
				entity_id (a_entity): INTEGER_64 do ... end
			end

			-- Then use:
			repo := create {USER_REPOSITORY}.make (db)
			all_users := repo.find_all
			user := repo.find_by_id (42)
			active_users := repo.find_where ("status = 'active'")
			new_id := repo.insert (new_user)
			repo.update (existing_user)
			repo.delete (42)
	]"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	SIMPLE_SQL_REPOSITORY [G -> ANY]

feature {NONE} -- Initialization

	make (a_database: SIMPLE_SQL_DATABASE)
			-- Create repository with database connection
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
		ensure
			result_not_void: Result /= Void
		end

	find_all_ordered (a_order_by: READABLE_STRING_8): ARRAYED_LIST [G]
			-- Return all entities ordered by specified column(s)
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
		ensure
			result_not_void: Result /= Void
		end

	find_all_limited (a_limit: INTEGER; a_offset: INTEGER): ARRAYED_LIST [G]
			-- Return entities with pagination
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
			result_not_void: Result /= Void
			respects_limit: Result.count <= a_limit
		end

feature -- Query: By ID

	find_by_id (a_id: INTEGER_64): detachable G
			-- Find entity by primary key, or Void if not found
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
		ensure
			result_not_void: Result /= Void
		end

	find_where_ordered (a_conditions: READABLE_STRING_8; a_order_by: READABLE_STRING_8): ARRAYED_LIST [G]
			-- Find all entities matching conditions with ordering
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
		ensure
			result_not_void: Result /= Void
		end

	find_first_where (a_conditions: READABLE_STRING_8): detachable G
			-- Find first entity matching conditions, or Void if none
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
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.select_builder
				.select_column ("COUNT(*)")
				.from_table (table_name)
				.execute
			if attached l_result and then not l_result.is_empty then
				if attached {INTEGER_64} l_result.first.item (1) as l_count then
					Result := l_count.to_integer_32
				end
			end
		ensure
			non_negative: Result >= 0
		end

	count_where (a_conditions: READABLE_STRING_8): INTEGER
			-- Number of entities matching conditions
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
				if attached {INTEGER_64} l_result.first.item (1) as l_count then
					Result := l_count.to_integer_32
				end
			end
		ensure
			non_negative: Result >= 0
		end

feature -- Command: Insert

	insert (a_entity: G): INTEGER_64
			-- Insert entity and return new primary key ID
			-- Returns 0 if insert failed
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
		do
			Result := database.has_error
		end

	last_error_message: detachable STRING_32
			-- Error message from last failed operation
		do
			Result := database.last_error_message
		end

feature {NONE} -- Implementation (Deferred)

	row_to_entity (a_row: SIMPLE_SQL_ROW): G
			-- Convert database row to entity object
		require
			row_not_void: a_row /= Void
		deferred
		ensure
			result_not_void: Result /= Void
		end

	entity_to_columns (a_entity: G): HASH_TABLE [detachable ANY, STRING_8]
			-- Convert entity to column name/value pairs for insert/update
			-- Should include all columns except auto-generated ones (like AUTOINCREMENT id)
		require
			entity_not_void: a_entity /= Void
		deferred
		ensure
			result_not_void: Result /= Void
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

end
