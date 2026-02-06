note
	description: "[
		FTS5 Full-Text Search virtual table management.

		Provides high-level API for creating and managing SQLite FTS5 virtual tables
		for full-text search capabilities.

		Usage:
			fts := db.fts5
			fts.create_table ("documents_fts", <<"title", "body", "author">>)
			fts.insert ("documents_fts", <<"title", "body", "author">>, <<"My Title", "Content here", "John">>)

			-- Search
			results := fts.search ("documents_fts", "content")
			results := fts.search_ranked ("documents_fts", "content", 10)
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_FTS5

create
	make

feature {NONE} -- Initialization

	make (a_database: SIMPLE_SQL_DATABASE)
			-- Create FTS5 manager for database
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

feature -- Status

	table_exists (a_table: READABLE_STRING_8): BOOLEAN
			-- Does FTS5 virtual table exist?
		require
			table_not_empty: not a_table.is_empty
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query (
				"SELECT 1 FROM sqlite_master WHERE type='table' AND name='" +
				a_table.to_string_8 + "' AND sql LIKE '%%fts5%%'"
			)
			Result := not l_result.is_empty
		end

	is_fts5_available: BOOLEAN
			-- Is FTS5 extension available in this SQLite build?
		require
			database_open: database.is_open
		local
			l_result: SIMPLE_SQL_RESULT
			l_option: STRING_32
		do
			-- Check compile options for ENABLE_FTS5
			l_result := database.query ("PRAGMA compile_options")
			across l_result.rows as ic loop
				if attached ic.item (1) as al_l_val then
					-- Convert any type to string and check
					create l_option.make_from_string (al_l_val.out)
					l_option.to_upper
					if l_option.has_substring ("FTS5") or l_option.has_substring ("ENABLE_FTS5") then
						Result := True
					end
				end
			end
		end

feature -- Table Management

	create_table (a_table: READABLE_STRING_8; a_columns: ARRAY [READABLE_STRING_8])
			-- Create FTS5 virtual table with specified columns
		require
			fts5_available: is_fts5_available
			table_not_empty: not a_table.is_empty
			columns_not_empty: not a_columns.is_empty
			table_not_exists: not table_exists (a_table)
		local
			l_sql: STRING_8
			i: INTEGER
		do
			create l_sql.make (100)
			l_sql.append ("CREATE VIRTUAL TABLE ")
			l_sql.append (a_table.to_string_8)
			l_sql.append (" USING fts5(")

			from i := a_columns.lower until i > a_columns.upper loop
				if i > a_columns.lower then
					l_sql.append (", ")
				end
				l_sql.append (a_columns[i].to_string_8)
				i := i + 1
			end

			l_sql.append (")")
			database.execute (l_sql)
		ensure
			table_created: not database.has_error implies table_exists (a_table)
		end

	create_table_with_options (a_table: READABLE_STRING_8; a_columns: ARRAY [READABLE_STRING_8]; a_options: READABLE_STRING_8)
			-- Create FTS5 virtual table with columns and additional options
			-- Options can include: tokenize, prefix, content, content_rowid, columnsize, detail
		require
			fts5_available: is_fts5_available
			table_not_empty: not a_table.is_empty
			columns_not_empty: not a_columns.is_empty
		local
			l_sql: STRING_8
			i: INTEGER
		do
			create l_sql.make (150)
			l_sql.append ("CREATE VIRTUAL TABLE ")
			l_sql.append (a_table.to_string_8)
			l_sql.append (" USING fts5(")

			from i := a_columns.lower until i > a_columns.upper loop
				if i > a_columns.lower then
					l_sql.append (", ")
				end
				l_sql.append (a_columns[i].to_string_8)
				i := i + 1
			end

			if not a_options.is_empty then
				l_sql.append (", ")
				l_sql.append (a_options.to_string_8)
			end

			l_sql.append (")")
			database.execute (l_sql)
		end

	create_external_content_table (a_table: READABLE_STRING_8; a_columns: ARRAY [READABLE_STRING_8]; a_content_table: READABLE_STRING_8; a_content_rowid: READABLE_STRING_8)
			-- Create FTS5 table that indexes content from another table (external content)
			-- This saves space by not duplicating the content
		require
			fts5_available: is_fts5_available
			table_not_empty: not a_table.is_empty
			columns_not_empty: not a_columns.is_empty
			content_table_not_empty: not a_content_table.is_empty
			content_rowid_not_empty: not a_content_rowid.is_empty
		local
			l_sql: STRING_8
			i: INTEGER
		do
			create l_sql.make (200)
			l_sql.append ("CREATE VIRTUAL TABLE ")
			l_sql.append (a_table.to_string_8)
			l_sql.append (" USING fts5(")

			from i := a_columns.lower until i > a_columns.upper loop
				if i > a_columns.lower then
					l_sql.append (", ")
				end
				l_sql.append (a_columns[i].to_string_8)
				i := i + 1
			end

			l_sql.append (", content='")
			l_sql.append (a_content_table.to_string_8)
			l_sql.append ("', content_rowid='")
			l_sql.append (a_content_rowid.to_string_8)
			l_sql.append ("')")

			database.execute (l_sql)
		end

	drop_table (a_table: READABLE_STRING_8)
			-- Drop FTS5 virtual table
		require
			table_not_empty: not a_table.is_empty
		do
			database.execute ("DROP TABLE IF EXISTS " + a_table.to_string_8)
		ensure
			table_dropped: not database.has_error implies not table_exists (a_table)
		end

feature -- Data Operations

	insert (a_table: READABLE_STRING_8; a_columns: ARRAY [READABLE_STRING_8]; a_values: ARRAY [detachable ANY])
			-- Insert row into FTS5 table
		require
			table_not_empty: not a_table.is_empty
			columns_not_empty: not a_columns.is_empty
			values_match_columns: a_values.count = a_columns.count
		local
			l_sql: STRING_8
			i: INTEGER
		do
			create l_sql.make (200)
			l_sql.append ("INSERT INTO ")
			l_sql.append (a_table.to_string_8)
			l_sql.append (" (")

			from i := a_columns.lower until i > a_columns.upper loop
				if i > a_columns.lower then
					l_sql.append (", ")
				end
				l_sql.append (a_columns[i].to_string_8)
				i := i + 1
			end

			l_sql.append (") VALUES (")

			from i := a_values.lower until i > a_values.upper loop
				if i > a_values.lower then
					l_sql.append (", ")
				end
				l_sql.append (value_to_sql (a_values[i]))
				i := i + 1
			end

			l_sql.append (")")
			database.execute (l_sql)
		end

	delete (a_table: READABLE_STRING_8; a_rowid: INTEGER_64)
			-- Delete row from FTS5 table by rowid
		require
			table_not_empty: not a_table.is_empty
		do
			database.execute ("DELETE FROM " + a_table.to_string_8 + " WHERE rowid = " + a_rowid.out)
		end

	rebuild (a_table: READABLE_STRING_8)
			-- Rebuild FTS5 index (useful after bulk operations or to optimize)
		require
			fts5_available: is_fts5_available
			table_not_empty: not a_table.is_empty
		do
			database.execute ("INSERT INTO " + a_table.to_string_8 + "(" + a_table.to_string_8 + ") VALUES('rebuild')")
		end

	optimize (a_table: READABLE_STRING_8)
			-- Optimize FTS5 index (merge all b-tree segments)
		require
			fts5_available: is_fts5_available
			table_not_empty: not a_table.is_empty
		do
			database.execute ("INSERT INTO " + a_table.to_string_8 + "(" + a_table.to_string_8 + ") VALUES('optimize')")
		end

feature -- Searching

	search (a_table: READABLE_STRING_8; a_query: READABLE_STRING_8): SIMPLE_SQL_RESULT
			-- Search FTS5 table with query, return all matching rows
		require
			fts5_available: is_fts5_available
			table_not_empty: not a_table.is_empty
			query_not_empty: not a_query.is_empty
		do
			Result := database.query (
				"SELECT * FROM " + a_table.to_string_8 +
				" WHERE " + a_table.to_string_8 + " MATCH '" + escaped_fts_query (a_query) + "'"
			)
		end

	search_ranked (a_table: READABLE_STRING_8; a_query: READABLE_STRING_8; a_limit: INTEGER): SIMPLE_SQL_RESULT
			-- Search FTS5 table with BM25 ranking, return top results
		require
			fts5_available: is_fts5_available
			table_not_empty: not a_table.is_empty
			query_not_empty: not a_query.is_empty
			limit_positive: a_limit > 0
		do
			Result := database.query (
				"SELECT *, bm25(" + a_table.to_string_8 + ") as rank FROM " + a_table.to_string_8 +
				" WHERE " + a_table.to_string_8 + " MATCH '" + escaped_fts_query (a_query) + "'" +
				" ORDER BY rank LIMIT " + a_limit.out
			)
		end

	search_column (a_table: READABLE_STRING_8; a_column: READABLE_STRING_8; a_query: READABLE_STRING_8): SIMPLE_SQL_RESULT
			-- Search specific column in FTS5 table
		require
			fts5_available: is_fts5_available
			table_not_empty: not a_table.is_empty
			column_not_empty: not a_column.is_empty
			query_not_empty: not a_query.is_empty
		do
			Result := database.query (
				"SELECT * FROM " + a_table.to_string_8 +
				" WHERE " + a_column.to_string_8 + " MATCH '" + escaped_fts_query (a_query) + "'"
			)
		end

	search_with_snippets (a_table: READABLE_STRING_8; a_query: READABLE_STRING_8; a_column: READABLE_STRING_8; a_limit: INTEGER): SIMPLE_SQL_RESULT
			-- Search with highlighted snippets showing match context
		require
			fts5_available: is_fts5_available
			table_not_empty: not a_table.is_empty
			query_not_empty: not a_query.is_empty
			column_not_empty: not a_column.is_empty
			limit_positive: a_limit > 0
		do
			Result := database.query (
				"SELECT *, snippet(" + a_table.to_string_8 + ", " +
				column_index (a_table, a_column).out + ", '<b>', '</b>', '...', 32) as snippet, " +
				"bm25(" + a_table.to_string_8 + ") as rank FROM " + a_table.to_string_8 +
				" WHERE " + a_table.to_string_8 + " MATCH '" + escaped_fts_query (a_query) + "'" +
				" ORDER BY rank LIMIT " + a_limit.out
			)
		end

	count_matches (a_table: READABLE_STRING_8; a_query: READABLE_STRING_8): INTEGER
			-- Count number of matching rows
		require
			fts5_available: is_fts5_available
			table_not_empty: not a_table.is_empty
			query_not_empty: not a_query.is_empty
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query (
				"SELECT COUNT(*) as cnt FROM " + a_table.to_string_8 +
				" WHERE " + a_table.to_string_8 + " MATCH '" + escaped_fts_query (a_query) + "'"
			)
			if not l_result.is_empty and then attached l_result.first as al_l_row then
				Result := al_l_row.integer_value ("cnt")
			end
		end

feature -- Query Builder

	query_builder (a_table: READABLE_STRING_8): SIMPLE_SQL_FTS5_QUERY
			-- Create fluent query builder for FTS5 searches
		require
			fts5_available: is_fts5_available
			table_not_empty: not a_table.is_empty
		do
			create Result.make (database, a_table)
		ensure
			result_attached: Result /= Void
		end

feature {NONE} -- Implementation

	escaped_fts_query (a_query: READABLE_STRING_8): STRING_8
			-- Escape special characters in FTS5 query
			-- For queries with apostrophes, wrap in double quotes for phrase matching
		local
			i: INTEGER
			c: CHARACTER
			l_has_apostrophe: BOOLEAN
		do
			-- Check if query contains apostrophe
			across a_query as ic loop
				if ic.item = '%'' then
					l_has_apostrophe := True
				end
			end

			create Result.make (a_query.count + 10)

			if l_has_apostrophe then
				-- Use double-quote phrase matching for apostrophes
				Result.append_character ('"')
				from i := 1 until i > a_query.count loop
					c := a_query.item (i)
					if c = '"' then
						-- Escape double quotes by doubling for FTS5
						Result.append_character ('"')
						Result.append_character ('"')
					elseif c = '%'' then
						-- Escape single quotes for SQL string literal
						Result.append_character ('%'')
						Result.append_character (c)
					else
						Result.append_character (c)
					end
					i := i + 1
				end
				Result.append_character ('"')
			else
				-- Standard escaping for SQL string literals
				from i := 1 until i > a_query.count loop
					c := a_query.item (i)
					inspect c
					when '%'', '"' then
						Result.append_character ('%'')
						Result.append_character (c)
					else
						Result.append_character (c)
					end
					i := i + 1
				end
			end
		end

	value_to_sql (a_value: detachable ANY): STRING_8
			-- Convert value to SQL literal
		do
			if a_value = Void then
				Result := "NULL"
			elseif attached {READABLE_STRING_GENERAL} a_value as al_l_str then
				Result := "'" + escaped_string (al_l_str) + "'"
			elseif attached {INTEGER_64} a_value as al_l_int then
				Result := al_l_int.out
			elseif attached {INTEGER_32} a_value as al_l_int then
				Result := al_l_int.out
			elseif attached {REAL_64} a_value as al_l_real then
				Result := al_l_real.out
			else
				Result := "'" + escaped_string (a_value.out) + "'"
			end
		end

	escaped_string (a_string: READABLE_STRING_GENERAL): STRING_8
			-- Escape string for SQL
		local
			i: INTEGER
			c: CHARACTER_32
		do
			create Result.make (a_string.count + 10)
			from i := 1 until i > a_string.count loop
				c := a_string.item (i)
				if c = {CHARACTER_32} '%'' then
					Result.append ("''")
				else
					Result.append_character (c.to_character_8)
				end
				i := i + 1
			end
		end

	column_index (a_table: READABLE_STRING_8; a_column: READABLE_STRING_8): INTEGER
			-- Get 0-based index of column in FTS5 table
		local
			l_result: SIMPLE_SQL_RESULT
			l_name: STRING_32
		do
			l_result := database.query ("PRAGMA table_info('" + a_table.to_string_8 + "')")
			across l_result.rows as ic loop
				l_name := ic.string_value ("l_name")
				if l_name.same_string (a_column.to_string_32) then
					Result := ic.integer_value ("cid")
				end
			end
		end

invariant
	database_attached: database /= Void

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
