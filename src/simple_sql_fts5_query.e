note
	description: "[
		Fluent builder for constructing FTS5 full-text search queries.
		Chains MATCH expressions, BM25 ranking, snippet/highlight options,
		ordering, and pagination into executable SQL.
		Provides the query-composition layer for simple_sql full-text search.
	]"
	purpose: "Build and execute FTS5 queries with MATCH, ranking, and snippets"
	collaborators: "SIMPLE_SQL_DATABASE, SIMPLE_SQL_FTS5, SIMPLE_SQL_RESULT, SIMPLE_SQL_CURSOR"
	design_pattern: "Builder"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_FTS5_QUERY

create
	make

feature {NONE} -- Initialization

	make (a_database: SIMPLE_SQL_DATABASE; a_table: READABLE_STRING_8)
			-- Create FTS5 query builder for table
		note
			semantic_role: "[
				Captures database and table references
				and initializes empty builder
				collections.
			]"
		require
			database_open: a_database.is_open
			table_not_empty: not a_table.is_empty
		do
			database := a_database
			table_name := a_table.to_string_8
			create select_columns.make (5)
			create match_expressions.make (3)
			create order_clauses.make (2)
			include_all_columns := True
		ensure
			database_set: database = a_database
			table_set: table_name ~ a_table.to_string_8
		end

feature -- Access

	database: SIMPLE_SQL_DATABASE
			-- Database connection

	table_name: STRING_8
			-- FTS5 table to query

feature -- Query Building - Match

	match (a_query: READABLE_STRING_8): like Current
			-- Add MATCH expression for entire table
		note
			semantic_role: "[
				Appends a table-wide MATCH expression
				to the query.
			]"
		require
			query_not_empty: not a_query.is_empty
		do
			match_expressions.extend ([Void, a_query.to_string_8])
			Result := Current
		ensure
			match_added: match_expressions.count = old match_expressions.count + 1
		end

	match_column (a_column: READABLE_STRING_8; a_query: READABLE_STRING_8): like Current
			-- Add MATCH expression for specific column
		note
			semantic_role: "[
				Appends a column-scoped MATCH
				expression to the query.
			]"
		require
			column_not_empty: not a_column.is_empty
			query_not_empty: not a_query.is_empty
		do
			match_expressions.extend ([a_column.to_string_8, a_query.to_string_8])
			Result := Current
		ensure
			match_added: match_expressions.count = old match_expressions.count + 1
		end

	match_phrase (a_phrase: READABLE_STRING_8): like Current
			-- Add phrase MATCH (exact phrase in quotes)
		note
			semantic_role: "[
				Wraps the phrase in double quotes for
				FTS5 exact phrase matching.
			]"
		require
			phrase_not_empty: not a_phrase.is_empty
		do
			match_expressions.extend ([Void, "%"" + a_phrase.to_string_8 + "%""])
			Result := Current
		end

	match_prefix (a_prefix: READABLE_STRING_8): like Current
			-- Add prefix MATCH (word starting with prefix)
		note
			semantic_role: "[
				Appends an FTS5 prefix query with
				trailing asterisk.
			]"
		require
			prefix_not_empty: not a_prefix.is_empty
		do
			match_expressions.extend ([Void, a_prefix.to_string_8 + "*"])
			Result := Current
		end

	match_near (a_term1, a_term2: READABLE_STRING_8; a_distance: INTEGER): like Current
			-- Add NEAR match (terms within distance of each other)
		note
			semantic_role: "[
				Constructs an FTS5 NEAR() proximity
				expression.
			]"
		require
			term1_not_empty: not a_term1.is_empty
			term2_not_empty: not a_term2.is_empty
			distance_positive: a_distance >= 0
		do
			match_expressions.extend ([Void, "NEAR(" + a_term1.to_string_8 + " " + a_term2.to_string_8 + ", " + a_distance.out + ")"])
			Result := Current
		end

	match_boolean (a_expression: READABLE_STRING_8): like Current
			-- Add boolean MATCH expression (AND, OR, NOT operators)
			-- Example: "sqlite AND database NOT tutorial"
		note
			semantic_role: "[
				Passes a raw FTS5 boolean expression
				through to MATCH.
			]"
		require
			expression_not_empty: not a_expression.is_empty
		do
			match_expressions.extend ([Void, a_expression.to_string_8])
			Result := Current
		end

feature -- Query Building - Select

	select_column (a_column: READABLE_STRING_8): like Current
			-- Add column to SELECT
		note
			semantic_role: "[
				Adds a single column to the explicit
				SELECT list.
			]"
		require
			column_not_empty: not a_column.is_empty
		do
			include_all_columns := False
			select_columns.extend (a_column.to_string_8)
			Result := Current
		end

	select_columns_list (a_columns: ARRAY [READABLE_STRING_8]): like Current
			-- Add multiple columns to SELECT
		note
			semantic_role: "[
				Adds multiple columns to the explicit
				SELECT list.
			]"
		require
			columns_not_empty: not a_columns.is_empty
		local
			i: INTEGER
		do
			include_all_columns := False
			from i := a_columns.lower until i > a_columns.upper loop
				select_columns.extend (a_columns[i].to_string_8)
				i := i + 1
			end
			Result := Current
		end

feature -- Query Building - Ranking and Snippets

	with_rank: like Current
			-- Include BM25 rank score in results
		note
			semantic_role: "[
				Enables BM25 rank column in SELECT
				output.
			]"
		do
			include_rank := True
			Result := Current
		ensure
			rank_enabled: include_rank
		end

	with_rank_weights (a_weights: ARRAY [REAL_64]): like Current
			-- Include BM25 rank with custom column weights
			-- Higher weight = more important column
		note
			semantic_role: "[
				Enables BM25 rank with per-column
				weight configuration.
			]"
		require
			weights_not_empty: not a_weights.is_empty
		do
			include_rank := True
			create rank_weights.make_from_array (a_weights)
			Result := Current
		end

	with_snippets (a_column: READABLE_STRING_8; a_start_tag, a_end_tag: READABLE_STRING_8): like Current
			-- Include snippet with highlighted matches
		note
			semantic_role: "[
				Configures snippet() output with
				default token limit.
			]"
		require
			column_not_empty: not a_column.is_empty
		do
			snippet_column := a_column.to_string_8
			snippet_start_tag := a_start_tag.to_string_8
			snippet_end_tag := a_end_tag.to_string_8
			snippet_max_tokens := 64
			Result := Current
		ensure
			snippets_enabled: snippet_column /= Void
		end

	with_snippets_config (a_column: READABLE_STRING_8; a_start_tag, a_end_tag, a_ellipsis: READABLE_STRING_8; a_max_tokens: INTEGER): like Current
			-- Include snippet with full configuration
		note
			semantic_role: "[
				Configures snippet() output with custom
				ellipsis and token limit.
			]"
		require
			column_not_empty: not a_column.is_empty
			max_tokens_positive: a_max_tokens > 0
		do
			snippet_column := a_column.to_string_8
			snippet_start_tag := a_start_tag.to_string_8
			snippet_end_tag := a_end_tag.to_string_8
			snippet_ellipsis := a_ellipsis.to_string_8
			snippet_max_tokens := a_max_tokens
			Result := Current
		end

	with_highlight (a_column: READABLE_STRING_8; a_start_tag, a_end_tag: READABLE_STRING_8): like Current
			-- Include full column content with highlighted matches
		note
			semantic_role: "[
				Configures highlight() for full-column
				match highlighting.
			]"
		require
			column_not_empty: not a_column.is_empty
		do
			highlight_column := a_column.to_string_8
			highlight_start_tag := a_start_tag.to_string_8
			highlight_end_tag := a_end_tag.to_string_8
			Result := Current
		ensure
			highlight_enabled: highlight_column /= Void
		end

feature -- Query Building - Ordering

	order_by_rank: like Current
			-- Order results by BM25 rank (best matches first)
		note
			semantic_role: "[
				Enables BM25 ranking and adds rank
				to ORDER BY.
			]"
		do
			include_rank := True
			order_clauses.extend ("rank")
			Result := Current
		end

	order_by (a_column: READABLE_STRING_8): like Current
			-- Order by column ascending
		note
			semantic_role: "[
				Appends an ascending ORDER BY clause.
			]"
		require
			column_not_empty: not a_column.is_empty
		do
			order_clauses.extend (a_column.to_string_8)
			Result := Current
		end

	order_by_desc (a_column: READABLE_STRING_8): like Current
			-- Order by column descending
		note
			semantic_role: "[
				Appends a descending ORDER BY clause.
			]"
		require
			column_not_empty: not a_column.is_empty
		do
			order_clauses.extend (a_column.to_string_8 + " DESC")
			Result := Current
		end

feature -- Query Building - Limit/Offset

	limit (a_count: INTEGER): like Current
			-- Limit number of results
		note
			semantic_role: "[
				Sets the LIMIT clause for result count
				restriction.
			]"
		require
			count_positive: a_count > 0
		do
			limit_count := a_count
			Result := Current
		ensure
			limit_set: limit_count = a_count
		end

	offset (a_offset: INTEGER): like Current
			-- Skip first N results
		note
			semantic_role: "[
				Sets the OFFSET clause for result
				pagination.
			]"
		require
			offset_non_negative: a_offset >= 0
		do
			offset_count := a_offset
			Result := Current
		ensure
			offset_set: offset_count = a_offset
		end

feature -- Execution

	execute: SIMPLE_SQL_RESULT
			-- Execute query and return results
		note
			semantic_role: "[
				Generates SQL from builder state and
				executes via database query.
			]"
		require
			has_match: not match_expressions.is_empty
		do
			Result := database.query (to_sql)
		end

	execute_cursor: SIMPLE_SQL_CURSOR
			-- Execute query returning lazy cursor
		note
			semantic_role: "[
				Generates SQL and returns a lazy cursor
				for streaming results.
			]"
		require
			has_match: not match_expressions.is_empty
		do
			Result := database.query_cursor (to_sql)
		end

	count: INTEGER
			-- Execute COUNT query
		note
			semantic_role: "[
				Generates COUNT SQL and extracts the
				integer result.
			]"
		require
			has_match: not match_expressions.is_empty
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query (to_count_sql)
			if not l_result.is_empty and then attached l_result.first as al_l_row then
				Result := al_l_row.integer_value ("cnt")
			end
		end

feature -- SQL Generation

	to_sql: STRING_8
			-- Generate SQL query string
		note
			semantic_role: "[
				Assembles the full SELECT...FROM...
				WHERE MATCH...ORDER BY...LIMIT SQL.
			]"
		require
			has_match: not match_expressions.is_empty
		do
			create Result.make (200)
			Result.append ("SELECT ")
			append_select_clause (Result)
			Result.append (" FROM ")
			Result.append (table_name)
			Result.append (" WHERE ")
			append_match_clause (Result)
			append_order_clause (Result)
			append_limit_clause (Result)
		end

	to_count_sql: STRING_8
			-- Generate COUNT SQL query string
		note
			semantic_role: "[
				Assembles a COUNT(*) query with the
				same MATCH clause.
			]"
		require
			has_match: not match_expressions.is_empty
		do
			create Result.make (100)
			Result.append ("SELECT COUNT(*) as cnt FROM ")
			Result.append (table_name)
			Result.append (" WHERE ")
			append_match_clause (Result)
		end

feature -- Model Queries

	select_columns_model: MML_SEQUENCE [STRING_8]
			-- Mathematical model of selected columns in order.
		note
			semantic_role: "[
				Provides an MML sequence model of
				selected columns for contract
				verification.
			]"
		do
			create Result
			across select_columns as ic loop
				Result := Result & ic
			end
		ensure
			count_matches: Result.count = select_columns.count
		end

	match_expressions_model: MML_SEQUENCE [TUPLE [column: detachable STRING_8; query: STRING_8]]
			-- Mathematical model of MATCH expressions in order.
		note
			semantic_role: "[
				Provides an MML sequence model of
				MATCH expressions for contract
				verification.
			]"
		do
			create Result
			across match_expressions as ic loop
				Result := Result & ic
			end
		ensure
			count_matches: Result.count = match_expressions.count
		end

	order_clauses_model: MML_SEQUENCE [STRING_8]
			-- Mathematical model of ORDER BY clauses in order.
		note
			semantic_role: "[
				Provides an MML sequence model of
				ORDER BY clauses for contract
				verification.
			]"
		do
			create Result
			across order_clauses as ic loop
				Result := Result & ic
			end
		ensure
			count_matches: Result.count = order_clauses.count
		end

feature -- Implementation

	select_columns: ARRAYED_LIST [STRING_8]
			-- Columns to select

	match_expressions: ARRAYED_LIST [TUPLE [column: detachable STRING_8; query: STRING_8]]
			-- MATCH expressions (column can be Void for table-wide match)

	order_clauses: ARRAYED_LIST [STRING_8]
			-- ORDER BY clauses

	include_all_columns: BOOLEAN
			-- Include all columns in select?

	include_rank: BOOLEAN
			-- Include BM25 rank?

	rank_weights: detachable ARRAY [REAL_64]
			-- Custom BM25 weights per column

	snippet_column: detachable STRING_8
			-- Column for snippet generation

	snippet_start_tag: detachable STRING_8
			-- Snippet highlight start tag

	snippet_end_tag: detachable STRING_8
			-- Snippet highlight end tag

	snippet_ellipsis: detachable STRING_8
			-- Snippet ellipsis string

	snippet_max_tokens: INTEGER
			-- Maximum tokens in snippet

	highlight_column: detachable STRING_8
			-- Column for full highlight

	highlight_start_tag: detachable STRING_8
			-- Highlight start tag

	highlight_end_tag: detachable STRING_8
			-- Highlight end tag

	limit_count: INTEGER
			-- LIMIT value (0 = no limit)

	offset_count: INTEGER
			-- OFFSET value

	append_select_clause (a_sql: STRING_8)
			-- Append SELECT columns to SQL
		note
			semantic_role: "[
				Builds SELECT clause with optional
				rank, snippet, and highlight
				expressions.
			]"
		local
			l_col_idx, idx: INTEGER
		do
			if include_all_columns and select_columns.is_empty then
				a_sql.append ("*")
			else
				across
					select_columns as ic
				from
					idx := 1
				loop
					if idx > 1 then
						a_sql.append (", ")
					end
					a_sql.append (ic)
					idx := idx + 1
				end
			end

			-- Add rank if requested
			if include_rank then
				if not include_all_columns or not select_columns.is_empty then
					a_sql.append (", ")
				elseif include_all_columns and select_columns.is_empty then
					a_sql.append (", ")
				end
				a_sql.append ("bm25(")
				a_sql.append (table_name)
				if attached rank_weights as l_weights and then not l_weights.is_empty then
					across l_weights as ic loop
						a_sql.append (", ")
						a_sql.append (ic.out)
					end
				end
				a_sql.append (") as rank")
			end

			-- Add snippet if requested
			if attached snippet_column as al_l_snip_col then
				a_sql.append (", snippet(")
				a_sql.append (table_name)
				a_sql.append (", ")
				l_col_idx := column_index (al_l_snip_col)
				a_sql.append (l_col_idx.out)
				a_sql.append (", '")
				if attached snippet_start_tag as al_l_tag then
					a_sql.append (al_l_tag)
				else
					a_sql.append ("<b>")
				end
				a_sql.append ("', '")
				if attached snippet_end_tag as al_l_tag then
					a_sql.append (al_l_tag)
				else
					a_sql.append ("</b>")
				end
				a_sql.append ("', '")
				if attached snippet_ellipsis as al_l_ellip then
					a_sql.append (al_l_ellip)
				else
					a_sql.append ("...")
				end
				a_sql.append ("', ")
				a_sql.append (snippet_max_tokens.out)
				a_sql.append (") as snippet")
			end

			-- Add highlight if requested
			if attached highlight_column as al_l_high_col then
				a_sql.append (", highlight(")
				a_sql.append (table_name)
				a_sql.append (", ")
				l_col_idx := column_index (al_l_high_col)
				a_sql.append (l_col_idx.out)
				a_sql.append (", '")
				if attached highlight_start_tag as al_l_tag then
					a_sql.append (al_l_tag)
				else
					a_sql.append ("<b>")
				end
				a_sql.append ("', '")
				if attached highlight_end_tag as al_l_tag then
					a_sql.append (al_l_tag)
				else
					a_sql.append ("</b>")
				end
				a_sql.append ("') as highlight")
			end
		end

	append_match_clause (a_sql: STRING_8)
			-- Append MATCH clause to SQL
		note
			semantic_role: "[
				Builds WHERE clause with AND-joined
				MATCH expressions.
			]"
		local
			l_first: BOOLEAN
		do
			l_first := True
			across match_expressions as ic loop
				if not l_first then
					a_sql.append (" AND ")
				end
				l_first := False

				if attached ic.column as al_l_col then
					-- Column-specific match
					a_sql.append (al_l_col)
					a_sql.append (" MATCH '")
					a_sql.append (escaped_fts_query (ic.query))
					a_sql.append ("'")
				else
					-- Table-wide match
					a_sql.append (table_name)
					a_sql.append (" MATCH '")
					a_sql.append (escaped_fts_query (ic.query))
					a_sql.append ("'")
				end
			end
		end

	append_order_clause (a_sql: STRING_8)
			-- Append ORDER BY clause to SQL
		note
			semantic_role: "[
				Appends comma-separated ORDER BY clause
				if any ordering is specified.
			]"
		local
			i: INTEGER
		do
			if not order_clauses.is_empty then
				a_sql.append (" ORDER BY ")
				across
					order_clauses as ic
				from
					i := 1
				loop
					if i > 1 then
						a_sql.append (", ")
					end
					a_sql.append (ic)
					i := i + 1
				end
			end
		end

	append_limit_clause (a_sql: STRING_8)
			-- Append LIMIT/OFFSET clause to SQL
		note
			semantic_role: "[
				Appends LIMIT and optional OFFSET
				clause.
			]"
		do
			if limit_count > 0 then
				a_sql.append (" LIMIT ")
				a_sql.append (limit_count.out)
				if offset_count > 0 then
					a_sql.append (" OFFSET ")
					a_sql.append (offset_count.out)
				end
			end
		end

	escaped_fts_query (a_query: STRING_8): STRING_8
			-- Escape special characters in FTS5 query
		note
			semantic_role: "[
				Doubles single quotes for safe embedding
				in SQL string literals.
			]"
		local
			i: INTEGER
			c: CHARACTER
		do
			create Result.make (a_query.count + 10)
			from i := 1 until i > a_query.count loop
				c := a_query.item (i)
				inspect c
				when '%'' then
					Result.append ("''")
				else
					Result.append_character (c)
				end
				i := i + 1
			end
		end

	column_index (a_column: STRING_8): INTEGER
			-- Get 0-based index of column in FTS5 table
		note
			semantic_role: "[
				Looks up column ordinal position via
				PRAGMA table_info.
			]"
		local
			l_result: SIMPLE_SQL_RESULT
			l_name: STRING_32
		do
			l_result := database.query ("PRAGMA table_info('" + table_name + "')")
			across l_result.rows as ic loop
				l_name := ic.string_value ("l_name")
				if l_name.same_string (a_column.to_string_32) then
					Result := ic.integer_value ("cid")
				end
			end
		end

invariant
	database_attached: database /= Void
	table_name_not_empty: not table_name.is_empty

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		simple_sql - High-level SQLite API for Eiffel
		https://github.com/simple-eiffel/simple_sql
	]"

end
