note
	description: "[
		Eager loading support to prevent N+1 query problems.

		Provides a declarative way to specify related data to load in a single query
		or with batched queries, rather than lazy loading each related entity.

		Usage:
			loader := db.eager_loader
			loader.from_table ("documents")
				.include ("comments", "document_id", "id")
				.include ("tags", "document_tags", "document_id", "tag_id")
				.where ("owner_id = 1")

			results := loader.execute
			-- results.main_rows has documents
			-- results.related ("comments") has all comments for those documents
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_EAGER_LOADER

create
	make

feature {NONE} -- Initialization

	make (a_database: SIMPLE_SQL_DATABASE)
			-- Initialize with database connection
		require
			database_not_void: a_database /= Void
			database_open: a_database.is_open
		do
			database := a_database
			create includes.make (5)
			create where_clauses.make (5)
			limit_value := -1
			offset_value := -1
		ensure
			database_set: database = a_database
		end

feature -- Access

	database: SIMPLE_SQL_DATABASE
			-- Database connection

feature -- Configuration

	from_table (a_table: READABLE_STRING_8): like Current
			-- Set the main table to query
		require
			table_not_empty: not a_table.is_empty
		do
			main_table := a_table.to_string_8
			Result := Current
		ensure
			table_set: attached main_table as mt and then mt.same_string (a_table.to_string_8)
		end

	include (a_related_table: READABLE_STRING_8; a_foreign_key: READABLE_STRING_8; a_primary_key: READABLE_STRING_8): like Current
			-- Include related table using direct foreign key relationship
			-- a_related_table: the table to include (e.g., "comments")
			-- a_foreign_key: the foreign key column in related table (e.g., "document_id")
			-- a_primary_key: the primary key column in main table (e.g., "id")
		require
			related_table_not_empty: not a_related_table.is_empty
			foreign_key_not_empty: not a_foreign_key.is_empty
			primary_key_not_empty: not a_primary_key.is_empty
		local
			l_include: TUPLE [table: STRING_8; foreign_key: STRING_8; primary_key: STRING_8; join_table: detachable STRING_8; join_fk: detachable STRING_8]
		do
			l_include := [a_related_table.to_string_8, a_foreign_key.to_string_8, a_primary_key.to_string_8, Void, Void]
			includes.extend (l_include)
			Result := Current
		end

	include_many_to_many (a_related_table: READABLE_STRING_8; a_join_table: READABLE_STRING_8;
			a_main_fk: READABLE_STRING_8; a_related_fk: READABLE_STRING_8): like Current
			-- Include related table via many-to-many join table
			-- a_related_table: the final table to include (e.g., "tags")
			-- a_join_table: the junction table (e.g., "document_tags")
			-- a_main_fk: foreign key in join table to main table (e.g., "document_id")
			-- a_related_fk: foreign key in join table to related table (e.g., "tag_id")
		require
			related_table_not_empty: not a_related_table.is_empty
			join_table_not_empty: not a_join_table.is_empty
			main_fk_not_empty: not a_main_fk.is_empty
			related_fk_not_empty: not a_related_fk.is_empty
		local
			l_include: TUPLE [table: STRING_8; foreign_key: STRING_8; primary_key: STRING_8; join_table: detachable STRING_8; join_fk: detachable STRING_8]
		do
			l_include := [a_related_table.to_string_8, a_main_fk.to_string_8, "id", a_join_table.to_string_8, a_related_fk.to_string_8]
			includes.extend (l_include)
			Result := Current
		end

	where (a_condition: READABLE_STRING_8): like Current
			-- Add WHERE condition for main table
		require
			condition_not_empty: not a_condition.is_empty
		do
			where_clauses.extend (a_condition.to_string_8)
			Result := Current
		end

	limit (a_limit: INTEGER): like Current
			-- Set LIMIT for main table query
		require
			limit_positive: a_limit > 0
		do
			limit_value := a_limit
			Result := Current
		ensure
			limit_set: limit_value = a_limit
		end

	offset (a_offset: INTEGER): like Current
			-- Set OFFSET for main table query
		require
			offset_non_negative: a_offset >= 0
		do
			offset_value := a_offset
			Result := Current
		ensure
			offset_set: offset_value = a_offset
		end

	order_by (a_column: READABLE_STRING_8): like Current
			-- Set ORDER BY for main table
		require
			column_not_empty: not a_column.is_empty
		do
			order_by_column := a_column.to_string_8
			Result := Current
		end

feature -- Status

	has_main_table: BOOLEAN
			-- Has a main table been configured?
		do
			Result := attached main_table as mt and then not mt.is_empty
		end

feature -- Execution

	execute: SIMPLE_SQL_EAGER_RESULT
			-- Execute the eager loading query
			-- Returns main rows plus all related data in a single result object
		require
			has_table: has_main_table
		local
			l_main_sql: STRING_8
			l_main_result: SIMPLE_SQL_RESULT
			l_ids: ARRAYED_LIST [INTEGER_64]
			l_related_results: HASH_TABLE [SIMPLE_SQL_RESULT, STRING_8]
		do
			-- Build and execute main query
			l_main_sql := build_main_query
			l_main_result := database.query (l_main_sql)

			-- Extract primary key IDs from main results
			l_ids := extract_ids (l_main_result, "id")

			-- Execute related queries with batched IN clause
			create l_related_results.make (includes.count)
			if not l_ids.is_empty then
				across includes as ic loop
					l_related_results.put (execute_related_query (ic, l_ids), ic.table)
				end
			end

			create Result.make (l_main_result, l_related_results)
		ensure
			result_not_void: Result /= Void
		end

feature {NONE} -- Implementation

	main_table: detachable STRING_8
			-- Main table to query

	includes: ARRAYED_LIST [TUPLE [table: STRING_8; foreign_key: STRING_8; primary_key: STRING_8; join_table: detachable STRING_8; join_fk: detachable STRING_8]]
			-- Related tables to include

	where_clauses: ARRAYED_LIST [STRING_8]
			-- WHERE conditions

	limit_value: INTEGER
			-- LIMIT value (-1 means not set)

	offset_value: INTEGER
			-- OFFSET value (-1 means not set)

	order_by_column: detachable STRING_8
			-- ORDER BY column

	build_main_query: STRING_8
			-- Build SQL for main table query
		local
			i: INTEGER
		do
			create Result.make (200)
			Result.append ("SELECT * FROM ")
			if attached main_table as mt then
				Result.append (mt)
			end

			-- WHERE clauses
			if not where_clauses.is_empty then
				Result.append (" WHERE ")
				from i := 1 until i > where_clauses.count loop
					if i > 1 then
						Result.append (" AND ")
					end
					Result.append (where_clauses [i])
					i := i + 1
				end
			end

			-- ORDER BY
			if attached order_by_column as obc then
				Result.append (" ORDER BY ")
				Result.append (obc)
			end

			-- LIMIT
			if limit_value > 0 then
				Result.append (" LIMIT ")
				Result.append_integer (limit_value)
			end

			-- OFFSET
			if offset_value > 0 then
				Result.append (" OFFSET ")
				Result.append_integer (offset_value)
			end
		end

	extract_ids (a_result: SIMPLE_SQL_RESULT; a_column: STRING_8): ARRAYED_LIST [INTEGER_64]
			-- Extract ID values from result set
		do
			create Result.make (a_result.rows.count)
			across a_result.rows as ic loop
				Result.extend (ic.integer_64_value (a_column))
			end
		end

	execute_related_query (a_include: TUPLE [table: STRING_8; foreign_key: STRING_8; primary_key: STRING_8; join_table: detachable STRING_8; join_fk: detachable STRING_8]; a_ids: ARRAYED_LIST [INTEGER_64]): SIMPLE_SQL_RESULT
			-- Execute query for related table using IN clause with IDs
		local
			l_sql: STRING_8
			l_in_clause: STRING_8
			l_first: BOOLEAN
		do
			-- Build IN clause
			create l_in_clause.make (a_ids.count * 5)
			l_first := True
			across a_ids as ic loop
				if not l_first then
					l_in_clause.append (", ")
				end
				l_in_clause.append (ic.out)
				l_first := False
			end

			if attached a_include.join_table as jt and then attached a_include.join_fk as jfk then
				-- Many-to-many: SELECT t.*, jt.main_fk FROM related t JOIN junction jt ON ...
				create l_sql.make (200)
				l_sql.append ("SELECT ")
				l_sql.append (a_include.table)
				l_sql.append (".*, ")
				l_sql.append (jt)
				l_sql.append (".")
				l_sql.append (a_include.foreign_key)
				l_sql.append (" AS _eager_fk FROM ")
				l_sql.append (a_include.table)
				l_sql.append (" JOIN ")
				l_sql.append (jt)
				l_sql.append (" ON ")
				l_sql.append (a_include.table)
				l_sql.append (".id = ")
				l_sql.append (jt)
				l_sql.append (".")
				l_sql.append (jfk)
				l_sql.append (" WHERE ")
				l_sql.append (jt)
				l_sql.append (".")
				l_sql.append (a_include.foreign_key)
				l_sql.append (" IN (")
				l_sql.append (l_in_clause)
				l_sql.append (")")
			else
				-- Direct foreign key relationship
				create l_sql.make (200)
				l_sql.append ("SELECT *, ")
				l_sql.append (a_include.foreign_key)
				l_sql.append (" AS _eager_fk FROM ")
				l_sql.append (a_include.table)
				l_sql.append (" WHERE ")
				l_sql.append (a_include.foreign_key)
				l_sql.append (" IN (")
				l_sql.append (l_in_clause)
				l_sql.append (")")
			end

			Result := database.query (l_sql)
		end

invariant
	database_attached: database /= Void

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
