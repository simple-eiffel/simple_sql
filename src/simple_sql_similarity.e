note
	description: "[
		Similarity and distance calculations for vector embeddings.

		Provides common metrics for comparing vectors:
			- Cosine Similarity: Angle between vectors (-1 to 1)
			- Euclidean Distance: Straight-line distance
			- Manhattan Distance: Taxicab/L1 distance
			- Dot Product: Inner product of vectors

		Usage:
			create sim.make
			score := sim.cosine_similarity (vec1, vec2)
			dist := sim.euclidean_distance (vec1, vec2)

		Cosine Similarity:
			- 1.0 = identical direction
			- 0.0 = orthogonal (no similarity)
			- -1.0 = opposite direction

		For normalized vectors, cosine similarity equals dot product.
	]"
	purpose: "Vector distance and similarity metrics for embedding-based search and ranking"
	collaborators: "SIMPLE_SQL_VECTOR, SIMPLE_SQL_VECTOR_STORE, SIMPLE_SORTER"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_SIMILARITY

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize similarity calculator
		note
			semantic_role: "[
				No-op initialization for stateless metric
				calculator.
			]"
		do
			-- Nothing to initialize
		end

feature -- Similarity Metrics

	cosine_similarity (a_vec1, a_vec2: SIMPLE_SQL_VECTOR): REAL_64
			-- Cosine similarity between vectors
			-- Range: -1.0 (opposite) to 1.0 (identical direction)
			-- Returns 0.0 for zero vectors
		note
			semantic_role: "[
				Computes the cosine of the angle between
				two vectors with zero-vector guard.
			]"
		require
			same_dimension: a_vec1.dimension = a_vec2.dimension
		local
			dot, mag1, mag2, denom: REAL_64
		do
			dot := a_vec1.dot_product (a_vec2)
			mag1 := a_vec1.magnitude
			mag2 := a_vec2.magnitude
			denom := mag1 * mag2

			if denom > Tolerance then
				Result := dot / denom
				-- Clamp to [-1, 1] to handle floating point errors
				Result := Result.max (-1.0).min (1.0)
			else
				Result := 0.0  -- Zero vector case
			end
		ensure
			in_range: Result >= -1.0 and Result <= 1.0
		end

	euclidean_distance (a_vec1, a_vec2: SIMPLE_SQL_VECTOR): REAL_64
			-- Euclidean (L2) distance between vectors
		note
			semantic_role: "[
				Computes the straight-line distance
				between two vectors.
			]"
		require
			same_dimension: a_vec1.dimension = a_vec2.dimension
		local
			sum, diff: REAL_64
			i: INTEGER
		do
			from i := 1 until i > a_vec1.dimension loop
				diff := a_vec1 [i] - a_vec2 [i]
				sum := sum + diff * diff
				i := i + 1
			variant
				a_vec1.dimension - i + 1
			end
			Result := {DOUBLE_MATH}.sqrt (sum)
		ensure
			non_negative: Result >= 0.0
			zero_for_same: a_vec1.is_equal (a_vec2) implies Result < Tolerance
			symmetric: (Result - euclidean_distance (a_vec2, a_vec1)).abs < Tolerance
		end

	manhattan_distance (a_vec1, a_vec2: SIMPLE_SQL_VECTOR): REAL_64
			-- Manhattan (L1/taxicab) distance between vectors
		note
			semantic_role: "[
				Computes the L1 taxicab distance between
				two vectors.
			]"
		require
			same_dimension: a_vec1.dimension = a_vec2.dimension
		local
			i: INTEGER
		do
			from i := 1 until i > a_vec1.dimension loop
				Result := Result + (a_vec1 [i] - a_vec2 [i]).abs
				i := i + 1
			variant
				a_vec1.dimension - i + 1
			end
		ensure
			non_negative: Result >= 0.0
			zero_for_same: a_vec1.is_equal (a_vec2) implies Result < Tolerance
			symmetric: (Result - manhattan_distance (a_vec2, a_vec1)).abs < Tolerance
			at_least_euclidean: Result >= euclidean_distance (a_vec1, a_vec2) - Tolerance
		end

	dot_product (a_vec1, a_vec2: SIMPLE_SQL_VECTOR): REAL_64
			-- Dot product (inner product) of vectors
		note
			semantic_role: "[
				Delegates to the vector's dot_product for
				inner product computation.
			]"
		require
			same_dimension: a_vec1.dimension = a_vec2.dimension
		do
			Result := a_vec1.dot_product (a_vec2)
		ensure
			symmetric: (Result - a_vec2.dot_product (a_vec1)).abs < Tolerance
		end

feature -- Derived Metrics

	angular_distance (a_vec1, a_vec2: SIMPLE_SQL_VECTOR): REAL_64
			-- Angular distance: 1 - cosine_similarity
			-- Range: 0.0 (identical) to 2.0 (opposite)
		note
			semantic_role: "[
				Converts cosine similarity to a distance
				metric via subtraction from 1.
			]"
		require
			same_dimension: a_vec1.dimension = a_vec2.dimension
		do
			Result := 1.0 - cosine_similarity (a_vec1, a_vec2)
		ensure
			in_range: Result >= 0.0 and Result <= 2.0
		end

	squared_euclidean_distance (a_vec1, a_vec2: SIMPLE_SQL_VECTOR): REAL_64
			-- Squared Euclidean distance (faster, avoids sqrt)
		note
			semantic_role: "[
				Computes L2 distance squared for
				performance-sensitive comparisons.
			]"
		require
			same_dimension: a_vec1.dimension = a_vec2.dimension
		local
			l_diff: REAL_64
			i: INTEGER
		do
			from i := 1 until i > a_vec1.dimension loop
				l_diff := a_vec1 [i] - a_vec2 [i]
				Result := Result + l_diff * l_diff
				i := i + 1
			variant
				a_vec1.dimension - i + 1
			end
		ensure
			non_negative: Result >= 0.0
			consistent_with_euclidean: (Result - euclidean_distance (a_vec1, a_vec2) ^ 2).abs < Tolerance
		end

feature -- Batch Operations

	pairwise_cosine_similarity (a_vectors: ARRAY [SIMPLE_SQL_VECTOR]): ARRAY2 [REAL_64]
			-- Compute cosine similarity matrix for all pairs
		note
			semantic_role: "[
				Builds a symmetric similarity matrix from
				all vector pair combinations.
			]"
		require
			not_empty: not a_vectors.is_empty
			same_dimensions: across a_vectors as ic all ic.dimension = a_vectors [a_vectors.lower].dimension end
		local
			n, i, j: INTEGER
		do
			n := a_vectors.count
			create Result.make_filled (0.0, n, n)
			from i := 1 until i > n loop
				from j := i until j > n loop
					Result [i, j] := cosine_similarity (a_vectors [a_vectors.lower + i - 1], a_vectors [a_vectors.lower + j - 1])
					Result [j, i] := Result [i, j]  -- Symmetric
					j := j + 1
				end
				i := i + 1
			end
		ensure
			symmetric: Result.height = Result.width
			correct_size: Result.height = a_vectors.count
		end

	rank_by_similarity (a_query: SIMPLE_SQL_VECTOR; a_candidates: ARRAY [SIMPLE_SQL_VECTOR]): ARRAY [TUPLE [index: INTEGER; score: REAL_64]]
			-- Rank candidates by cosine similarity to query (highest first)
		note
			semantic_role: "[
				Scores and sorts candidates by descending
				similarity to a query vector.
			]"
		require
			candidates_not_empty: not a_candidates.is_empty
			same_dimension: across a_candidates as ic all ic.dimension = a_query.dimension end
		local
			l_scores: ARRAYED_LIST [TUPLE [index: INTEGER; score: REAL_64]]
			i: INTEGER
		do
			create l_scores.make (a_candidates.count)
			from i := a_candidates.lower until i > a_candidates.upper loop
				l_scores.extend ([i, cosine_similarity (a_query, a_candidates [i])])
				i := i + 1
			end

			-- Sort by score descending
			sort_scores_descending (l_scores)

			create Result.make_from_array (l_scores.to_array)
		ensure
			same_count: Result.count = a_candidates.count
		end

	find_most_similar (a_query: SIMPLE_SQL_VECTOR; a_candidates: ARRAY [SIMPLE_SQL_VECTOR]): INTEGER
			-- Index of most similar candidate (in original array bounds)
		note
			semantic_role: "[
				Linear scans candidates to find the index
				with highest cosine similarity.
			]"
		require
			candidates_not_empty: not a_candidates.is_empty
			same_dimension: across a_candidates as ic all ic.dimension = a_query.dimension end
		local
			best_score, score: REAL_64
			i: INTEGER
		do
			Result := a_candidates.lower
			best_score := cosine_similarity (a_query, a_candidates [Result])

			from i := a_candidates.lower + 1 until i > a_candidates.upper loop
				score := cosine_similarity (a_query, a_candidates [i])
				if score > best_score then
					best_score := score
					Result := i
				end
				i := i + 1
			end
		ensure
			valid_index: Result >= a_candidates.lower and Result <= a_candidates.upper
		end

	average_similarity (a_vectors: ARRAY [SIMPLE_SQL_VECTOR]): REAL_64
			-- Average pairwise cosine similarity
		note
			semantic_role: "[
				Computes the mean cosine similarity across
				all unique vector pairs.
			]"
		require
			at_least_two: a_vectors.count >= 2
			same_dimensions: across a_vectors as ic all ic.dimension = a_vectors [a_vectors.lower].dimension end
		local
			l_total: REAL_64
			count, i, j: INTEGER
		do
			from i := a_vectors.lower until i >= a_vectors.upper loop
				from j := i + 1 until j > a_vectors.upper loop
					l_total := l_total + cosine_similarity (a_vectors [i], a_vectors [j])
					count := count + 1
					j := j + 1
				end
				i := i + 1
			end
			if count > 0 then
				Result := l_total / count
			end
		end

feature -- Utility

	is_similar (a_vec1, a_vec2: SIMPLE_SQL_VECTOR; a_threshold: REAL_64): BOOLEAN
			-- Are vectors similar (cosine similarity >= threshold)?
		note
			semantic_role: "[
				Threshold-based similarity predicate using
				cosine similarity.
			]"
		require
			same_dimension: a_vec1.dimension = a_vec2.dimension
			valid_threshold: a_threshold >= -1.0 and a_threshold <= 1.0
		do
			Result := cosine_similarity (a_vec1, a_vec2) >= a_threshold
		ensure
			definition: Result = (cosine_similarity (a_vec1, a_vec2) >= a_threshold)
			symmetric: Result = is_similar (a_vec2, a_vec1, a_threshold)
		end

	is_near (a_vec1, a_vec2: SIMPLE_SQL_VECTOR; a_max_distance: REAL_64): BOOLEAN
			-- Are vectors near (Euclidean distance <= max)?
		note
			semantic_role: "[
				Distance-based proximity predicate using
				Euclidean distance.
			]"
		require
			same_dimension: a_vec1.dimension = a_vec2.dimension
			positive_distance: a_max_distance >= 0.0
		do
			Result := euclidean_distance (a_vec1, a_vec2) <= a_max_distance
		ensure
			definition: Result = (euclidean_distance (a_vec1, a_vec2) <= a_max_distance)
			symmetric: Result = is_near (a_vec2, a_vec1, a_max_distance)
		end

feature {NONE} -- Implementation

	sort_scores_descending (a_list: ARRAYED_LIST [TUPLE [index: INTEGER; score: REAL_64]])
			-- Sort in place by score descending.
		note
			semantic_role: "[
				Delegates to SIMPLE_SORTER for descending
				score ordering.
			]"
		local
			l_sorter: SIMPLE_SORTER [TUPLE [index: INTEGER; score: REAL_64]]
		do
			create l_sorter.make
			l_sorter.sort_by_descending (a_list, agent similarity_score_key)
		ensure
			same_count: a_list.count = old a_list.count
		end

	similarity_score_key (a_item: TUPLE [index: INTEGER; score: REAL_64]): REAL_64
			-- Extract score for sorting.
		note
			semantic_role: "[
				Key extractor agent for score-based
				sorting.
			]"
		do
			Result := a_item.score
		end

	Tolerance: REAL_64 = 1.0e-10
			-- Floating point comparison tolerance

invariant
	tolerance_positive: Tolerance > 0.0

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		simple_sql - High-level SQLite API for Eiffel
		https://github.com/simple-eiffel/simple_sql
	]"

end
