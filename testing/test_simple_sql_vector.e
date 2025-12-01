note
	description: "Test suite for vector embeddings: SIMPLE_SQL_VECTOR, SIMPLE_SQL_VECTOR_STORE, SIMPLE_SQL_SIMILARITY"
	testing: "type/manual"
	testing: "execution/isolated"

class
	TEST_SIMPLE_SQL_VECTOR

inherit
	TEST_SET_BASE

feature -- Test routines: SIMPLE_SQL_VECTOR Creation

	test_vector_from_array
			-- Test creating vector from array
		note
			testing: "covers/{SIMPLE_SQL_VECTOR}.make_from_array"
		local
			l_vec: SIMPLE_SQL_VECTOR
		do
			create l_vec.make_from_array (<<0.1, 0.2, 0.3, 0.4>>)
			assert_equal ("dimension", 4, l_vec.dimension)
			assert_true ("value_1", (l_vec [1] - 0.1).abs < 1.0e-10)
			assert_true ("value_2", (l_vec [2] - 0.2).abs < 1.0e-10)
			assert_true ("value_3", (l_vec [3] - 0.3).abs < 1.0e-10)
			assert_true ("value_4", (l_vec [4] - 0.4).abs < 1.0e-10)
		end

	test_vector_zero
			-- Test creating zero vector
		note
			testing: "covers/{SIMPLE_SQL_VECTOR}.make_zero"
		local
			l_vec: SIMPLE_SQL_VECTOR
		do
			create l_vec.make_zero (5)
			assert_equal ("dimension", 5, l_vec.dimension)
			assert_true ("is_zero", l_vec.is_zero)
			assert_true ("all_zero", across 1 |..| 5 as i all l_vec [i] = 0.0 end)
		end

	test_vector_blob_roundtrip
			-- Test vector to BLOB and back
		note
			testing: "covers/{SIMPLE_SQL_VECTOR}.to_blob"
			testing: "covers/{SIMPLE_SQL_VECTOR}.make_from_blob"
		local
			l_vec1, l_vec2: SIMPLE_SQL_VECTOR
			l_blob: MANAGED_POINTER
		do
			create l_vec1.make_from_array (<<1.5, -2.7, 3.14159, 0.0, -0.001>>)
			l_blob := l_vec1.to_blob

			assert_equal ("blob_size", 40, l_blob.count)  -- 5 * 8 bytes

			create l_vec2.make_from_blob (l_blob)
			assert_equal ("same_dimension", l_vec1.dimension, l_vec2.dimension)
			assert_true ("values_equal", l_vec1.is_equal (l_vec2))
		end

feature -- Test routines: SIMPLE_SQL_VECTOR Mathematical Operations

	test_vector_magnitude
			-- Test magnitude calculation
		note
			testing: "covers/{SIMPLE_SQL_VECTOR}.magnitude"
		local
			l_vec: SIMPLE_SQL_VECTOR
			l_mag: REAL_64
		do
			-- 3-4-5 triangle: sqrt(3^2 + 4^2) = 5
			create l_vec.make_from_array (<<3.0, 4.0>>)
			l_mag := l_vec.magnitude
			assert_true ("magnitude_5", (l_mag - 5.0).abs < 1.0e-10)

			-- Unit vector
			create l_vec.make_from_array (<<1.0, 0.0, 0.0>>)
			assert_true ("unit_magnitude", (l_vec.magnitude - 1.0).abs < 1.0e-10)

			-- Zero vector
			create l_vec.make_zero (3)
			assert_true ("zero_magnitude", l_vec.magnitude < 1.0e-10)
		end

	test_vector_dot_product
			-- Test dot product
		note
			testing: "covers/{SIMPLE_SQL_VECTOR}.dot_product"
		local
			l_vec1, l_vec2: SIMPLE_SQL_VECTOR
			l_dot: REAL_64
		do
			create l_vec1.make_from_array (<<1.0, 2.0, 3.0>>)
			create l_vec2.make_from_array (<<4.0, 5.0, 6.0>>)
			-- 1*4 + 2*5 + 3*6 = 4 + 10 + 18 = 32
			l_dot := l_vec1.dot_product (l_vec2)
			assert_true ("dot_32", (l_dot - 32.0).abs < 1.0e-10)

			-- Orthogonal vectors
			create l_vec1.make_from_array (<<1.0, 0.0>>)
			create l_vec2.make_from_array (<<0.0, 1.0>>)
			l_dot := l_vec1.dot_product (l_vec2)
			assert_true ("orthogonal_zero", l_dot.abs < 1.0e-10)
		end

	test_vector_normalized
			-- Test normalization
		note
			testing: "covers/{SIMPLE_SQL_VECTOR}.normalized"
		local
			l_vec, l_norm: SIMPLE_SQL_VECTOR
		do
			create l_vec.make_from_array (<<3.0, 4.0>>)
			l_norm := l_vec.normalized
			assert_true ("unit_magnitude", (l_norm.magnitude - 1.0).abs < 1.0e-10)
			assert_equal ("same_dimension", l_vec.dimension, l_norm.dimension)
		end

	test_vector_add_subtract
			-- Test vector addition and subtraction
		note
			testing: "covers/{SIMPLE_SQL_VECTOR}.add"
			testing: "covers/{SIMPLE_SQL_VECTOR}.subtract"
		local
			l_vec1, l_vec2, l_sum, l_diff: SIMPLE_SQL_VECTOR
		do
			create l_vec1.make_from_array (<<1.0, 2.0, 3.0>>)
			create l_vec2.make_from_array (<<4.0, 5.0, 6.0>>)

			l_sum := l_vec1.add (l_vec2)
			assert_true ("sum_1", (l_sum [1] - 5.0).abs < 1.0e-10)
			assert_true ("sum_2", (l_sum [2] - 7.0).abs < 1.0e-10)
			assert_true ("sum_3", (l_sum [3] - 9.0).abs < 1.0e-10)

			l_diff := l_vec2.subtract (l_vec1)
			assert_true ("diff_1", (l_diff [1] - 3.0).abs < 1.0e-10)
			assert_true ("diff_2", (l_diff [2] - 3.0).abs < 1.0e-10)
			assert_true ("diff_3", (l_diff [3] - 3.0).abs < 1.0e-10)
		end

	test_vector_scale
			-- Test scalar multiplication
		note
			testing: "covers/{SIMPLE_SQL_VECTOR}.scale"
		local
			l_vec, l_scaled: SIMPLE_SQL_VECTOR
		do
			create l_vec.make_from_array (<<1.0, 2.0, 3.0>>)
			l_scaled := l_vec.scale (2.0)
			assert_true ("scaled_1", (l_scaled [1] - 2.0).abs < 1.0e-10)
			assert_true ("scaled_2", (l_scaled [2] - 4.0).abs < 1.0e-10)
			assert_true ("scaled_3", (l_scaled [3] - 6.0).abs < 1.0e-10)
		end

feature -- Test routines: SIMPLE_SQL_SIMILARITY

	test_cosine_similarity_identical
			-- Test cosine similarity of identical vectors
		note
			testing: "covers/{SIMPLE_SQL_SIMILARITY}.cosine_similarity"
		local
			l_sim: SIMPLE_SQL_SIMILARITY
			l_vec: SIMPLE_SQL_VECTOR
			l_score: REAL_64
		do
			create l_sim.make
			create l_vec.make_from_array (<<1.0, 2.0, 3.0>>)
			l_score := l_sim.cosine_similarity (l_vec, l_vec)
			assert_true ("identical_is_1", (l_score - 1.0).abs < 1.0e-10)
		end

	test_cosine_similarity_orthogonal
			-- Test cosine similarity of orthogonal vectors
		note
			testing: "covers/{SIMPLE_SQL_SIMILARITY}.cosine_similarity"
		local
			l_sim: SIMPLE_SQL_SIMILARITY
			l_vec1, l_vec2: SIMPLE_SQL_VECTOR
			l_score: REAL_64
		do
			create l_sim.make
			create l_vec1.make_from_array (<<1.0, 0.0>>)
			create l_vec2.make_from_array (<<0.0, 1.0>>)
			l_score := l_sim.cosine_similarity (l_vec1, l_vec2)
			assert_true ("orthogonal_is_0", l_score.abs < 1.0e-10)
		end

	test_cosine_similarity_opposite
			-- Test cosine similarity of opposite vectors
		note
			testing: "covers/{SIMPLE_SQL_SIMILARITY}.cosine_similarity"
		local
			l_sim: SIMPLE_SQL_SIMILARITY
			l_vec1, l_vec2: SIMPLE_SQL_VECTOR
			l_score: REAL_64
		do
			create l_sim.make
			create l_vec1.make_from_array (<<1.0, 2.0, 3.0>>)
			create l_vec2.make_from_array (<<-1.0, -2.0, -3.0>>)
			l_score := l_sim.cosine_similarity (l_vec1, l_vec2)
			assert_true ("opposite_is_-1", (l_score - (-1.0)).abs < 1.0e-10)
		end

	test_euclidean_distance
			-- Test Euclidean distance
		note
			testing: "covers/{SIMPLE_SQL_SIMILARITY}.euclidean_distance"
		local
			l_sim: SIMPLE_SQL_SIMILARITY
			l_vec1, l_vec2: SIMPLE_SQL_VECTOR
			l_dist: REAL_64
		do
			create l_sim.make
			create l_vec1.make_from_array (<<0.0, 0.0>>)
			create l_vec2.make_from_array (<<3.0, 4.0>>)
			l_dist := l_sim.euclidean_distance (l_vec1, l_vec2)
			assert_true ("distance_5", (l_dist - 5.0).abs < 1.0e-10)

			-- Same vector
			l_dist := l_sim.euclidean_distance (l_vec1, l_vec1)
			assert_true ("same_is_0", l_dist < 1.0e-10)
		end

	test_manhattan_distance
			-- Test Manhattan distance
		note
			testing: "covers/{SIMPLE_SQL_SIMILARITY}.manhattan_distance"
		local
			l_sim: SIMPLE_SQL_SIMILARITY
			l_vec1, l_vec2: SIMPLE_SQL_VECTOR
			l_dist: REAL_64
		do
			create l_sim.make
			create l_vec1.make_from_array (<<0.0, 0.0>>)
			create l_vec2.make_from_array (<<3.0, 4.0>>)
			-- |3-0| + |4-0| = 7
			l_dist := l_sim.manhattan_distance (l_vec1, l_vec2)
			assert_true ("manhattan_7", (l_dist - 7.0).abs < 1.0e-10)
		end

	test_is_similar
			-- Test similarity threshold check
		note
			testing: "covers/{SIMPLE_SQL_SIMILARITY}.is_similar"
		local
			l_sim: SIMPLE_SQL_SIMILARITY
			l_vec1, l_vec2: SIMPLE_SQL_VECTOR
		do
			create l_sim.make
			create l_vec1.make_from_array (<<1.0, 0.0>>)
			create l_vec2.make_from_array (<<0.8, 0.6>>)
			-- cosine similarity of (1,0) and (0.8,0.6) = 0.8 / (1.0 * 1.0) = 0.8

			assert_true ("similar_at_0.7", l_sim.is_similar (l_vec1, l_vec2, 0.7))
			refute ("not_similar_at_0.9", l_sim.is_similar (l_vec1, l_vec2, 0.9))
		end

feature -- Test routines: SIMPLE_SQL_VECTOR_STORE CRUD

	test_store_insert_and_retrieve
			-- Test inserting and retrieving a vector
		note
			testing: "covers/{SIMPLE_SQL_VECTOR_STORE}.insert"
			testing: "covers/{SIMPLE_SQL_VECTOR_STORE}.find_by_id"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_store: SIMPLE_SQL_VECTOR_STORE
			l_vec, l_retrieved: SIMPLE_SQL_VECTOR
			l_id: INTEGER_64
		do
			create l_db.make_memory
			create l_store.make (l_db, "embeddings")

			create l_vec.make_from_array (<<0.1, 0.2, 0.3, 0.4, 0.5>>)
			l_id := l_store.insert (l_vec, Void)

			assert_true ("got_id", l_id > 0)
			refute ("no_error", l_store.has_error)

			l_retrieved := l_store.find_by_id (l_id)
			assert_attached ("retrieved", l_retrieved)
			if attached l_retrieved as l_r then
				assert_true ("same_values", l_vec.is_equal (l_r))
			end

			l_db.close
		end

	test_store_with_metadata
			-- Test storing vector with metadata
		note
			testing: "covers/{SIMPLE_SQL_VECTOR_STORE}.insert"
			testing: "covers/{SIMPLE_SQL_VECTOR_STORE}.find_metadata_by_id"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_store: SIMPLE_SQL_VECTOR_STORE
			l_vec: SIMPLE_SQL_VECTOR
			l_id: INTEGER_64
			l_metadata: detachable STRING_32
		do
			create l_db.make_memory
			create l_store.make (l_db, "embeddings")

			create l_vec.make_from_array (<<1.0, 2.0, 3.0>>)
			l_id := l_store.insert (l_vec, "{%"source%": %"test.txt%", %"chunk%": 1}")

			l_metadata := l_store.find_metadata_by_id (l_id)
			assert_attached ("has_metadata", l_metadata)
			if attached l_metadata as l_m then
				assert_true ("contains_source", l_m.has_substring ("test.txt"))
			end

			l_db.close
		end

	test_store_update
			-- Test updating a vector
		note
			testing: "covers/{SIMPLE_SQL_VECTOR_STORE}.update"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_store: SIMPLE_SQL_VECTOR_STORE
			l_vec1, l_vec2, l_retrieved: SIMPLE_SQL_VECTOR
			l_id: INTEGER_64
			l_success: BOOLEAN
		do
			create l_db.make_memory
			create l_store.make (l_db, "embeddings")

			create l_vec1.make_from_array (<<1.0, 1.0, 1.0>>)
			l_id := l_store.insert (l_vec1, Void)

			create l_vec2.make_from_array (<<2.0, 2.0, 2.0>>)
			l_success := l_store.update (l_id, l_vec2)
			assert_true ("update_success", l_success)

			l_retrieved := l_store.find_by_id (l_id)
			if attached l_retrieved as l_r then
				assert_true ("updated_values", l_vec2.is_equal (l_r))
			end

			l_db.close
		end

	test_store_delete
			-- Test deleting a vector
		note
			testing: "covers/{SIMPLE_SQL_VECTOR_STORE}.delete"
			testing: "covers/{SIMPLE_SQL_VECTOR_STORE}.exists"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_store: SIMPLE_SQL_VECTOR_STORE
			l_vec: SIMPLE_SQL_VECTOR
			l_id: INTEGER_64
			l_success: BOOLEAN
		do
			create l_db.make_memory
			create l_store.make (l_db, "embeddings")

			create l_vec.make_from_array (<<1.0, 2.0, 3.0>>)
			l_id := l_store.insert (l_vec, Void)
			assert_true ("exists_before", l_store.exists (l_id))

			l_success := l_store.delete (l_id)
			assert_true ("delete_success", l_success)
			refute ("not_exists_after", l_store.exists (l_id))

			l_db.close
		end

	test_store_count
			-- Test counting vectors
		note
			testing: "covers/{SIMPLE_SQL_VECTOR_STORE}.count"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_store: SIMPLE_SQL_VECTOR_STORE
			l_vector: SIMPLE_SQL_VECTOR
			l_ignored_id: INTEGER_64
		do
			create l_db.make_memory
			create l_store.make (l_db, "embeddings")

			assert_true ("empty_count", l_store.count = 0)

			create l_vector.make_from_array (<<1.0, 2.0>>)
			l_ignored_id := l_store.insert (l_vector, Void)
			l_ignored_id := l_store.insert (l_vector, Void)
			l_ignored_id := l_store.insert (l_vector, Void)

			assert_true ("three_count", l_store.count = 3)

			l_db.close
		end

feature -- Test routines: SIMPLE_SQL_VECTOR_STORE Similarity Search

	test_find_nearest
			-- Test K-nearest neighbor search
		note
			testing: "covers/{SIMPLE_SQL_VECTOR_STORE}.find_nearest"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_store: SIMPLE_SQL_VECTOR_STORE
			l_query, l_vector: SIMPLE_SQL_VECTOR
			l_results: ARRAYED_LIST [TUPLE [id: INTEGER_64; vector: SIMPLE_SQL_VECTOR; score: REAL_64]]
			l_ignored_id: INTEGER_64
		do
			create l_db.make_memory
			create l_store.make (l_db, "embeddings")

			-- Insert vectors at different angles
			create l_vector.make_from_array (<<1.0, 0.0>>)
			l_ignored_id := l_store.insert (l_vector, Void)  -- ID 1: East

			create l_vector.make_from_array (<<0.0, 1.0>>)
			l_ignored_id := l_store.insert (l_vector, Void)  -- ID 2: North

			create l_vector.make_from_array (<<0.707, 0.707>>)
			l_ignored_id := l_store.insert (l_vector, Void)  -- ID 3: Northeast (45 degrees)

			create l_vector.make_from_array (<<-1.0, 0.0>>)
			l_ignored_id := l_store.insert (l_vector, Void)  -- ID 4: West (opposite of East)

			-- Query: looking for vectors similar to East
			create l_query.make_from_array (<<1.0, 0.0>>)
			l_results := l_store.find_nearest (l_query, 2)

			assert_equal ("two_results", 2, l_results.count)
			-- First result should be ID 1 (identical to query)
			assert_equal ("first_is_east", {INTEGER_64} 1, l_results [1].id)
			assert_true ("first_score_1", (l_results [1].score - 1.0).abs < 1.0e-6)

			l_db.close
		end

	test_find_within_threshold
			-- Test finding vectors above similarity threshold
		note
			testing: "covers/{SIMPLE_SQL_VECTOR_STORE}.find_within_threshold"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_store: SIMPLE_SQL_VECTOR_STORE
			l_query, l_vector: SIMPLE_SQL_VECTOR
			l_results: ARRAYED_LIST [TUPLE [id: INTEGER_64; vector: SIMPLE_SQL_VECTOR; score: REAL_64]]
			l_ignored_id: INTEGER_64
		do
			create l_db.make_memory
			create l_store.make (l_db, "embeddings")

			-- Insert vectors
			create l_vector.make_from_array (<<1.0, 0.0>>)
			l_ignored_id := l_store.insert (l_vector, Void)  -- Very similar to query

			create l_vector.make_from_array (<<0.9, 0.1>>)
			l_ignored_id := l_store.insert (l_vector, Void)  -- Somewhat similar

			create l_vector.make_from_array (<<0.0, 1.0>>)
			l_ignored_id := l_store.insert (l_vector, Void)  -- Orthogonal (not similar)

			create l_vector.make_from_array (<<-1.0, 0.0>>)
			l_ignored_id := l_store.insert (l_vector, Void)  -- Opposite

			create l_query.make_from_array (<<1.0, 0.0>>)
			l_results := l_store.find_within_threshold (l_query, 0.8)

			-- Should find 2 vectors (the two similar ones)
			assert_equal ("two_similar", 2, l_results.count)

			l_db.close
		end

	test_find_nearest_euclidean
			-- Test K-nearest by Euclidean distance
		note
			testing: "covers/{SIMPLE_SQL_VECTOR_STORE}.find_nearest_euclidean"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_store: SIMPLE_SQL_VECTOR_STORE
			l_query, l_vector: SIMPLE_SQL_VECTOR
			l_results: ARRAYED_LIST [TUPLE [id: INTEGER_64; vector: SIMPLE_SQL_VECTOR; distance: REAL_64]]
			l_ignored_id: INTEGER_64
		do
			create l_db.make_memory
			create l_store.make (l_db, "embeddings")

			-- Insert vectors at different positions
			create l_vector.make_from_array (<<0.0, 0.0>>)
			l_ignored_id := l_store.insert (l_vector, Void)  -- Origin

			create l_vector.make_from_array (<<1.0, 0.0>>)
			l_ignored_id := l_store.insert (l_vector, Void)  -- Distance 1 from origin

			create l_vector.make_from_array (<<3.0, 4.0>>)
			l_ignored_id := l_store.insert (l_vector, Void)  -- Distance 5 from origin

			create l_query.make_from_array (<<0.0, 0.0>>)
			l_results := l_store.find_nearest_euclidean (l_query, 2)

			assert_equal ("two_results", 2, l_results.count)
			-- First should be the origin itself (distance 0)
			assert_true ("first_distance_0", l_results [1].distance < 1.0e-10)
			-- Second should be at distance 1
			assert_true ("second_distance_1", (l_results [2].distance - 1.0).abs < 1.0e-10)

			l_db.close
		end

end
