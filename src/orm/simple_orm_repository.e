note
	description: "[
		Generic ORM repository that works with SIMPLE_ORM_ENTITY subclasses.

		Provides typed CRUD operations using entity metadata for automatic
		column mapping. Much less boilerplate than SIMPLE_SQL_REPOSITORY.

		Usage:
			class USER_REPO inherit SIMPLE_ORM_REPOSITORY [USER]
			create make
			feature
				new_entity: USER
					do create Result.make_default end
			end

			-- Then use:
			repo := create {USER_REPO}.make (database)
			repo.create_table
			user := repo.find_by_id (42)
			all_users := repo.find_all
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	SIMPLE_ORM_REPOSITORY [G -> SIMPLE_ORM_ENTITY]

feature {NONE} -- Initialization

	make (a_database: SIMPLE_SQL_DATABASE)
			-- Create repository with database connection.
		require
			database_open: a_database.is_open
		do
			database := a_database
			create orm.make (a_database)
		ensure
			database_set: database = a_database
		end

feature -- Access

	database: SIMPLE_SQL_DATABASE
			-- Database connection.

	orm: SIMPLE_ORM
			-- ORM instance for this repository.

feature -- Factory

	new_entity: G
			-- Create a new default entity instance.
			-- Must be implemented by concrete repository.
		deferred
		end

feature -- Schema

	create_table
			-- Create table for this entity type if it doesn't exist.
		do
			orm.create_table (new_entity)
		end

	drop_table
			-- Drop table for this entity type if it exists.
		do
			orm.drop_table (new_entity)
		end

	table_exists: BOOLEAN
			-- Does table for this entity type exist?
		do
			Result := orm.table_exists (new_entity)
		end

	table_name: STRING_8
			-- Name of the database table.
		do
			Result := new_entity.table_name
		end

	primary_key_column: STRING_8
			-- Name of the primary key column.
		do
			Result := new_entity.primary_key_column
		end

feature -- Query: All

	find_all: ARRAYED_LIST [G]
			-- Find all entities.
		local
			l_list: ARRAYED_LIST [SIMPLE_ORM_ENTITY]
		do
			l_list := orm.find_all (new_entity)
			create Result.make (l_list.count)
			across l_list as ic loop
				if attached {G} ic as l_entity then
					Result.extend (l_entity)
				end
			end
		end

	find_all_ordered (a_order_by: READABLE_STRING_8): ARRAYED_LIST [G]
			-- Find all entities ordered by column(s).
		require
			order_not_empty: not a_order_by.is_empty
		local
			l_list: ARRAYED_LIST [SIMPLE_ORM_ENTITY]
		do
			l_list := orm.find_all_ordered (new_entity, a_order_by)
			create Result.make (l_list.count)
			across l_list as ic loop
				if attached {G} ic as l_entity then
					Result.extend (l_entity)
				end
			end
		end

	find_all_limited (a_limit, a_offset: INTEGER): ARRAYED_LIST [G]
			-- Find entities with pagination.
		require
			positive_limit: a_limit > 0
			non_negative_offset: a_offset >= 0
		local
			l_list: ARRAYED_LIST [SIMPLE_ORM_ENTITY]
		do
			l_list := orm.find_all_limited (new_entity, a_limit, a_offset)
			create Result.make (l_list.count)
			across l_list as ic loop
				if attached {G} ic as l_entity then
					Result.extend (l_entity)
				end
			end
		ensure
			respects_limit: Result.count <= a_limit
		end

feature -- Query: By ID

	find_by_id (a_id: INTEGER_64): detachable G
			-- Find entity by primary key, or Void if not found.
		require
			valid_id: a_id > 0
		do
			if attached orm.find_by_id (new_entity, a_id) as l_entity then
				if attached {G} l_entity as l_result then
					Result := l_result
				end
			end
		end

	exists (a_id: INTEGER_64): BOOLEAN
			-- Does an entity with this ID exist?
		require
			valid_id: a_id > 0
		do
			Result := orm.exists (new_entity, a_id)
		end

feature -- Query: Conditional

	find_where (a_conditions: READABLE_STRING_8): ARRAYED_LIST [G]
			-- Find all entities matching conditions.
		require
			conditions_not_empty: not a_conditions.is_empty
		local
			l_list: ARRAYED_LIST [SIMPLE_ORM_ENTITY]
		do
			l_list := orm.find_where (new_entity, a_conditions)
			create Result.make (l_list.count)
			across l_list as ic loop
				if attached {G} ic as l_entity then
					Result.extend (l_entity)
				end
			end
		end

	find_first_where (a_conditions: READABLE_STRING_8): detachable G
			-- Find first entity matching conditions.
		require
			conditions_not_empty: not a_conditions.is_empty
		do
			if attached orm.find_first_where (new_entity, a_conditions) as l_entity then
				if attached {G} l_entity as l_result then
					Result := l_result
				end
			end
		end

feature -- Query: Counting

	count: INTEGER
			-- Total count of entities.
		do
			Result := orm.count (new_entity)
		ensure
			non_negative: Result >= 0
		end

	count_where (a_conditions: READABLE_STRING_8): INTEGER
			-- Count of entities matching conditions.
		require
			conditions_not_empty: not a_conditions.is_empty
		do
			Result := orm.count_where (new_entity, a_conditions)
		ensure
			non_negative: Result >= 0
		end

feature -- Command: Insert

	insert (a_entity: G): INTEGER_64
			-- Insert entity and return new primary key.
		require
			entity_is_new: a_entity.is_new
		do
			Result := orm.insert (a_entity)
		ensure
			id_set_on_success: Result > 0 implies a_entity.id = Result
		end

feature -- Command: Update

	update (a_entity: G): BOOLEAN
			-- Update entity by its primary key.
		require
			entity_persisted: a_entity.is_persisted
		do
			Result := orm.update (a_entity)
		end

feature -- Command: Save

	save (a_entity: G): INTEGER_64
			-- Insert new entity or update existing.
		do
			Result := orm.save (a_entity)
		end

feature -- Command: Delete

	delete (a_entity: G): BOOLEAN
			-- Delete entity by primary key.
		require
			entity_persisted: a_entity.is_persisted
		do
			Result := orm.delete (a_entity)
		end

	delete_by_id (a_id: INTEGER_64): BOOLEAN
			-- Delete entity by ID.
		require
			valid_id: a_id > 0
		do
			Result := orm.delete_by_id (new_entity, a_id)
		end

	delete_where (a_conditions: READABLE_STRING_8): INTEGER
			-- Delete all entities matching conditions.
		require
			conditions_not_empty: not a_conditions.is_empty
		do
			Result := orm.delete_where (new_entity, a_conditions)
		ensure
			non_negative: Result >= 0
		end

	delete_all: INTEGER
			-- Delete all entities (use with caution!).
		do
			Result := orm.delete_all (new_entity)
		ensure
			non_negative: Result >= 0
		end

feature -- Status

	has_error: BOOLEAN
			-- Did the last operation cause an error?
		do
			Result := orm.has_error
		end

	last_error_message: detachable STRING_32
			-- Error message from last failed operation.
		do
			Result := orm.last_error_message
		end

invariant
	database_attached: database /= Void
	database_open: database.is_open
	orm_attached: orm /= Void

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
