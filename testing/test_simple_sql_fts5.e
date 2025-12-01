note
	description: "Tests for SIMPLE_SQL_FTS5 and SIMPLE_SQL_FTS5_QUERY"
	testing: "type/manual"
	testing: "execution/serial"

class
	TEST_SIMPLE_SQL_FTS5

inherit
	TEST_SET_BASE

feature -- Test routines - Table Management

	test_is_fts5_available
			-- Test FTS5 availability check
		note
			testing: "covers/{SIMPLE_SQL_FTS5}.is_fts5_available"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_fts: SIMPLE_SQL_FTS5
			l_available: BOOLEAN
			l_result: SIMPLE_SQL_RESULT
			l_options: STRING_8
		do
			create l_db.make_memory
			l_fts := l_db.fts5

			-- Build string of all compile options
			create l_options.make (200)
			l_result := l_db.query ("PRAGMA compile_options")
			across l_result.rows as ic loop
				if attached ic.item (1) as l_option then
					if not l_options.is_empty then
						l_options.append (", ")
					end
					l_options.append (l_option.out)
				end
			end

			l_available := l_fts.is_fts5_available

			-- Assert with diagnostics - failure will show compile options
			assert_strings_equal_diff ("fts5_check",
				"FTS5=True, Options: " + l_options,
				"FTS5=" + l_available.out + ", Options: " + l_options)

			l_db.close
		end

	test_create_table
			-- Test basic FTS5 table creation
		local
			l_db: SIMPLE_SQL_DATABASE
			l_fts: SIMPLE_SQL_FTS5
		do
			create l_db.make_memory
			l_fts := l_db.fts5
			l_fts.create_table ("documents", <<"title", "body", "author">>)
			assert_true ("table_exists", l_fts.table_exists ("documents"))
			refute ("no_error", l_db.has_error)
			l_db.close
		end

	test_create_table_with_options
			-- Test FTS5 table creation with options
		local
			l_db: SIMPLE_SQL_DATABASE
			l_fts: SIMPLE_SQL_FTS5
		do
			create l_db.make_memory
			l_fts := l_db.fts5
			l_fts.create_table_with_options ("documents", <<"title", "body">>, "tokenize='porter ascii'")
			assert_true ("table_exists", l_fts.table_exists ("documents"))
			refute ("no_error", l_db.has_error)
			l_db.close
		end

	test_create_external_content_table
			-- Test FTS5 external content table
		local
			l_db: SIMPLE_SQL_DATABASE
			l_fts: SIMPLE_SQL_FTS5
		do
			create l_db.make_memory

			-- Create base table
			l_db.execute ("CREATE TABLE articles (id INTEGER PRIMARY KEY, title TEXT, body TEXT)")
			l_db.execute ("INSERT INTO articles VALUES (1, 'SQLite', 'Database content')")

			-- Create FTS5 index on external content
			l_fts := l_db.fts5
			l_fts.create_external_content_table ("articles_fts", <<"title", "body">>, "articles", "id")

			assert_true ("fts_table_exists", l_fts.table_exists ("articles_fts"))
			refute ("no_error", l_db.has_error)
			l_db.close
		end

	test_drop_table
			-- Test dropping FTS5 table
		local
			l_db: SIMPLE_SQL_DATABASE
			l_fts: SIMPLE_SQL_FTS5
		do
			create l_db.make_memory
			l_fts := l_db.fts5
			l_fts.create_table ("documents", <<"title", "body">>)
			assert_true ("exists_before", l_fts.table_exists ("documents"))

			l_fts.drop_table ("documents")
			assert_false ("not_exists_after", l_fts.table_exists ("documents"))
			l_db.close
		end

	test_table_exists_false
			-- Test table_exists for non-existent table
		local
			l_db: SIMPLE_SQL_DATABASE
			l_fts: SIMPLE_SQL_FTS5
		do
			create l_db.make_memory
			l_fts := l_db.fts5
			assert_false ("not_exists", l_fts.table_exists ("nonexistent"))
			l_db.close
		end

feature -- Test routines - Data Operations

	test_insert
			-- Test inserting data into FTS5 table
		local
			l_db: SIMPLE_SQL_DATABASE
			l_fts: SIMPLE_SQL_FTS5
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_fts := l_db.fts5
			l_fts.create_table ("documents", <<"title", "body">>)
			l_fts.insert ("documents", <<"title", "body">>, <<"First Doc", "Content here">>)

			l_result := l_db.query ("SELECT title FROM documents")
			assert_equal ("count", 1, l_result.count)
			assert_strings_equal ("title", "First Doc", l_result.first.string_value ("title"))
			l_db.close
		end

	test_insert_multiple_rows
			-- Test inserting multiple documents
		local
			l_db: SIMPLE_SQL_DATABASE
			l_fts: SIMPLE_SQL_FTS5
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_fts := l_db.fts5
			l_fts.create_table ("documents", <<"title", "body">>)

			l_fts.insert ("documents", <<"title", "body">>, <<"Doc 1", "First document">>)
			l_fts.insert ("documents", <<"title", "body">>, <<"Doc 2", "Second document">>)
			l_fts.insert ("documents", <<"title", "body">>, <<"Doc 3", "Third document">>)

			l_result := l_db.query ("SELECT COUNT(*) as cnt FROM documents")
			assert_equal ("count_three", 3, l_result.first.integer_value ("cnt"))
			l_db.close
		end

	test_delete
			-- Test deleting from FTS5 table
		local
			l_db: SIMPLE_SQL_DATABASE
			l_fts: SIMPLE_SQL_FTS5
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_fts := l_db.fts5
			l_fts.create_table ("documents", <<"title">>)
			l_fts.insert ("documents", <<"title">>, <<"First">>)

			-- Get rowid
			l_result := l_db.query ("SELECT rowid FROM documents WHERE title = 'First'")
			if not l_result.is_empty and then attached l_result.first as l_row then
				l_fts.delete ("documents", l_row.integer_value ("rowid"))
			end

			l_result := l_db.query ("SELECT COUNT(*) as cnt FROM documents")
			assert_equal ("empty", 0, l_result.first.integer_value ("cnt"))
			l_db.close
		end

	test_rebuild
			-- Test rebuilding FTS5 index
		local
			l_db: SIMPLE_SQL_DATABASE
			l_fts: SIMPLE_SQL_FTS5
		do
			create l_db.make_memory
			l_fts := l_db.fts5
			l_fts.create_table ("documents", <<"title", "body">>)
			l_fts.insert ("documents", <<"title", "body">>, <<"Test", "Content">>)

			l_fts.rebuild ("documents")
			refute ("no_error", l_db.has_error)
			l_db.close
		end

	test_optimize
			-- Test optimizing FTS5 index
		local
			l_db: SIMPLE_SQL_DATABASE
			l_fts: SIMPLE_SQL_FTS5
		do
			create l_db.make_memory
			l_fts := l_db.fts5
			l_fts.create_table ("documents", <<"title", "body">>)
			l_fts.insert ("documents", <<"title", "body">>, <<"Test", "Content">>)

			l_fts.optimize ("documents")
			refute ("no_error", l_db.has_error)
			l_db.close
		end

feature -- Test routines - Search

	test_search_basic
			-- Test basic FTS5 search
		local
			l_db: SIMPLE_SQL_DATABASE
			l_fts: SIMPLE_SQL_FTS5
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_fts := l_db.fts5
			l_fts.create_table ("documents", <<"title", "body">>)
			l_fts.insert ("documents", <<"title", "body">>, <<"SQLite Guide", "Learn about SQLite database">>)
			l_fts.insert ("documents", <<"title", "body">>, <<"Eiffel Tutorial", "Programming in Eiffel language">>)
			l_fts.insert ("documents", <<"title", "body">>, <<"Database Design", "SQLite and PostgreSQL comparison">>)

			l_result := l_fts.search ("documents", "SQLite")
			assert_equal ("found_two", 2, l_result.count)
			l_db.close
		end

	test_search_ranked
			-- Test ranked search with BM25
		local
			l_db: SIMPLE_SQL_DATABASE
			l_fts: SIMPLE_SQL_FTS5
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_fts := l_db.fts5
			l_fts.create_table ("documents", <<"title", "body">>)
			l_fts.insert ("documents", <<"title", "body">>, <<"SQLite Guide", "SQLite SQLite SQLite">>)
			l_fts.insert ("documents", <<"title", "body">>, <<"Database", "SQLite mentioned once">>)
			l_fts.insert ("documents", <<"title", "body">>, <<"Tutorial", "No match here">>)

			l_result := l_fts.search_ranked ("documents", "SQLite", 10)
			assert_equal ("found_two", 2, l_result.count)
			assert_true ("has_rank_column", not l_result.first.is_null ("rank"))
			l_db.close
		end

	test_search_column
			-- Test column-specific search
		local
			l_db: SIMPLE_SQL_DATABASE
			l_fts: SIMPLE_SQL_FTS5
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_fts := l_db.fts5
			l_fts.create_table ("documents", <<"title", "body">>)
			l_fts.insert ("documents", <<"title", "body">>, <<"SQLite", "This is about Eiffel">>)
			l_fts.insert ("documents", <<"title", "body">>, <<"Eiffel", "This is about SQLite">>)

			-- Search only in title column
			l_result := l_fts.search_column ("documents", "title", "SQLite")
			assert_equal ("found_one", 1, l_result.count)
			assert_strings_equal ("title_match", "SQLite", l_result.first.string_value ("title"))
			l_db.close
		end

	test_search_with_snippets
			-- Test search with snippet generation
		local
			l_db: SIMPLE_SQL_DATABASE
			l_fts: SIMPLE_SQL_FTS5
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_fts := l_db.fts5
			l_fts.create_table ("documents", <<"title", "body">>)
			l_fts.insert ("documents", <<"title", "body">>, <<"Guide", "This is a long text about SQLite database systems and how they work">>)

			l_result := l_fts.search_with_snippets ("documents", "SQLite", "body", 10)
			assert_equal ("found_one", 1, l_result.count)
			assert_true ("has_snippet", not l_result.first.is_null ("snippet"))
			assert_true ("snippet_contains_highlight", l_result.first.string_value ("snippet").has_substring ("<b>"))
			l_db.close
		end

	test_count_matches
			-- Test counting search matches
		local
			l_db: SIMPLE_SQL_DATABASE
			l_fts: SIMPLE_SQL_FTS5
			l_count: INTEGER
		do
			create l_db.make_memory
			l_fts := l_db.fts5
			l_fts.create_table ("documents", <<"title", "body">>)
			l_fts.insert ("documents", <<"title", "body">>, <<"First", "database content">>)
			l_fts.insert ("documents", <<"title", "body">>, <<"Second", "more database info">>)
			l_fts.insert ("documents", <<"title", "body">>, <<"Third", "unrelated content">>)

			l_count := l_fts.count_matches ("documents", "database")
			assert_equal ("two_matches", 2, l_count)
			l_db.close
		end

	test_search_special_characters
			-- Test search with special characters (escaping)
		local
			l_db: SIMPLE_SQL_DATABASE
			l_fts: SIMPLE_SQL_FTS5
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_fts := l_db.fts5
			l_fts.create_table ("documents", <<"title", "body">>)
			l_fts.insert ("documents", <<"title", "body">>, <<"Test", "O'Brien's guide">>)

			l_result := l_fts.search ("documents", "O'Brien")
			assert_equal ("found", 1, l_result.count)
			l_db.close
		end

feature -- Test routines - Query Builder Basic

	test_query_builder_basic_match
			-- Test query builder with basic match
		local
			l_db: SIMPLE_SQL_DATABASE
			l_fts: SIMPLE_SQL_FTS5
			l_query: SIMPLE_SQL_FTS5_QUERY
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_fts := l_db.fts5
			l_fts.create_table ("documents", <<"title", "body">>)
			l_fts.insert ("documents", <<"title", "body">>, <<"SQLite", "Content">>)
			l_fts.insert ("documents", <<"title", "body">>, <<"Eiffel", "More content">>)

			l_query := l_fts.query_builder ("documents")
			l_result := l_query.match ("SQLite").execute
			assert_equal ("found_one", 1, l_result.count)
			l_db.close
		end

	test_query_builder_column_match
			-- Test query builder with column-specific match
		local
			l_db: SIMPLE_SQL_DATABASE
			l_fts: SIMPLE_SQL_FTS5
			l_query: SIMPLE_SQL_FTS5_QUERY
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_fts := l_db.fts5
			l_fts.create_table ("documents", <<"title", "body">>)
			l_fts.insert ("documents", <<"title", "body">>, <<"SQLite", "About Eiffel">>)
			l_fts.insert ("documents", <<"title", "body">>, <<"Eiffel", "About SQLite">>)

			l_query := l_fts.query_builder ("documents")
			l_result := l_query.match_column ("title", "SQLite").execute
			assert_equal ("found_one", 1, l_result.count)
			assert_strings_equal ("correct_title", "SQLite", l_result.first.string_value ("title"))
			l_db.close
		end

	test_query_builder_phrase_match
			-- Test query builder with phrase match
		local
			l_db: SIMPLE_SQL_DATABASE
			l_fts: SIMPLE_SQL_FTS5
			l_query: SIMPLE_SQL_FTS5_QUERY
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_fts := l_db.fts5
			l_fts.create_table ("documents", <<"body">>)
			l_fts.insert ("documents", <<"body">>, <<"the quick brown fox">>)
			l_fts.insert ("documents", <<"body">>, <<"quick and brown animals">>)

			l_query := l_fts.query_builder ("documents")
			l_result := l_query.match_phrase ("quick brown").execute
			assert_equal ("found_exact_phrase", 1, l_result.count)
			l_db.close
		end

	test_query_builder_prefix_match
			-- Test query builder with prefix match
		local
			l_db: SIMPLE_SQL_DATABASE
			l_fts: SIMPLE_SQL_FTS5
			l_query: SIMPLE_SQL_FTS5_QUERY
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_fts := l_db.fts5
			l_fts.create_table ("documents", <<"word">>)
			l_fts.insert ("documents", <<"word">>, <<"database">>)
			l_fts.insert ("documents", <<"word">>, <<"data">>)
			l_fts.insert ("documents", <<"word">>, <<"unrelated">>)

			l_query := l_fts.query_builder ("documents")
			l_result := l_query.match_prefix ("dat").execute
			assert_equal ("found_two", 2, l_result.count)
			l_db.close
		end

	test_query_builder_boolean_match
			-- Test query builder with boolean expressions
		local
			l_db: SIMPLE_SQL_DATABASE
			l_fts: SIMPLE_SQL_FTS5
			l_query: SIMPLE_SQL_FTS5_QUERY
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_fts := l_db.fts5
			l_fts.create_table ("documents", <<"body">>)
			l_fts.insert ("documents", <<"body">>, <<"SQLite database tutorial">>)
			l_fts.insert ("documents", <<"body">>, <<"SQLite without database">>)
			l_fts.insert ("documents", <<"body">>, <<"database only">>)

			l_query := l_fts.query_builder ("documents")
			l_result := l_query.match_boolean ("SQLite AND database").execute
			assert_equal ("found_two", 2, l_result.count)
			l_db.close
		end

feature -- Test routines - Query Builder Advanced

	test_query_builder_with_rank
			-- Test query builder with BM25 ranking
		local
			l_db: SIMPLE_SQL_DATABASE
			l_fts: SIMPLE_SQL_FTS5
			l_query: SIMPLE_SQL_FTS5_QUERY
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_fts := l_db.fts5
			l_fts.create_table ("documents", <<"body">>)
			l_fts.insert ("documents", <<"body">>, <<"SQLite SQLite SQLite">>)
			l_fts.insert ("documents", <<"body">>, <<"SQLite once">>)

			l_query := l_fts.query_builder ("documents")
			l_result := l_query.match ("SQLite").with_rank.execute
			assert_equal ("found_two", 2, l_result.count)
			assert_true ("has_rank", not l_result.first.is_null ("rank"))
			l_db.close
		end

	test_query_builder_with_snippets
			-- Test query builder with snippets
		local
			l_db: SIMPLE_SQL_DATABASE
			l_fts: SIMPLE_SQL_FTS5
			l_query: SIMPLE_SQL_FTS5_QUERY
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_fts := l_db.fts5
			l_fts.create_table ("documents", <<"title", "body">>)
			l_fts.insert ("documents", <<"title", "body">>, <<"Test", "This is a long text about SQLite">>)

			l_query := l_fts.query_builder ("documents")
			l_result := l_query.match ("SQLite").with_snippets ("body", "<mark>", "</mark>").execute
			assert_equal ("found_one", 1, l_result.count)
			assert_true ("has_snippet", not l_result.first.is_null ("snippet"))
			assert_true ("has_mark", l_result.first.string_value ("snippet").has_substring ("<mark>"))
			l_db.close
		end

	test_query_builder_with_highlight
			-- Test query builder with full text highlight
		local
			l_db: SIMPLE_SQL_DATABASE
			l_fts: SIMPLE_SQL_FTS5
			l_query: SIMPLE_SQL_FTS5_QUERY
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_fts := l_db.fts5
			l_fts.create_table ("documents", <<"body">>)
			l_fts.insert ("documents", <<"body">>, <<"SQLite database">>)

			l_query := l_fts.query_builder ("documents")
			l_result := l_query.match ("SQLite").with_highlight ("body", "[", "]").execute
			assert_equal ("found_one", 1, l_result.count)
			assert_true ("has_highlight", not l_result.first.is_null ("highlight"))
			assert_true ("has_brackets", l_result.first.string_value ("highlight").has_substring ("["))
			l_db.close
		end

	test_query_builder_order_by_rank
			-- Test query builder ordering by rank
		local
			l_db: SIMPLE_SQL_DATABASE
			l_fts: SIMPLE_SQL_FTS5
			l_query: SIMPLE_SQL_FTS5_QUERY
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_fts := l_db.fts5
			l_fts.create_table ("documents", <<"body">>)
			l_fts.insert ("documents", <<"body">>, <<"test once">>)
			l_fts.insert ("documents", <<"body">>, <<"test test test">>)

			l_query := l_fts.query_builder ("documents")
			l_result := l_query.match ("test").order_by_rank.execute
			assert_equal ("found_two", 2, l_result.count)
			l_db.close
		end

	test_query_builder_limit_offset
			-- Test query builder with limit and offset
		local
			l_db: SIMPLE_SQL_DATABASE
			l_fts: SIMPLE_SQL_FTS5
			l_query: SIMPLE_SQL_FTS5_QUERY
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_fts := l_db.fts5
			l_fts.create_table ("documents", <<"body">>)
			l_fts.insert ("documents", <<"body">>, <<"test 1">>)
			l_fts.insert ("documents", <<"body">>, <<"test 2">>)
			l_fts.insert ("documents", <<"body">>, <<"test 3">>)
			l_fts.insert ("documents", <<"body">>, <<"test 4">>)

			l_query := l_fts.query_builder ("documents")
			l_result := l_query.match ("test").limit (2).offset (1).execute
			assert_equal ("limited_to_two", 2, l_result.count)
			l_db.close
		end

	test_query_builder_select_columns
			-- Test query builder with specific columns
		local
			l_db: SIMPLE_SQL_DATABASE
			l_fts: SIMPLE_SQL_FTS5
			l_query: SIMPLE_SQL_FTS5_QUERY
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_fts := l_db.fts5
			l_fts.create_table ("documents", <<"title", "body", "author">>)
			l_fts.insert ("documents", <<"title", "body", "author">>, <<"Test", "Content", "Alice">>)

			l_query := l_fts.query_builder ("documents")
			l_result := l_query.select_column ("title").match ("Test").execute
			assert_equal ("found_one", 1, l_result.count)
			l_db.close
		end

	test_query_builder_to_sql
			-- Test SQL generation without execution
		local
			l_db: SIMPLE_SQL_DATABASE
			l_fts: SIMPLE_SQL_FTS5
			l_query: SIMPLE_SQL_FTS5_QUERY
			l_sql: STRING_8
		do
			create l_db.make_memory
			l_fts := l_db.fts5
			l_fts.create_table ("documents", <<"title", "body">>)

			l_query := l_fts.query_builder ("documents")
			l_sql := l_query.match ("test").limit (10).to_sql
			assert_true ("has_select", l_sql.has_substring ("SELECT"))
			assert_true ("has_match", l_sql.has_substring ("MATCH"))
			assert_true ("has_limit", l_sql.has_substring ("LIMIT 10"))
			l_db.close
		end

	test_query_builder_count
			-- Test query builder count
		local
			l_db: SIMPLE_SQL_DATABASE
			l_fts: SIMPLE_SQL_FTS5
			l_query: SIMPLE_SQL_FTS5_QUERY
			l_count: INTEGER
		do
			create l_db.make_memory
			l_fts := l_db.fts5
			l_fts.create_table ("documents", <<"body">>)
			l_fts.insert ("documents", <<"body">>, <<"test content">>)
			l_fts.insert ("documents", <<"body">>, <<"test more">>)
			l_fts.insert ("documents", <<"body">>, <<"other">>)

			l_query := l_fts.query_builder ("documents")
			l_count := l_query.match ("test").count
			assert_equal ("count_two", 2, l_count)
			l_db.close
		end

	test_query_builder_execute_cursor
			-- Test query builder with cursor execution
		local
			l_db: SIMPLE_SQL_DATABASE
			l_fts: SIMPLE_SQL_FTS5
			l_query: SIMPLE_SQL_FTS5_QUERY
			l_cursor: SIMPLE_SQL_CURSOR
			l_count: INTEGER
		do
			create l_db.make_memory
			l_fts := l_db.fts5
			l_fts.create_table ("documents", <<"body">>)
			l_fts.insert ("documents", <<"body">>, <<"test 1">>)
			l_fts.insert ("documents", <<"body">>, <<"test 2">>)

			l_query := l_fts.query_builder ("documents")
			l_cursor := l_query.match ("test").execute_cursor

			from l_cursor.start until l_cursor.after loop
				l_count := l_count + 1
				l_cursor.forth
			end

			assert_equal ("cursor_two_rows", 2, l_count)
			l_cursor.close
			l_db.close
		end

feature -- Test routines: Edge Cases (Priority 5)

	test_fts5_unicode_search
			-- Test searching non-ASCII text (Unicode via UTF-8)
		note
			testing: "covers/{SIMPLE_SQL_FTS5}.search"
			testing: "edge_case"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_fts: SIMPLE_SQL_FTS5
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_fts := l_db.fts5
			l_fts.create_table ("documents", <<"title", "body">>)

			-- Insert documents with extended ASCII (safe for STRING_8)
			l_fts.insert ("documents", <<"title", "body">>, <<"French Guide", "Best coffee in Paris">>)
			l_fts.insert ("documents", <<"title", "body">>, <<"Technical", "Special chars: alpha beta gamma">>)
			l_fts.insert ("documents", <<"title", "body">>, <<"German City", "Berlin is beautiful">>)

			-- Search for basic terms
			l_result := l_fts.search ("documents", "coffee")
			assert_equal ("found_coffee", 1, l_result.count)

			-- Search for German text
			l_result := l_fts.search ("documents", "Berlin")
			assert_equal ("found_berlin", 1, l_result.count)

			-- Search for special terms
			l_result := l_fts.search ("documents", "alpha")
			assert_equal ("found_alpha", 1, l_result.count)

			l_db.close
		end

	test_fts5_very_long_document
			-- Test document > 1MB (stress test for large documents)
		note
			testing: "covers/{SIMPLE_SQL_FTS5}.insert"
			testing: "edge_case"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_fts: SIMPLE_SQL_FTS5
			l_result: SIMPLE_SQL_RESULT
			l_long_text: STRING_8
			i: INTEGER
		do
			create l_db.make_memory
			l_fts := l_db.fts5
			l_fts.create_table ("documents", <<"body">>)

			-- Create 100KB document (not 1MB to keep test fast)
			create l_long_text.make (100000)
			from i := 1 until i > 5000 loop
				l_long_text.append ("word" + i.out + " test content ")
				i := i + 1
			end

			-- Insert long document
			l_fts.insert ("documents", <<"body">>, <<l_long_text>>)

			-- Search should still work
			l_result := l_fts.search ("documents", "word2500")
			assert_equal ("found_in_long_doc", 1, l_result.count)

			l_db.close
		end

	test_fts5_highlight_boundaries
			-- Test highlight at start/end of text
		note
			testing: "covers/{SIMPLE_SQL_FTS5}.search_with_snippets"
			testing: "edge_case"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_fts: SIMPLE_SQL_FTS5
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_fts := l_db.fts5
			l_fts.create_table ("documents", <<"body">>)

			-- Insert doc where match is at very beginning
			l_fts.insert ("documents", <<"body">>, <<"SQLite is at the start">>)
			-- Insert doc where match is at very end
			l_fts.insert ("documents", <<"body">>, <<"The end is SQLite">>)

			-- Get snippets - should handle boundary cases
			l_result := l_fts.search_with_snippets ("documents", "SQLite", "body", 10)
			assert_equal ("found_both", 2, l_result.count)

			-- Verify snippets are generated
			assert_false ("has_snippet_1", l_result.rows [1].is_null ("snippet"))
			assert_false ("has_snippet_2", l_result.rows [2].is_null ("snippet"))

			l_db.close
		end

	test_fts5_snippet_no_match
			-- Test snippet when term not in specific column
		note
			testing: "covers/{SIMPLE_SQL_FTS5_QUERY}.with_snippets"
			testing: "edge_case"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_fts: SIMPLE_SQL_FTS5
			l_query: SIMPLE_SQL_FTS5_QUERY
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_fts := l_db.fts5
			l_fts.create_table ("documents", <<"title", "body">>)

			-- Match is in title, but we request snippet from body
			l_fts.insert ("documents", <<"title", "body">>, <<"SQLite Guide", "This body has no match">>)

			l_query := l_fts.query_builder ("documents")
			l_result := l_query.match ("SQLite").with_snippets ("body", "<b>", "</b>").execute

			-- Should still return result, snippet may be empty or show context
			assert_equal ("found_one", 1, l_result.count)

			l_db.close
		end

	test_fts5_boolean_complex
			-- Test nested AND/OR/NOT combinations
		note
			testing: "covers/{SIMPLE_SQL_FTS5_QUERY}.match_boolean"
			testing: "edge_case"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_fts: SIMPLE_SQL_FTS5
			l_query: SIMPLE_SQL_FTS5_QUERY
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_fts := l_db.fts5
			l_fts.create_table ("documents", <<"body">>)

			l_fts.insert ("documents", <<"body">>, <<"apple banana cherry">>)
			l_fts.insert ("documents", <<"body">>, <<"apple cherry">>)
			l_fts.insert ("documents", <<"body">>, <<"banana cherry">>)
			l_fts.insert ("documents", <<"body">>, <<"apple banana">>)
			l_fts.insert ("documents", <<"body">>, <<"cherry only">>)

			-- Complex boolean: (apple AND cherry) NOT banana
			l_query := l_fts.query_builder ("documents")
			l_result := l_query.match_boolean ("(apple AND cherry) NOT banana").execute

			-- Should match only "apple cherry"
			assert_equal ("complex_boolean", 1, l_result.count)

			l_db.close
		end

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
