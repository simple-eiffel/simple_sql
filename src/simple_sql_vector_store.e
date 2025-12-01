note
	description: "[
		Vector storage and retrieval for SQLite with similarity search.

		Provides persistent storage for embedding vectors with:
			- CRUD operations (insert, retrieve, update, delete)
			- Metadata association (key-value pairs per vector)
			- K-nearest neighbor search
			- Similarity filtering

		Table Schema (auto-created):
			CREATE TABLE IF NOT EXISTS {table_name} (
				id INTEGER PRIMARY KEY AUTOINCREMENT,
				vector_data BLOB NOT NULL,
				dimension INTEGER NOT NULL,
				metadata TEXT,  -- JSON for flexible key-value storage
				created_at TEXT DEFAULT CURRENT_TIMESTAMP
			)

		Usage:
			create store.make (db, "embeddings")

			-- Insert vector with metadata
			id := store.insert (my_vector, "{%"source%": %"document.txt%"}")

			-- Retrieve by ID
			vec := store.find_by_id (id)

			-- Find similar vectors
			results := store.find_nearest (query_vector, 10)  -- Top 10
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_VECTOR_STORE

create
	make

feature {NONE} -- Initialization

	make (a_database: SIMPLE_SQL_DATABASE; a_table_name: STRING_8)
			-- Create vector store using specified table
		require
			database_open: a_database.is_open
			table_name_valid: not a_table_name.is_empty
		do
			database := a_database
			table_name := a_table_name
			create similarity.make
			ensure_table_exists
		ensure
			database_set: database = a_database
			table_name_set: table_name ~ a_table_name
		end

feature -- Access

	database: SIMPLE_SQL_DATABASE
			-- Database connection

	table_name: STRING_8
			-- Table storing vectors

	similarity: SIMPLE_SQL_SIMILARITY
			-- Similarity calculator

	has_error: BOOLEAN
			-- Did last operation fail?
		do
			Result := last_error_message /= Void
		end

	last_error_message: detachable STRING_32
			-- Error message from last operation

feature -- Query

	find_by_id (a_id: INTEGER_64): detachable SIMPLE_SQL_VECTOR
			-- Retrieve vector by ID, Void if not found
		local
			l_sql: STRING_8
			l_result: SIMPLE_SQL_RESULT
		do
			clear_error
			l_sql := "SELECT vector_data FROM " + table_name + " WHERE id = " + a_id.out
			l_result := database.query (l_sql)
			if not database.has_error and then l_result.count > 0 then
				if attached l_result.first.blob_value ("vector_data") as l_blob then
					create Result.make_from_blob (l_blob)
				end
			elseif database.has_error then
				set_error (database.last_error_message)
			end
		end

	find_metadata_by_id (a_id: INTEGER_64): detachable STRING_32
			-- Retrieve metadata JSON by ID
		local
			l_sql: STRING_8
			l_result: SIMPLE_SQL_RESULT
		do
			clear_error
			l_sql := "SELECT metadata FROM " + table_name + " WHERE id = " + a_id.out
			l_result := database.query (l_sql)
			if not database.has_error and then l_result.count > 0 then
				Result := l_result.first.string_value ("metadata")
			elseif database.has_error then
				set_error (database.last_error_message)
			end
		end

	count: INTEGER_64
			-- Total number of vectors stored
		local
			l_result: SIMPLE_SQL_RESULT
		do
			clear_error
			l_result := database.query ("SELECT COUNT(*) as cnt FROM " + table_name)
			if not database.has_error and then l_result.count > 0 then
				Result := l_result.first.integer_value ("cnt")
			end
		end

	all_ids: ARRAYED_LIST [INTEGER_64]
			-- All vector IDs in store
		local
			l_result: SIMPLE_SQL_RESULT
		do
			clear_error
			create Result.make (100)
			l_result := database.query ("SELECT id FROM " + table_name + " ORDER BY id")
			if not database.has_error then
				across l_result.rows as ic loop
					Result.extend (ic.integer_64_value ("id"))
				end
			end
		end

	find_all: ARRAYED_LIST [TUPLE [id: INTEGER_64; vector: SIMPLE_SQL_VECTOR; metadata: detachable STRING_32]]
			-- All vectors with their IDs and metadata
		local
			l_result: SIMPLE_SQL_RESULT
			l_vector: SIMPLE_SQL_VECTOR
		do
			clear_error
			create Result.make (100)
			l_result := database.query ("SELECT id, vector_data, metadata FROM " + table_name + " ORDER BY id")
			if not database.has_error then
				across l_result.rows as ic loop
					if attached ic.blob_value ("vector_data") as l_blob then
						create l_vector.make_from_blob (l_blob)
						Result.extend ([ic.integer_64_value ("id"), l_vector, ic.string_value ("metadata")])
					end
				end
			end
		end

feature -- Similarity Search

	find_nearest (a_query: SIMPLE_SQL_VECTOR; a_k: INTEGER): ARRAYED_LIST [TUPLE [id: INTEGER_64; vector: SIMPLE_SQL_VECTOR; score: REAL_64]]
			-- Find K nearest neighbors by cosine similarity
		require
			k_positive: a_k > 0
		local
			l_all: ARRAYED_LIST [TUPLE [id: INTEGER_64; vector: SIMPLE_SQL_VECTOR; metadata: detachable STRING_32]]
			l_scored: ARRAYED_LIST [TUPLE [id: INTEGER_64; vector: SIMPLE_SQL_VECTOR; score: REAL_64]]
			l_score: REAL_64
		do
			clear_error
			create Result.make (a_k)
			l_all := find_all
			create l_scored.make (l_all.count)

			-- Calculate similarity scores
			across l_all as ic loop
				if ic.vector.dimension = a_query.dimension then
					l_score := similarity.cosine_similarity (a_query, ic.vector)
					l_scored.extend ([ic.id, ic.vector, l_score])
				end
			end

			-- Sort by score descending (highest similarity first)
			sort_by_score_descending (l_scored)

			-- Take top K
			across l_scored as ic loop
				if Result.count < a_k then
					Result.extend (ic)
				end
			end
		ensure
			at_most_k: Result.count <= a_k
		end

	find_nearest_euclidean (a_query: SIMPLE_SQL_VECTOR; a_k: INTEGER): ARRAYED_LIST [TUPLE [id: INTEGER_64; vector: SIMPLE_SQL_VECTOR; distance: REAL_64]]
			-- Find K nearest neighbors by Euclidean distance
		require
			k_positive: a_k > 0
		local
			l_all: ARRAYED_LIST [TUPLE [id: INTEGER_64; vector: SIMPLE_SQL_VECTOR; metadata: detachable STRING_32]]
			l_scored: ARRAYED_LIST [TUPLE [id: INTEGER_64; vector: SIMPLE_SQL_VECTOR; distance: REAL_64]]
			l_distance: REAL_64
		do
			clear_error
			create Result.make (a_k)
			l_all := find_all
			create l_scored.make (l_all.count)

			-- Calculate distances
			across l_all as ic loop
				if ic.vector.dimension = a_query.dimension then
					l_distance := similarity.euclidean_distance (a_query, ic.vector)
					l_scored.extend ([ic.id, ic.vector, l_distance])
				end
			end

			-- Sort by distance ascending (smallest distance first)
			sort_by_distance_ascending (l_scored)

			-- Take top K
			across l_scored as ic loop
				if Result.count < a_k then
					Result.extend (ic)
				end
			end
		ensure
			at_most_k: Result.count <= a_k
		end

	find_within_threshold (a_query: SIMPLE_SQL_VECTOR; a_threshold: REAL_64): ARRAYED_LIST [TUPLE [id: INTEGER_64; vector: SIMPLE_SQL_VECTOR; score: REAL_64]]
			-- Find all vectors with cosine similarity >= threshold
		require
			valid_threshold: a_threshold >= -1.0 and a_threshold <= 1.0
		local
			l_all: ARRAYED_LIST [TUPLE [id: INTEGER_64; vector: SIMPLE_SQL_VECTOR; metadata: detachable STRING_32]]
			l_score: REAL_64
		do
			clear_error
			create Result.make (100)
			l_all := find_all

			across l_all as ic loop
				if ic.vector.dimension = a_query.dimension then
					l_score := similarity.cosine_similarity (a_query, ic.vector)
					if l_score >= a_threshold then
						Result.extend ([ic.id, ic.vector, l_score])
					end
				end
			end

			-- Sort by score descending
			sort_by_score_descending (Result)
		end

feature -- Commands

	insert (a_vector: SIMPLE_SQL_VECTOR; a_metadata: detachable READABLE_STRING_GENERAL): INTEGER_64
			-- Insert vector with optional metadata, return new ID
		local
			l_stmt: SIMPLE_SQL_PREPARED_STATEMENT
			l_blob: MANAGED_POINTER
		do
			clear_error
			l_blob := a_vector.to_blob
			l_stmt := database.prepare ("INSERT INTO " + table_name + " (vector_data, dimension, metadata) VALUES (?, ?, ?)")
			l_stmt.bind_blob (1, l_blob)
			l_stmt.bind_integer (2, a_vector.dimension)
			if attached a_metadata then
				l_stmt.bind_text (3, a_metadata.to_string_8)
			else
				l_stmt.bind_null (3)
			end
			l_stmt.execute

			if l_stmt.has_error then
				if attached l_stmt.last_error as l_error then
					set_error (l_error.message)
				else
					set_error ("Unknown error")
				end
			else
				Result := database.last_insert_rowid
			end
		ensure
			error_or_positive_id: has_error or Result > 0
		end

	update (a_id: INTEGER_64; a_vector: SIMPLE_SQL_VECTOR): BOOLEAN
			-- Update vector data for existing ID
		local
			l_stmt: SIMPLE_SQL_PREPARED_STATEMENT
			l_blob: MANAGED_POINTER
		do
			clear_error
			l_blob := a_vector.to_blob
			l_stmt := database.prepare ("UPDATE " + table_name + " SET vector_data = ?, dimension = ? WHERE id = ?")
			l_stmt.bind_blob (1, l_blob)
			l_stmt.bind_integer (2, a_vector.dimension)
			l_stmt.bind_integer (3, a_id)
			l_stmt.execute

			if l_stmt.has_error then
				if attached l_stmt.last_error as l_error then
					set_error (l_error.message)
				else
					set_error ("Unknown error")
				end
			else
				Result := database.changes_count > 0
			end
		end

	update_metadata (a_id: INTEGER_64; a_metadata: detachable READABLE_STRING_GENERAL): BOOLEAN
			-- Update metadata for existing ID
		local
			l_stmt: SIMPLE_SQL_PREPARED_STATEMENT
		do
			clear_error
			l_stmt := database.prepare ("UPDATE " + table_name + " SET metadata = ? WHERE id = ?")
			if attached a_metadata then
				l_stmt.bind_text (1, a_metadata.to_string_8)
			else
				l_stmt.bind_null (1)
			end
			l_stmt.bind_integer (2, a_id)
			l_stmt.execute

			if l_stmt.has_error then
				if attached l_stmt.last_error as l_error then
					set_error (l_error.message)
				else
					set_error ("Unknown error")
				end
			else
				Result := database.changes_count > 0
			end
		end

	delete (a_id: INTEGER_64): BOOLEAN
			-- Delete vector by ID
		local
			l_sql: STRING_8
		do
			clear_error
			l_sql := "DELETE FROM " + table_name + " WHERE id = " + a_id.out
			database.execute (l_sql)
			if database.has_error then
				set_error (database.last_error_message)
			else
				Result := database.changes_count > 0
			end
		end

	delete_all: INTEGER
			-- Delete all vectors, return count deleted
		local
			l_sql: STRING_8
		do
			clear_error
			l_sql := "DELETE FROM " + table_name
			database.execute (l_sql)
			if database.has_error then
				set_error (database.last_error_message)
			else
				Result := database.changes_count
			end
		end

	exists (a_id: INTEGER_64): BOOLEAN
			-- Does vector with this ID exist?
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query ("SELECT 1 FROM " + table_name + " WHERE id = " + a_id.out)
			Result := not database.has_error and then l_result.count > 0
		end

feature {NONE} -- Implementation

	ensure_table_exists
			-- Create table if it doesn't exist
		local
			l_sql: STRING_8
		do
			l_sql := "CREATE TABLE IF NOT EXISTS " + table_name + " (id INTEGER PRIMARY KEY AUTOINCREMENT, vector_data BLOB NOT NULL, dimension INTEGER NOT NULL, metadata TEXT, created_at TEXT DEFAULT CURRENT_TIMESTAMP)"
			database.execute (l_sql)
		end

	sort_by_score_descending (a_list: ARRAYED_LIST [TUPLE [id: INTEGER_64; vector: SIMPLE_SQL_VECTOR; score: REAL_64]])
			-- Sort in place by score descending (bubble sort - simple for small lists)
		local
			i, j: INTEGER
			temp: TUPLE [id: INTEGER_64; vector: SIMPLE_SQL_VECTOR; score: REAL_64]
			swapped: BOOLEAN
		do
			from i := 1 until i >= a_list.count loop
				swapped := False
				from j := 1 until j > a_list.count - i loop
					if a_list [j].score < a_list [j + 1].score then
						temp := a_list [j]
						a_list [j] := a_list [j + 1]
						a_list [j + 1] := temp
						swapped := True
					end
					j := j + 1
				end
				if not swapped then
					i := a_list.count -- Exit early if sorted
				end
				i := i + 1
			end
		end

	sort_by_distance_ascending (a_list: ARRAYED_LIST [TUPLE [id: INTEGER_64; vector: SIMPLE_SQL_VECTOR; distance: REAL_64]])
			-- Sort in place by distance ascending (bubble sort)
		local
			i, j: INTEGER
			temp: TUPLE [id: INTEGER_64; vector: SIMPLE_SQL_VECTOR; distance: REAL_64]
			swapped: BOOLEAN
		do
			from i := 1 until i >= a_list.count loop
				swapped := False
				from j := 1 until j > a_list.count - i loop
					if a_list [j].distance > a_list [j + 1].distance then
						temp := a_list [j]
						a_list [j] := a_list [j + 1]
						a_list [j + 1] := temp
						swapped := True
					end
					j := j + 1
				end
				if not swapped then
					i := a_list.count
				end
				i := i + 1
			end
		end

	clear_error
			-- Clear error state
		do
			last_error_message := Void
		ensure
			no_error: not has_error
		end

	set_error (a_message: detachable READABLE_STRING_GENERAL)
			-- Set error message
		do
			if attached a_message then
				last_error_message := a_message.to_string_32
			else
				last_error_message := "Unknown error"
			end
		ensure
			has_error: has_error
		end

invariant
	database_exists: database /= Void
	table_name_valid: not table_name.is_empty

end
