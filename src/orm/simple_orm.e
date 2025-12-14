note
	description: "[
		Object-Relational Mapping facade for simple_sql.

		Provides simplified CRUD operations for entities that inherit
		from SIMPLE_ORM_ENTITY. Reduces boilerplate by using entity
		metadata for automatic column mapping.

		Usage:
			-- Create ORM with database
			create orm.make (database)

			-- Create table from entity
			orm.create_table (create {MY_ENTITY}.make_default)

			-- Insert
			new_id := orm.insert (entity)

			-- Find
			entity := orm.find_by_id (create {MY_ENTITY}.make_default, 42)
			all := orm.find_all (create {MY_ENTITY}.make_default)

			-- Update
			orm.update (entity)

			-- Delete
			orm.delete (entity)
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_ORM

create
	make

feature {NONE} -- Initialization

	make (a_database: SIMPLE_SQL_DATABASE)
			-- Create ORM with database connection.
		require
			database_open: a_database.is_open
		do
			database := a_database
		ensure
			database_set: database = a_database
		end

feature -- Access

	database: SIMPLE_SQL_DATABASE
			-- Database connection.

feature -- Schema Operations

	create_table (a_prototype: SIMPLE_ORM_ENTITY)
			-- Create table for entity type if it doesn't exist.
		require
			prototype_attached: a_prototype /= Void
		do
			database.execute (a_prototype.create_table_sql)
		end

	drop_table (a_prototype: SIMPLE_ORM_ENTITY)
			-- Drop table for entity type if it exists.
		require
			prototype_attached: a_prototype /= Void
		do
			database.execute ("DROP TABLE IF EXISTS " + a_prototype.table_name)
		end

	table_exists (a_prototype: SIMPLE_ORM_ENTITY): BOOLEAN
			-- Does table for this entity type exist?
		require
			prototype_attached: a_prototype /= Void
		do
			Result := database.schema.table_exists (a_prototype.table_name)
		end

feature -- Query: All

	find_all (a_prototype: SIMPLE_ORM_ENTITY): ARRAYED_LIST [SIMPLE_ORM_ENTITY]
			-- Find all entities of this type.
		require
			prototype_attached: a_prototype /= Void
		local
			l_result: SIMPLE_SQL_RESULT
			l_entity: SIMPLE_ORM_ENTITY
		do
			create Result.make (10)
			l_result := database.select_builder
				.select_all
				.from_table (a_prototype.table_name)
				.execute
			if attached l_result then
				across l_result.rows as ic loop
					l_entity := new_entity_from_prototype (a_prototype)
					l_entity.from_row (ic)
					Result.extend (l_entity)
				end
			end
		end

	find_all_ordered (a_prototype: SIMPLE_ORM_ENTITY; a_order_by: READABLE_STRING_8): ARRAYED_LIST [SIMPLE_ORM_ENTITY]
			-- Find all entities ordered by column(s).
		require
			prototype_attached: a_prototype /= Void
			order_not_empty: not a_order_by.is_empty
		local
			l_result: SIMPLE_SQL_RESULT
			l_entity: SIMPLE_ORM_ENTITY
		do
			create Result.make (10)
			l_result := database.select_builder
				.select_all
				.from_table (a_prototype.table_name)
				.order_by (a_order_by)
				.execute
			if attached l_result then
				across l_result.rows as ic loop
					l_entity := new_entity_from_prototype (a_prototype)
					l_entity.from_row (ic)
					Result.extend (l_entity)
				end
			end
		end

	find_all_limited (a_prototype: SIMPLE_ORM_ENTITY; a_limit, a_offset: INTEGER): ARRAYED_LIST [SIMPLE_ORM_ENTITY]
			-- Find entities with pagination.
		require
			prototype_attached: a_prototype /= Void
			positive_limit: a_limit > 0
			non_negative_offset: a_offset >= 0
		local
			l_result: SIMPLE_SQL_RESULT
			l_builder: SIMPLE_SQL_SELECT_BUILDER
			l_entity: SIMPLE_ORM_ENTITY
		do
			create Result.make (a_limit)
			l_builder := database.select_builder
				.select_all
				.from_table (a_prototype.table_name)
				.limit (a_limit)
			if a_offset > 0 then
				l_builder := l_builder.offset (a_offset)
			end
			l_result := l_builder.execute
			if attached l_result then
				across l_result.rows as ic loop
					l_entity := new_entity_from_prototype (a_prototype)
					l_entity.from_row (ic)
					Result.extend (l_entity)
				end
			end
		ensure
			respects_limit: Result.count <= a_limit
		end

feature -- Query: By ID

	find_by_id (a_prototype: SIMPLE_ORM_ENTITY; a_id: INTEGER_64): detachable SIMPLE_ORM_ENTITY
			-- Find entity by primary key, or Void if not found.
		require
			prototype_attached: a_prototype /= Void
			valid_id: a_id > 0
		local
			l_result: SIMPLE_SQL_RESULT
			l_entity: SIMPLE_ORM_ENTITY
		do
			l_result := database.select_builder
				.select_all
				.from_table (a_prototype.table_name)
				.where (a_prototype.primary_key_column + " = " + a_id.out)
				.limit (1)
				.execute
			if attached l_result and then not l_result.is_empty then
				l_entity := new_entity_from_prototype (a_prototype)
				l_entity.from_row (l_result.first)
				Result := l_entity
			end
		end

	exists (a_prototype: SIMPLE_ORM_ENTITY; a_id: INTEGER_64): BOOLEAN
			-- Does an entity with this ID exist?
		require
			prototype_attached: a_prototype /= Void
			valid_id: a_id > 0
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.select_builder
				.select_column ("1")
				.from_table (a_prototype.table_name)
				.where (a_prototype.primary_key_column + " = " + a_id.out)
				.limit (1)
				.execute
			Result := attached l_result and then not l_result.is_empty
		end

feature -- Query: Conditional

	find_where (a_prototype: SIMPLE_ORM_ENTITY; a_conditions: READABLE_STRING_8): ARRAYED_LIST [SIMPLE_ORM_ENTITY]
			-- Find all entities matching conditions.
		require
			prototype_attached: a_prototype /= Void
			conditions_not_empty: not a_conditions.is_empty
		local
			l_result: SIMPLE_SQL_RESULT
			l_entity: SIMPLE_ORM_ENTITY
		do
			create Result.make (10)
			l_result := database.select_builder
				.select_all
				.from_table (a_prototype.table_name)
				.where (a_conditions)
				.execute
			if attached l_result then
				across l_result.rows as ic loop
					l_entity := new_entity_from_prototype (a_prototype)
					l_entity.from_row (ic)
					Result.extend (l_entity)
				end
			end
		end

	find_first_where (a_prototype: SIMPLE_ORM_ENTITY; a_conditions: READABLE_STRING_8): detachable SIMPLE_ORM_ENTITY
			-- Find first entity matching conditions.
		require
			prototype_attached: a_prototype /= Void
			conditions_not_empty: not a_conditions.is_empty
		local
			l_result: SIMPLE_SQL_RESULT
			l_entity: SIMPLE_ORM_ENTITY
		do
			l_result := database.select_builder
				.select_all
				.from_table (a_prototype.table_name)
				.where (a_conditions)
				.limit (1)
				.execute
			if attached l_result and then not l_result.is_empty then
				l_entity := new_entity_from_prototype (a_prototype)
				l_entity.from_row (l_result.first)
				Result := l_entity
			end
		end

feature -- Query: Counting

	count (a_prototype: SIMPLE_ORM_ENTITY): INTEGER
			-- Total count of entities.
		require
			prototype_attached: a_prototype /= Void
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.select_builder
				.select_column ("COUNT(*)")
				.from_table (a_prototype.table_name)
				.execute
			if attached l_result and then not l_result.is_empty then
				if attached {INTEGER_64} l_result.first.item (1) as l_count then
					Result := l_count.to_integer_32
				end
			end
		ensure
			non_negative: Result >= 0
		end

	count_where (a_prototype: SIMPLE_ORM_ENTITY; a_conditions: READABLE_STRING_8): INTEGER
			-- Count of entities matching conditions.
		require
			prototype_attached: a_prototype /= Void
			conditions_not_empty: not a_conditions.is_empty
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.select_builder
				.select_column ("COUNT(*)")
				.from_table (a_prototype.table_name)
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

	insert (a_entity: SIMPLE_ORM_ENTITY): INTEGER_64
			-- Insert entity and return new primary key.
			-- Returns 0 if insert failed.
		require
			entity_attached: a_entity /= Void
			entity_is_new: a_entity.is_new
		local
			l_columns: HASH_TABLE [detachable ANY, STRING_8]
			l_builder: SIMPLE_SQL_INSERT_BUILDER
			l_keys: ARRAY [STRING_8]
			l_key: STRING_8
			i: INTEGER
		do
			l_columns := a_entity.to_column_hash
			l_builder := database.insert_builder.into (a_entity.table_name)
			l_keys := l_columns.current_keys
			from i := l_keys.lower until i > l_keys.upper loop
				l_key := l_keys [i]
				l_builder := l_builder.set (l_key, l_columns.item (l_key))
				i := i + 1
			end
			Result := l_builder.execute_returning_id
			if Result > 0 then
				a_entity.set_id (Result)
			end
		ensure
			id_set_on_success: Result > 0 implies a_entity.id = Result
		end

feature -- Command: Update

	update (a_entity: SIMPLE_ORM_ENTITY): BOOLEAN
			-- Update entity by its primary key.
			-- Returns True if exactly one row was updated.
		require
			entity_attached: a_entity /= Void
			entity_persisted: a_entity.is_persisted
		local
			l_columns: HASH_TABLE [detachable ANY, STRING_8]
			l_builder: SIMPLE_SQL_UPDATE_BUILDER
			l_keys: ARRAY [STRING_8]
			l_key: STRING_8
			i: INTEGER
			l_rows_affected: INTEGER
		do
			l_columns := a_entity.to_column_hash
			l_builder := database.update_builder.table (a_entity.table_name)
			l_keys := l_columns.current_keys
			from i := l_keys.lower until i > l_keys.upper loop
				l_key := l_keys [i]
				l_builder := l_builder.set (l_key, l_columns.item (l_key))
				i := i + 1
			end
			l_builder := l_builder.where (a_entity.primary_key_column + " = " + a_entity.id.out)
			l_rows_affected := l_builder.execute
			Result := l_rows_affected = 1
		end

feature -- Command: Save (Insert or Update)

	save (a_entity: SIMPLE_ORM_ENTITY): INTEGER_64
			-- Insert new entity or update existing.
			-- Returns entity ID (new or existing).
		require
			entity_attached: a_entity /= Void
		do
			if a_entity.is_new then
				Result := insert (a_entity)
			else
				if update (a_entity) then
					Result := a_entity.id
				end
			end
		end

feature -- Command: Delete

	delete (a_entity: SIMPLE_ORM_ENTITY): BOOLEAN
			-- Delete entity by primary key.
			-- Returns True if exactly one row was deleted.
		require
			entity_attached: a_entity /= Void
			entity_persisted: a_entity.is_persisted
		local
			l_rows_affected: INTEGER
		do
			l_rows_affected := database.delete_builder
				.from_table (a_entity.table_name)
				.where (a_entity.primary_key_column + " = " + a_entity.id.out)
				.execute
			Result := l_rows_affected = 1
		end

	delete_by_id (a_prototype: SIMPLE_ORM_ENTITY; a_id: INTEGER_64): BOOLEAN
			-- Delete entity by ID.
			-- Returns True if exactly one row was deleted.
		require
			prototype_attached: a_prototype /= Void
			valid_id: a_id > 0
		local
			l_rows_affected: INTEGER
		do
			l_rows_affected := database.delete_builder
				.from_table (a_prototype.table_name)
				.where (a_prototype.primary_key_column + " = " + a_id.out)
				.execute
			Result := l_rows_affected = 1
		end

	delete_where (a_prototype: SIMPLE_ORM_ENTITY; a_conditions: READABLE_STRING_8): INTEGER
			-- Delete all entities matching conditions.
			-- Returns number of rows deleted.
		require
			prototype_attached: a_prototype /= Void
			conditions_not_empty: not a_conditions.is_empty
		do
			Result := database.delete_builder
				.from_table (a_prototype.table_name)
				.where (a_conditions)
				.execute
		ensure
			non_negative: Result >= 0
		end

	delete_all (a_prototype: SIMPLE_ORM_ENTITY): INTEGER
			-- Delete all entities from table (use with caution!).
			-- Returns number of rows deleted.
		require
			prototype_attached: a_prototype /= Void
		do
			database.execute ("DELETE FROM " + a_prototype.table_name)
			Result := database.changes_count
		ensure
			non_negative: Result >= 0
		end

feature -- Status

	has_error: BOOLEAN
			-- Did the last operation cause an error?
		do
			Result := database.has_error
		end

	last_error_message: detachable STRING_32
			-- Error message from last failed operation.
		do
			Result := database.last_error_message
		end

feature {NONE} -- Implementation

	new_entity_from_prototype (a_prototype: SIMPLE_ORM_ENTITY): SIMPLE_ORM_ENTITY
			-- Create new entity instance using prototype's twin.
			-- Entities must implement proper `twin` or provide factory.
		do
			Result := a_prototype.twin
		end

invariant
	database_attached: database /= Void
	database_open: database.is_open

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
